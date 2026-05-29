require('dotenv').config();
const crypto = require('crypto');
const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const multer = require('multer');
const { GoogleAuth } = require('google-auth-library');
const { S3Client, PutObjectCommand, DeleteObjectCommand, ListObjectsV2Command, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

const app = express();
app.use(cors());
app.use(express.json());

// Firebase Admin
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
console.log('Firebase: Admin inicializado');

// Backblaze B2
const s3 = new S3Client({
  endpoint: process.env.B2_ENDPOINT,
  region: process.env.B2_REGION,
  credentials: {
    accessKeyId: process.env.B2_KEY_ID,
    secretAccessKey: process.env.B2_APPLICATION_KEY,
  },
  forcePathStyle: true,
});

const B2_BUCKET = process.env.B2_BUCKET_NAME;
const B2_PUBLIC_BASE_URL = process.env.B2_PUBLIC_BASE_URL?.replace(/\/$/, '') ?? '';
const upload = multer({ storage: multer.memoryStorage() });

console.log('B2 config:', {
  endpoint: process.env.B2_ENDPOINT,
  region: process.env.B2_REGION,
  bucket: process.env.B2_BUCKET_NAME,
  publicBaseUrl: process.env.B2_PUBLIC_BASE_URL,
});

const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY;
const GROQ_API_KEY = process.env.GROQ_API_KEY || '';
const GROQ_BASE_URL = process.env.GROQ_BASE_URL ? process.env.GROQ_BASE_URL.replace(/\/$/, '') : '';
const GROQ_MODEL = process.env.GROQ_MODEL || '';
const FACTURAPI_API_KEY = process.env.FACTURAPI_API_KEY || process.env.FACTURAPI_SECRET_KEY || '';
const FACTURAPI_BASE_URL = (process.env.FACTURAPI_BASE_URL || 'https://www.facturapi.io/v2').replace(/\/$/, '');
const VERTEX_PROJECT_ID = process.env.VERTEX_PROJECT_ID || serviceAccount.project_id || '';
const VERTEX_LOCATION = process.env.VERTEX_LOCATION || 'us-central1';
const VERTEX_MODEL = process.env.VERTEX_MODEL || '';

function validarConfigGroq() {
  const errores = [];

  if (!GROQ_BASE_URL) {
    errores.push('GROQ_BASE_URL');
  }

  if (!GROQ_MODEL) {
    errores.push('GROQ_MODEL');
  }

  if (errores.length > 0) {
    throw new Error(`Faltan variables obligatorias de Groq: ${errores.join(', ')}`);
  }
}

validarConfigGroq();

function validarConfigVertex() {
  const errores = [];

  if (!VERTEX_MODEL) {
    errores.push('VERTEX_MODEL');
  }

  if (errores.length > 0) {
    throw new Error(`Faltan variables obligatorias de Vertex: ${errores.join(', ')}`);
  }
}

validarConfigVertex();

const firebaseAuthUrl = (path) => {
  if (!FIREBASE_API_KEY) return '';
  return `https://identitytoolkit.googleapis.com/v1/${path}?key=${FIREBASE_API_KEY}`;
};

function ensureApiKey(req, res, next) {
  if (!FIREBASE_API_KEY) {
    return res.status(500).json({ error: 'Falta FIREBASE_API_KEY' });
  }
  next();
}

function ensureFacturapiConfig(req, res, next) {
  if (!FACTURAPI_API_KEY) {
    return res.status(500).json({ error: 'Falta FACTURAPI_API_KEY o FACTURAPI_SECRET_KEY' });
  }
  if (!FACTURAPI_BASE_URL) {
    return res.status(500).json({ error: 'Falta FACTURAPI_BASE_URL' });
  }
  next();
}

async function facturapiRequest(path, options = {}) {
  if (!globalThis.fetch) {
    throw new Error('Este entorno de Node no soporta fetch global');
  }

  const url = `${FACTURAPI_BASE_URL}${path}`;
  const headers = {
    Authorization: `Bearer ${FACTURAPI_API_KEY}`,
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };

  const response = await globalThis.fetch(url, {
    method: options.method || 'GET',
    headers,
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
  });

  const contentType = response.headers.get('content-type') || '';
  let payload = null;
  if (contentType.includes('application/json')) {
    payload = await response.json();
  } else {
    const text = await response.text();
    try {
      payload = JSON.parse(text);
    } catch (_) {
      payload = { raw: text };
    }
  }

  return { ok: response.ok, status: response.status, payload };
}

async function facturapiBinaryRequest(path, options = {}) {
  if (!globalThis.fetch) {
    throw new Error('Este entorno de Node no soporta fetch global');
  }

  const url = `${FACTURAPI_BASE_URL}${path}`;
  const headers = {
    Authorization: `Bearer ${FACTURAPI_API_KEY}`,
    ...(options.headers || {}),
  };

  const response = await globalThis.fetch(url, {
    method: options.method || 'GET',
    headers,
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
  });

  const contentType = response.headers.get('content-type') || 'application/octet-stream';
  const arrayBuffer = await response.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);

  return {
    ok: response.ok,
    status: response.status,
    contentType,
    buffer,
  };
}

async function authenticateToken(req, res, next) {
  const auth = req.headers['authorization'];
  if (!auth || !auth.toString().startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token requerido' });
  }
  const token = auth.toString().replace('Bearer ', '');
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.firebaseUid = decoded.uid;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token invalido' });
  }
}

function nombreVisibleUsuario(doc) {
  if (!doc) return null;
  const n = doc.nombre != null ? String(doc.nombre).trim() : '';
  if (n) return n;
  if (doc.email) return String(doc.email);
  return null;
}

function extraerTextoTranscripcionGroq(payload) {
  if (!payload || typeof payload !== 'object') return '';
  const texto = payload.text != null ? String(payload.text).trim() : '';
  if (texto) return texto;

  const segmentos = payload.segments;
  if (!Array.isArray(segmentos)) return '';

  return segmentos
    .map((segmento) => {
      if (!segmento || typeof segmento !== 'object') return '';
      return segmento.text != null ? String(segmento.text).trim() : '';
    })
    .filter(Boolean)
    .join(' ')
    .trim();
}

function extraerMensajeErrorGroq(body, statusCode) {
  try {
    const decoded = JSON.parse(body);
    if (decoded && typeof decoded === 'object') {
      if (typeof decoded.error === 'string' && decoded.error.trim()) {
        return `Groq ${statusCode}: ${decoded.error.trim()}`;
      }

      const error = decoded.error;
      if (error && typeof error === 'object') {
        const mensaje = error.message ?? error.detail ?? error.code;
        if (mensaje != null && String(mensaje).trim()) {
          return `Groq ${statusCode}: ${String(mensaje).trim()}`;
        }
      }

      if (typeof decoded.message === 'string' && decoded.message.trim()) {
        return `Groq ${statusCode}: ${decoded.message.trim()}`;
      }
    }
  } catch (_) {}

  const texto = String(body ?? '').trim();
  return texto ? `Groq ${statusCode}: ${texto}` : `Groq ${statusCode}`;
}

// =============================================================================
// LLAMADAS DE VOZ (Agora token + Firestore + FCM): toda la logica de negocio aqui.
// El cliente Flutter solo: motor RTC, permisos, UI y lectura Firestore.
// =============================================================================
const { FieldValue } = require('firebase-admin/firestore');

const AGORA_APP_ID = process.env.AGORA_APP_ID || '';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '';

const EST_LLAMADA = {
  RINGING: 'ringing',
  ACCEPTED: 'accepted',
  REJECTED: 'rejected',
  ENDED: 'ended',
  MISSED: 'missed',
  BUSY: 'busy',
};

function uidAgoraDesdeFirebaseUid(firebaseUid) {
  const buf = crypto.createHash('sha256').update(String(firebaseUid), 'utf8').digest();
  const u = buf.readUInt32BE(0);
  return u === 0 ? 1 : u;
}

function validarNombreCanal(canal) {
  const c = String(canal ?? '').trim();
  if (!c || c.length > 63) {
    const err = new Error('canal invalido o vacio (max 63 caracteres)');
    err.code = 'BAD_CANAL';
    throw err;
  }
  return c;
}

function normalizarExpiraSegundos(val) {
  if (val === undefined || val === null) return 3600;
  const n = Number(val);
  if (!Number.isFinite(n)) {
    const err = new Error('expiraEnSegundos debe ser un numero finito');
    err.code = 'BAD_EXP';
    throw err;
  }
  if (n <= 0) {
    const err = new Error('expiraEnSegundos debe ser > 0 (minimo aplicado en token: 60 s)');
    err.code = 'BAD_EXP';
    throw err;
  }
  return Math.min(Math.max(Math.floor(n), 60), 86400);
}

function construirTokenRtc(canal, firebaseUid, expiraEnSegundos) {
  if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
    const err = new Error('Faltan AGORA_APP_ID o AGORA_APP_CERTIFICATE en el servidor');
    err.code = 'AGORA_ENV';
    throw err;
  }
  const c = validarNombreCanal(canal);
  const uidAgora = uidAgoraDesdeFirebaseUid(firebaseUid);
  const expSeg =
    expiraEnSegundos === undefined || expiraEnSegundos === null
      ? 3600
      : normalizarExpiraSegundos(expiraEnSegundos);
  const privilegeExpiredTs = Math.floor(Date.now() / 1000) + expSeg;
  const token = RtcTokenBuilder.buildTokenWithUid(
    AGORA_APP_ID,
    AGORA_APP_CERTIFICATE,
    c,
    uidAgora,
    RtcRole.PUBLISHER,
    privilegeExpiredTs,
  );
  return { token, uidAgora, privilegeExpiredTs, canal: c };
}

function extraerTextoVertex(payload) {
  if (!payload || typeof payload !== 'object') return '';

  const textoDirecto = payload.text != null ? String(payload.text).trim() : '';
  if (textoDirecto) return textoDirecto;

  const respuesta = payload.answer != null ? String(payload.answer).trim() : '';
  if (respuesta) return respuesta;

  const candidates = payload.candidates;
  if (!Array.isArray(candidates)) return '';

  const buffer = [];
  candidates.forEach((candidate) => {
    if (!candidate || typeof candidate !== 'object') return;
    const content = candidate.content;
    if (!content || typeof content !== 'object') return;
    const parts = content.parts;
    if (!Array.isArray(parts)) return;

    parts.forEach((part) => {
      if (!part || typeof part !== 'object') return;
      const texto = part.text != null ? String(part.text).trim() : '';
      if (texto) buffer.push(texto);
    });
  });

  return buffer.join(' ').trim();
}

function extraerMensajeErrorVertex(body, statusCode) {
  try {
    const decoded = JSON.parse(body);
    if (decoded && typeof decoded === 'object') {
      if (typeof decoded.error === 'string' && decoded.error.trim()) {
        return `Vertex ${statusCode}: ${decoded.error.trim()}`;
      }

      const error = decoded.error;
      if (error && typeof error === 'object') {
        const mensaje = error.message ?? error.detail ?? error.code;
        if (mensaje != null && String(mensaje).trim()) {
          return `Vertex ${statusCode}: ${String(mensaje).trim()}`;
        }
      }

      if (typeof decoded.message === 'string' && decoded.message.trim()) {
        return `Vertex ${statusCode}: ${decoded.message.trim()}`;
      }
    }
  } catch (_) {}

  return `Vertex ${statusCode}: ${body.trim()}`;
}

/** Quita idLlamadaActiva en presencia de ambos participantes (Admin SDK). */
async function limpiarPresenciaParticipantes(idLlamada) {
  const ref = db.collection('llamadas').doc(idLlamada);
  const snap = await ref.get();
  if (!snap.exists) return;
  const { idEmisor, idReceptor } = snap.data();
  const batch = db.batch();
  const del = { idLlamadaActiva: FieldValue.delete() };
  if (idEmisor) batch.set(db.collection('llamadas_presencia').doc(idEmisor), del, { merge: true });
  if (idReceptor) batch.set(db.collection('llamadas_presencia').doc(idReceptor), del, { merge: true });
  await batch.commit();
}

async function enviarFcmLlamadaEntrante(idReceptor, { idLlamada, canal, idEmisor }) {
  const snap = await db.collection('tokens_llamadas').doc(idReceptor).get();
  const dataTok = snap.exists ? snap.data() : null;
  const fcmToken = dataTok && dataTok.token ? String(dataTok.token) : null;
  if (!fcmToken) {
    return { enviado: false, motivo: 'sin_token_fcm' };
  }
  await admin.messaging().send({
    token: fcmToken,
    data: {
      tipo: 'llamada_entrante',
      idLlamada,
      canal,
      idEmisor,
    },
    android: { priority: 'high' },
    apns: { headers: { 'apns-priority': '10' } },
  });
  return { enviado: true };
}

/** Token RTC (renovacion desde el cliente). */
app.post('/llamadas/agora-token', authenticateToken, (req, res) => {
  try {
    const canal = req.body?.canal != null ? String(req.body.canal).trim() : '';
    validarNombreCanal(canal);
    const expRaw = req.body?.expiraEnSegundos;
    const exp = expRaw === undefined || expRaw === null ? 3600 : normalizarExpiraSegundos(expRaw);
    const out = construirTokenRtc(canal, req.firebaseUid, exp);
    res.json({ ...out, agoraAppId: AGORA_APP_ID });
  } catch (err) {
    console.error('agora-token', err);
    if (err.code === 'BAD_EXP' || err.code === 'BAD_CANAL') {
      return res.status(400).json({ error: err.message });
    }
    const code = err.code === 'AGORA_ENV' ? 503 : 500;
    res.status(code).json({ error: err.message });
  }
});

/** Crea la llamada en Firestore con transaccion (presencia + anti carrera), FCM y token emisor. */
app.post('/llamadas/iniciar', authenticateToken, async (req, res) => {
  try {
    const idEmisor = req.firebaseUid;
    const idReceptor = req.body?.idReceptor != null ? String(req.body.idReceptor).trim() : '';
    if (!idReceptor) {
      return res.status(400).json({ error: 'idReceptor obligatorio' });
    }
    if (idEmisor === idReceptor) {
      return res.status(400).json({ error: 'No puedes llamarte a ti mismo' });
    }

    const nombreEmisor = req.body?.nombreEmisor != null ? String(req.body.nombreEmisor).trim() : '';
    const nombreReceptor = req.body?.nombreReceptor != null ? String(req.body.nombreReceptor).trim() : '';

    let idLlamada;
    let canal;
    try {
      const txResult = await db.runTransaction(async (t) => {
        const refE = db.collection('llamadas_presencia').doc(idEmisor);
        const refR = db.collection('llamadas_presencia').doc(idReceptor);
        const [snapE, snapR] = await Promise.all([t.get(refE), t.get(refR)]);

        const asegurarLibre = async (snap, rol) => {
          if (!snap.exists) return;
          const activaId = snap.data()?.idLlamadaActiva;
          if (!activaId) return;
          const cSnap = await t.get(db.collection('llamadas').doc(String(activaId)));
          if (!cSnap.exists) {
            t.set(snap.ref, { idLlamadaActiva: FieldValue.delete() }, { merge: true });
            return;
          }
          const cd = cSnap.data();
          if (cd.activa === true && (cd.estado === EST_LLAMADA.RINGING || cd.estado === EST_LLAMADA.ACCEPTED)) {
            const err = new Error(rol === 'emisor' ? 'emisor_ocupado' : 'receptor_ocupado');
            err.statusCode = 409;
            if (rol === 'receptor') err.codigo = EST_LLAMADA.BUSY;
            if (rol === 'emisor') err.idLlamadaActiva = String(activaId);
            throw err;
          }
          t.set(snap.ref, { idLlamadaActiva: FieldValue.delete() }, { merge: true });
        };

        await asegurarLibre(snapE, 'emisor');
        await asegurarLibre(snapR, 'receptor');

        const refCall = db.collection('llamadas').doc();
        const newId = refCall.id;
        const newCanal = `voz_${newId}`;
        t.set(refCall, {
          idLlamada: newId,
          idEmisor,
          idReceptor,
          canal: newCanal,
          estado: EST_LLAMADA.RINGING,
          fecha: FieldValue.serverTimestamp(),
          activa: true,
          ...(nombreEmisor ? { nombreEmisor } : {}),
          ...(nombreReceptor ? { nombreReceptor } : {}),
        });
        t.set(refE, { idLlamadaActiva: newId }, { merge: true });
        t.set(refR, { idLlamadaActiva: newId }, { merge: true });
        return { idLlamada: newId, canal: newCanal };
      });
      idLlamada = txResult.idLlamada;
      canal = txResult.canal;
    } catch (e) {
      if (e.statusCode === 409) {
        return res.status(409).json({
          error: e.message,
          ...(e.codigo ? { codigo: e.codigo } : {}),
          ...(e.idLlamadaActiva ? { idLlamadaActiva: e.idLlamadaActiva } : {}),
        });
      }
      throw e;
    }

    const cred = construirTokenRtc(canal, idEmisor, undefined);

    let fcmRes = { enviado: false, motivo: 'no_intentado' };
    try {
      fcmRes = await enviarFcmLlamadaEntrante(idReceptor, { idLlamada, canal, idEmisor });
    } catch (e) {
      console.error('FCM iniciar', e);
      fcmRes = { enviado: false, motivo: String(e.message || e) };
    }

    res.status(201).json({
      idLlamada,
      canal,
      agoraAppId: AGORA_APP_ID,
      token: cred.token,
      uidAgora: cred.uidAgora,
      privilegeExpiredTs: cred.privilegeExpiredTs,
      fcm: fcmRes,
    });
  } catch (err) {
    console.error('llamadas/iniciar', err);
    const code = err.code === 'AGORA_ENV' ? 503 : 500;
    res.status(code).json({ error: err.message });
  }
});

/** Receptor acepta: valida estado, actualiza Firestore y devuelve token RTC. */
app.post('/llamadas/aceptar', authenticateToken, async (req, res) => {
  try {
    const uid = req.firebaseUid;
    const idLlamada = req.body?.idLlamada != null ? String(req.body.idLlamada).trim() : '';
    if (!idLlamada) {
      return res.status(400).json({ error: 'idLlamada obligatorio' });
    }
    const ref = db.collection('llamadas').doc(idLlamada);
    const snap = await ref.get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'llamada_no_encontrada' });
    }
    const data = snap.data();
    if (data.idReceptor !== uid) {
      return res.status(403).json({ error: 'solo_el_receptor_puede_aceptar' });
    }
    if (data.estado !== EST_LLAMADA.RINGING) {
      return res.status(409).json({ error: 'estado_invalido', estado: data.estado });
    }

    let cred;
    try {
      const canalOk = validarNombreCanal(data.canal);
      cred = construirTokenRtc(canalOk, uid, undefined);
    } catch (e) {
      return res.status(500).json({ error: 'llamada_sin_canal_valido', detalle: e.message });
    }

    await ref.update({
      estado: EST_LLAMADA.ACCEPTED,
    });

    res.json({
      idLlamada,
      canal: cred.canal,
      agoraAppId: AGORA_APP_ID,
      token: cred.token,
      uidAgora: cred.uidAgora,
      privilegeExpiredTs: cred.privilegeExpiredTs,
    });
  } catch (err) {
    console.error('llamadas/aceptar', err);
    const code = err.code === 'AGORA_ENV' ? 503 : 500;
    res.status(code).json({ error: err.message });
  }
});

/** Receptor rechaza timbre. */
app.post('/llamadas/rechazar', authenticateToken, async (req, res) => {
  try {
    const uid = req.firebaseUid;
    const idLlamada = req.body?.idLlamada != null ? String(req.body.idLlamada).trim() : '';
    if (!idLlamada) {
      return res.status(400).json({ error: 'idLlamada obligatorio' });
    }
    const ref = db.collection('llamadas').doc(idLlamada);
    const snap = await ref.get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'llamada_no_encontrada' });
    }
    const data = snap.data();
    if (data.idReceptor !== uid) {
      return res.status(403).json({ error: 'solo_el_receptor_puede_rechazar' });
    }
    if (data.estado !== EST_LLAMADA.RINGING) {
      return res.status(409).json({ error: 'estado_invalido', estado: data.estado });
    }
    await ref.update({
      estado: EST_LLAMADA.REJECTED,
      activa: false,
    });
    await limpiarPresenciaParticipantes(idLlamada);
    res.json({ ok: true, idLlamada });
  } catch (err) {
    console.error('llamadas/rechazar', err);
    res.status(500).json({ error: err.message });
  }
});

/** Emisor cuelga antes de que contesten (sigue en ringing). */
app.post('/llamadas/cancelar-emisor', authenticateToken, async (req, res) => {
  try {
    const uid = req.firebaseUid;
    const idLlamada = req.body?.idLlamada != null ? String(req.body.idLlamada).trim() : '';
    if (!idLlamada) {
      return res.status(400).json({ error: 'idLlamada obligatorio' });
    }
    const ref = db.collection('llamadas').doc(idLlamada);
    const snap = await ref.get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'llamada_no_encontrada' });
    }
    const data = snap.data();
    if (data.idEmisor !== uid) {
      return res.status(403).json({ error: 'solo_el_emisor_puede_cancelar' });
    }
    if (data.estado !== EST_LLAMADA.RINGING) {
      return res.status(409).json({ error: 'estado_invalido', estado: data.estado });
    }
    await ref.update({
      estado: EST_LLAMADA.ENDED,
      activa: false,
    });
    await limpiarPresenciaParticipantes(idLlamada);
    res.json({ ok: true, idLlamada });
  } catch (err) {
    console.error('llamadas/cancelar-emisor', err);
    res.status(500).json({ error: err.message });
  }
});

/** Cualquier participante cuelga llamada en curso o finaliza sesion. */
app.post('/llamadas/finalizar', authenticateToken, async (req, res) => {
  try {
    const uid = req.firebaseUid;
    const idLlamada = req.body?.idLlamada != null ? String(req.body.idLlamada).trim() : '';
    if (!idLlamada) {
      return res.status(400).json({ error: 'idLlamada obligatorio' });
    }
    const ref = db.collection('llamadas').doc(idLlamada);
    const snap = await ref.get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'llamada_no_encontrada' });
    }
    const data = snap.data();
    if (data.idEmisor !== uid && data.idReceptor !== uid) {
      return res.status(403).json({ error: 'no_participante' });
    }
    await ref.update({
      estado: EST_LLAMADA.ENDED,
      activa: false,
    });
    await limpiarPresenciaParticipantes(idLlamada);
    res.json({ ok: true, idLlamada });
  } catch (err) {
    console.error('llamadas/finalizar', err);
    res.status(500).json({ error: err.message });
  }
});

/** Timeout de timbre: solo el emisor y solo si sigue en ringing (sustituye logica en cliente). */
app.post('/llamadas/marcar-perdida', authenticateToken, async (req, res) => {
  try {
    const uid = req.firebaseUid;
    const idLlamada = req.body?.idLlamada != null ? String(req.body.idLlamada).trim() : '';
    if (!idLlamada) {
      return res.status(400).json({ error: 'idLlamada obligatorio' });
    }
    const ref = db.collection('llamadas').doc(idLlamada);
    const snap = await ref.get();
    if (!snap.exists) {
      return res.status(404).json({ error: 'llamada_no_encontrada' });
    }
    const data = snap.data();
    if (data.idEmisor !== uid) {
      return res.status(403).json({ error: 'solo_el_emisor_puede_marcar_perdida' });
    }
    if (data.estado !== EST_LLAMADA.RINGING) {
      return res.json({ ok: true, sin_cambios: true, estado: data.estado });
    }
    await ref.update({
      estado: EST_LLAMADA.MISSED,
      activa: false,
    });
    await limpiarPresenciaParticipantes(idLlamada);
    res.json({ ok: true, idLlamada });
  } catch (err) {
    console.error('llamadas/marcar-perdida', err);
    res.status(500).json({ error: err.message });
  }
});

/** Compatibilidad: reenvia FCM (la ruta preferida es POST /llamadas/iniciar). */
app.post('/llamadas/notificar-entrante', authenticateToken, async (req, res) => {
  try {
    const idReceptor = req.body?.idReceptor != null ? String(req.body.idReceptor).trim() : '';
    const idLlamada = req.body?.idLlamada != null ? String(req.body.idLlamada).trim() : '';
    const canal = req.body?.canal != null ? String(req.body.canal).trim() : '';
    if (!idReceptor || !idLlamada || !canal) {
      return res.status(400).json({ error: 'idReceptor, idLlamada y canal son obligatorios' });
    }
    validarNombreCanal(canal);
    const fcmRes = await enviarFcmLlamadaEntrante(idReceptor, {
      idLlamada,
      canal,
      idEmisor: req.firebaseUid,
    });
    res.json(fcmRes);
  } catch (err) {
    console.error('notificar-entrante', err);
    if (err.code === 'BAD_CANAL') {
      return res.status(400).json({ error: err.message });
    }
    res.status(500).json({ error: err.message });
  }
});

// Custom token para Firebase Client SDK (Firestore snapshots en Flutter)
app.post('/auth/custom-token', authenticateToken, async (req, res) => {
  try {
    const customToken = await admin.auth().createCustomToken(req.firebaseUid);
    res.json({ customToken });
  } catch (err) {
    console.error('custom-token', err);
    res.status(500).json({ error: err.message });
  }
});

// --- Mensajes (cliente / trabajador) ---

function makeConversationId(uidA, uidB) {
  return [uidA, uidB].sort().join('_');
}

function normalizeRol(rol) {
  return String(rol ?? 'cliente').toLowerCase();
}

async function fetchUsuarioDoc(uid) {
  const doc = await db.collection('usuarios').doc(uid).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

function assertParticipant(convData, uid) {
  const parts = convData?.participantes;
  if (!Array.isArray(parts) || !parts.includes(uid)) {
    return false;
  }
  return true;
}

function tsToIso(v) {
  if (v && typeof v.toDate === 'function') return v.toDate().toISOString();
  return null;
}

// Crear o asegurar conversacion cliente-trabajador (mismo id para ambos lados)
app.post('/mensajes/conversaciones', authenticateToken, async (req, res) => {
  const otroUid = req.body?.otroUid;
  if (!otroUid || typeof otroUid !== 'string') {
    return res.status(400).json({ error: 'Body requiere otroUid (string)' });
  }
  const meUid = req.firebaseUid;
  if (otroUid === meUid) {
    return res.status(400).json({ error: 'No puedes conversar contigo mismo' });
  }

  try {
    const [yo, otro] = await Promise.all([fetchUsuarioDoc(meUid), fetchUsuarioDoc(otroUid)]);
    if (!yo) return res.status(404).json({ error: 'Tu usuario no existe en usuarios' });
    if (!otro) return res.status(404).json({ error: 'Usuario destino no encontrado' });

    const rolYo = normalizeRol(yo.rol);
    const rolOtro = normalizeRol(otro.rol);
    const okPair =
      (rolYo === 'cliente' && rolOtro === 'trabajador') ||
      (rolYo === 'trabajador' && rolOtro === 'cliente');
    if (!okPair) {
      return res.status(403).json({ error: 'Solo se permiten conversaciones entre cliente y trabajador' });
    }

    const conversationId = makeConversationId(meUid, otroUid);
    const clienteUid = rolYo === 'cliente' ? meUid : otroUid;
    const trabajadorUid = rolYo === 'trabajador' ? meUid : otroUid;

    const ref = db.collection('conversaciones').doc(conversationId);
    const existente = await ref.get();
    const clienteDoc = rolYo === 'cliente' ? yo : otro;
    const trabajadorDoc = rolYo === 'trabajador' ? yo : otro;
    const payload = {
      participantes: [meUid, otroUid],
      clienteUid,
      trabajadorUid,
      clienteNombre: nombreVisibleUsuario(clienteDoc),
      trabajadorNombre: nombreVisibleUsuario(trabajadorDoc),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (!existente.exists) {
      payload.creado = admin.firestore.FieldValue.serverTimestamp();
    }
    await ref.set(payload, { merge: true });

    res.status(200).json({ conversationId });
  } catch (err) {
    console.error('mensajes/conversaciones POST', err);
    res.status(500).json({ error: err.message });
  }
});

// Listar conversaciones del usuario actual
app.get('/mensajes/conversaciones', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  try {
    const snap = await db
      .collection('conversaciones')
      .where('participantes', 'array-contains', meUid)
      .orderBy('updatedAt', 'desc')
      .limit(50)
      .get();

    const items = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        participantes: data.participantes,
        clienteUid: data.clienteUid,
        trabajadorUid: data.trabajadorUid,
        ultimoMensaje: data.ultimoMensaje ?? null,
        ultimoSenderUid: data.ultimoSenderUid ?? null,
        updatedAt: tsToIso(data.updatedAt),
        creado: tsToIso(data.creado),
      };
    });

    const uidSet = new Set();
    for (const it of items) {
      if (it.clienteUid) uidSet.add(it.clienteUid);
      if (it.trabajadorUid) uidSet.add(it.trabajadorUid);
    }
    const nombrePorUid = {};
    await Promise.all(
      [...uidSet].map(async (uid) => {
        const udoc = await db.collection('usuarios').doc(uid).get();
        if (udoc.exists) {
          const d = udoc.data();
          nombrePorUid[uid] = (d.nombre && String(d.nombre).trim()) || d.email || uid;
        }
      }),
    );

    const enriched = items.map((it) => ({
      ...it,
      clienteNombre: it.clienteUid ? (nombrePorUid[it.clienteUid] ?? null) : null,
      trabajadorNombre: it.trabajadorUid ? (nombrePorUid[it.trabajadorUid] ?? null) : null,
    }));
    res.json(enriched);
  } catch (err) {
    console.error('mensajes/conversaciones GET', err);
    res.status(500).json({ error: err.message });
  }
});

// Listar mensajes de una conversacion
app.get('/mensajes/conversaciones/:conversationId/mensajes', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  const { conversationId } = req.params;
  const limitNum = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const antesDe = req.query.antesDe;

  try {
    const convRef = db.collection('conversaciones').doc(conversationId);
    const convSnap = await convRef.get();
    if (!convSnap.exists) {
      return res.status(404).json({ error: 'Conversacion no encontrada' });
    }
    const convData = convSnap.data();
    if (!assertParticipant(convData, meUid)) {
      return res.status(403).json({ error: 'No participas en esta conversacion' });
    }

    let q = convRef.collection('mensajes').orderBy('createdAt', 'desc').limit(limitNum);
    if (antesDe) {
      const cursor = await convRef.collection('mensajes').doc(antesDe).get();
      if (cursor.exists) {
        q = q.startAfter(cursor);
      }
    }
    const snap = await q.get();
    const mensajes = snap.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        conversationId,
        senderUid: d.senderUid,
        texto: d.texto,
        createdAt: tsToIso(d.createdAt),
      };
    });
    res.json(mensajes);
  } catch (err) {
    console.error('mensajes GET lista', err);
    res.status(500).json({ error: err.message });
  }
});

// Enviar mensaje
app.post('/mensajes/conversaciones/:conversationId', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  const { conversationId } = req.params;
  const texto = (req.body?.texto ?? '').toString().trim();
  if (!texto) {
    return res.status(400).json({ error: 'texto es obligatorio' });
  }

  try {
    const convRef = db.collection('conversaciones').doc(conversationId);
    const convSnap = await convRef.get();
    if (!convSnap.exists) {
      return res.status(404).json({ error: 'Conversacion no encontrada' });
    }
    const convData = convSnap.data();
    if (!assertParticipant(convData, meUid)) {
      return res.status(403).json({ error: 'No participas en esta conversacion' });
    }

    const msgRef = await convRef.collection('mensajes').add({
      senderUid: meUid,
      texto,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await convRef.update({
      ultimoMensaje: texto,
      ultimoSenderUid: meUid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: msgRef.id, conversationId });
  } catch (err) {
    console.error('mensajes POST enviar', err);
    res.status(500).json({ error: err.message });
  }
});

// --- Reservaciones y relacion cliente-trabajador ---

const ESTADO_TRABAJO = {
  PENDIENTE: 'pendiente',
  CONFIRMADO: 'confirmado',
  EN_CURSO: 'en_curso',
  COMPLETADO: 'completado',
  CANCELADO: 'cancelado',
};

const ORDEN_ESTADOS_TRABAJO = [
  ESTADO_TRABAJO.PENDIENTE,
  ESTADO_TRABAJO.CONFIRMADO,
  ESTADO_TRABAJO.EN_CURSO,
  ESTADO_TRABAJO.COMPLETADO,
];

function normalizarEstadoTrabajo(valor) {
  const v = String(valor ?? '').trim().toLowerCase();
  return ORDEN_ESTADOS_TRABAJO.includes(v) || v === ESTADO_TRABAJO.CANCELADO ? v : null;
}

function parseMesQuery(valor) {
  const raw = String(valor ?? '').trim();
  if (!raw) return null;
  const m = /^(\d{4})-(\d{2})$/.exec(raw);
  if (!m) return null;
  const year = Number(m[1]);
  const month = Number(m[2]);
  if (!Number.isFinite(year) || !Number.isFinite(month) || month < 1 || month > 12) return null;
  return { year, month };
}

function serializarReservacion(doc) {
  const data = doc.data() || {};
  return {
    id: doc.id,
    ...data,
    creado: tsToIso(data.creado),
    actualizado: tsToIso(data.actualizado),
    pagadoEn: tsToIso(data.pagadoEn),
  };
}

function esErrorIndiceFirestore(err) {
  const code = Number(err?.code);
  const message = String(err?.message || '');
  const lower = message.toLowerCase();
  return (
    code === 9 ||
    message.includes('FAILED_PRECONDITION') ||
    lower.includes('requires an index')
  );
}

function ordenarReservacionesPorCreadoDesc(items) {
  return [...items].sort((a, b) => {
    const tA = a?.creado ? Date.parse(a.creado) : NaN;
    const tB = b?.creado ? Date.parse(b.creado) : NaN;
    const nA = Number.isFinite(tA) ? tA : 0;
    const nB = Number.isFinite(tB) ? tB : 0;
    return nB - nA;
  });
}

// La relacion calificable existe solo si hay al menos una reservacion completada y pagada.
async function existeRelacionCalificable(clienteUid, trabajadorUid) {
  const snap = await db
    .collection('reservaciones')
    .where('clienteUid', '==', clienteUid)
    .where('trabajadorUid', '==', trabajadorUid)
    .where('estadoTrabajo', '==', ESTADO_TRABAJO.COMPLETADO)
    .where('pagado', '==', true)
    .limit(1)
    .get();
  return !snap.empty;
}

// El cliente crea una reservacion hacia un trabajador.
app.post('/reservaciones', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  const body = req.body || {};
  const trabajadorUid = typeof body.trabajadorUid === 'string' ? body.trabajadorUid.trim() : '';
  if (!trabajadorUid) {
    return res.status(400).json({ error: 'trabajadorUid es obligatorio' });
  }
  if (trabajadorUid === meUid) {
    return res.status(400).json({ error: 'No puedes reservarte a ti mismo' });
  }

  try {
    const [yo, trabajador] = await Promise.all([
      fetchUsuarioDoc(meUid),
      fetchUsuarioDoc(trabajadorUid),
    ]);
    if (!yo) return res.status(404).json({ error: 'Tu usuario no existe en usuarios' });
    if (!trabajador) return res.status(404).json({ error: 'Trabajador no encontrado' });
    if (normalizeRol(yo.rol) !== 'cliente') {
      return res.status(403).json({ error: 'Solo un cliente puede crear reservaciones' });
    }
    if (normalizeRol(trabajador.rol) !== 'trabajador') {
      return res.status(403).json({ error: 'El destino no es un trabajador' });
    }

    const fecha = typeof body.fecha === 'string' ? body.fecha.trim() : '';
    const metodoPago = body.pago != null ? String(body.pago).trim() : 'Efectivo';
    const payload = {
      clienteUid: meUid,
      trabajadorUid,
      clienteNombre: nombreVisibleUsuario(yo),
      trabajadorNombre: nombreVisibleUsuario(trabajador),
      fecha: fecha || null,
      direccion: body.direccion != null ? String(body.direccion).trim() : '',
      referencias: body.referencias != null ? String(body.referencias).trim() : '',
      telefono: body.telefono != null ? String(body.telefono).trim() : '',
      detalle: body.detalle != null ? String(body.detalle).trim() : '',
      urgencia: body.urgencia != null ? String(body.urgencia).trim() : 'Normal',
      metodoPago: metodoPago || 'Efectivo',
      pago: metodoPago || 'Efectivo', // compatibilidad con clientes previos
      estadoTrabajo: ESTADO_TRABAJO.PENDIENTE,
      pagado: false,
      pagadoEn: null,
      creado: admin.firestore.FieldValue.serverTimestamp(),
      actualizado: admin.firestore.FieldValue.serverTimestamp(),
    };
    const ref = await db.collection('reservaciones').add(payload);
    res.status(201).json({ id: ref.id });
  } catch (err) {
    console.error('reservaciones POST', err);
    res.status(500).json({ error: err.message });
  }
});

// Lista reservaciones del usuario autenticado para poblar calendario (cliente o trabajador).
app.get('/reservaciones/mias', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  const rolQuery = String(req.query.rol ?? '').trim().toLowerCase();
  const mes = parseMesQuery(req.query.mes);
  if (req.query.mes != null && !mes) {
    return res.status(400).json({ error: 'mes invalido, usa formato YYYY-MM' });
  }

  try {
    const meDoc = await fetchUsuarioDoc(meUid);
    if (!meDoc) return res.status(404).json({ error: 'Usuario no encontrado' });
    const rolUsuario = normalizeRol(meDoc.rol);
    const rol = rolQuery || rolUsuario;
    if (rol !== 'cliente' && rol !== 'trabajador') {
      return res.status(400).json({ error: 'rol invalido, usa cliente o trabajador' });
    }
    if (rol !== rolUsuario) {
      return res.status(403).json({ error: 'No puedes consultar reservaciones de otro rol' });
    }

    const campo = rol === 'cliente' ? 'clienteUid' : 'trabajadorUid';
    let docs = [];
    try {
      const snap = await db
        .collection('reservaciones')
        .where(campo, '==', meUid)
        .orderBy('creado', 'desc')
        .limit(200)
        .get();
      docs = snap.docs;
    } catch (queryErr) {
      if (!esErrorIndiceFirestore(queryErr)) throw queryErr;
      console.warn(
        '[reservaciones/mias] Fallback sin indice compuesto:',
        queryErr.message || queryErr
      );
      const snap = await db
        .collection('reservaciones')
        .where(campo, '==', meUid)
        .limit(200)
        .get();
      docs = snap.docs;
    }

    let items = docs.map(serializarReservacion);
    items = ordenarReservacionesPorCreadoDesc(items);
    items = items.filter((item) => {
      if (!mes) return true;
      const fecha = item.fecha && typeof item.fecha === 'string' ? new Date(item.fecha) : null;
      if (!fecha || Number.isNaN(fecha.getTime())) return false;
      return fecha.getFullYear() === mes.year && fecha.getMonth() + 1 === mes.month;
    });

    res.json(items);
  } catch (err) {
    console.error('reservaciones/mias GET', err);
    res.status(500).json({ error: err.message });
  }
});

// El trabajador dueño actualiza el estado del trabajo.
app.patch('/reservaciones/:id/estado-trabajo', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  const id = String(req.params.id || '').trim();
  const estadoNuevo = normalizarEstadoTrabajo(req.body?.estadoTrabajo);
  if (!id) return res.status(400).json({ error: 'id de reservacion obligatorio' });
  if (!estadoNuevo) {
    return res.status(400).json({ error: 'estadoTrabajo invalido' });
  }

  try {
    const meDoc = await fetchUsuarioDoc(meUid);
    if (!meDoc) return res.status(404).json({ error: 'Usuario no encontrado' });
    if (normalizeRol(meDoc.rol) !== 'trabajador') {
      return res.status(403).json({ error: 'Solo un trabajador puede actualizar estado de trabajo' });
    }

    const ref = db.collection('reservaciones').doc(id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: 'Reservacion no encontrada' });
    const data = snap.data();
    if (data.trabajadorUid !== meUid) {
      return res.status(403).json({ error: 'Solo el trabajador dueño puede actualizar esta reservacion' });
    }
    const estadoActual = normalizarEstadoTrabajo(data.estadoTrabajo) || ESTADO_TRABAJO.PENDIENTE;
    const idxActual = ORDEN_ESTADOS_TRABAJO.indexOf(estadoActual);
    const idxNuevo = ORDEN_ESTADOS_TRABAJO.indexOf(estadoNuevo);
    const transicionCancelada = estadoNuevo === ESTADO_TRABAJO.CANCELADO;

    if (!transicionCancelada) {
      if (idxNuevo < 0 || idxActual < 0) {
        return res.status(409).json({ error: 'Transicion de estado invalida' });
      }
      if (idxNuevo < idxActual) {
        return res.status(409).json({ error: 'No se permite retroceder estado de trabajo' });
      }
      if (idxNuevo - idxActual > 1) {
        return res.status(409).json({ error: 'Debes avanzar estado de trabajo paso a paso' });
      }
    }

    await ref.update({
      estadoTrabajo: estadoNuevo,
      actualizado: admin.firestore.FieldValue.serverTimestamp(),
    });
    const actualizado = await ref.get();
    res.json(serializarReservacion(actualizado));
  } catch (err) {
    console.error('reservaciones estado-trabajo PATCH', err);
    res.status(500).json({ error: err.message });
  }
});

// El cliente dueño confirma pago una vez completado el trabajo.
app.patch('/reservaciones/:id/confirmar-pago', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  const id = String(req.params.id || '').trim();
  if (!id) return res.status(400).json({ error: 'id de reservacion obligatorio' });

  try {
    const meDoc = await fetchUsuarioDoc(meUid);
    if (!meDoc) return res.status(404).json({ error: 'Usuario no encontrado' });
    if (normalizeRol(meDoc.rol) !== 'cliente') {
      return res.status(403).json({ error: 'Solo un cliente puede confirmar pago' });
    }

    const ref = db.collection('reservaciones').doc(id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: 'Reservacion no encontrada' });
    const data = snap.data();
    if (data.clienteUid !== meUid) {
      return res.status(403).json({ error: 'Solo el cliente dueño puede confirmar pago' });
    }
    if (normalizarEstadoTrabajo(data.estadoTrabajo) !== ESTADO_TRABAJO.COMPLETADO) {
      return res.status(409).json({ error: 'Solo puedes confirmar pago cuando el trabajo este completado' });
    }
    if (data.pagado === true) {
      const ya = serializarReservacion(snap);
      return res.json({ ...ya, pagoYaConfirmado: true });
    }

    await ref.update({
      pagado: true,
      pagadoEn: admin.firestore.FieldValue.serverTimestamp(),
      actualizado: admin.firestore.FieldValue.serverTimestamp(),
    });
    const actualizado = await ref.get();
    res.json(serializarReservacion(actualizado));
  } catch (err) {
    console.error('reservaciones confirmar-pago PATCH', err);
    res.status(500).json({ error: err.message });
  }
});

// --- Calificaciones de trabajadores ---

function calificacionDocId(clienteUid, trabajadorUid) {
  return `${clienteUid}_${trabajadorUid}`;
}

// Devuelve el valor saneado (multiplo de 0.5 entre 0.5 y 5) o null si es invalido.
function normalizarEstrellas(valor) {
  const n = Number(valor);
  if (!Number.isFinite(n)) return null;
  if (n < 0.5 || n > 5) return null;
  if (Math.round(n * 2) !== n * 2) return null;
  return Math.round(n * 2) / 2;
}

// Contexto para la UI del cliente: si puede calificar, su calificacion actual y el promedio del trabajador.
app.get('/calificaciones/:trabajadorUid/contexto', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  const trabajadorUid = String(req.params.trabajadorUid || '').trim();
  if (!trabajadorUid) {
    return res.status(400).json({ error: 'trabajadorUid es obligatorio' });
  }

  try {
    const [meDoc, trabajador] = await Promise.all([fetchUsuarioDoc(meUid), fetchUsuarioDoc(trabajadorUid)]);
    if (!meDoc) return res.status(404).json({ error: 'Usuario no encontrado' });
    if (!trabajador) return res.status(404).json({ error: 'Trabajador no encontrado' });

    const esCliente = normalizeRol(meDoc.rol) === 'cliente';
    const [puedeCalificar, miDoc] = await Promise.all([
      esCliente ? existeRelacionCalificable(meUid, trabajadorUid) : Promise.resolve(false),
      db.collection('calificaciones').doc(calificacionDocId(meUid, trabajadorUid)).get(),
    ]);

    const promedio = Number(trabajador.calificacion) || 0;
    const total = Number(trabajador.numCalificaciones) || 0;
    const miCalificacion = miDoc.exists ? (Number(miDoc.data().estrellas) || null) : null;

    res.json({
      puedeCalificar,
      miCalificacion,
      promedio,
      total,
      mensajeBloqueo: puedeCalificar
        ? null
        : 'Debes tener una reservacion completada y pagada con este trabajador',
    });
  } catch (err) {
    console.error('calificaciones contexto GET', err);
    res.status(500).json({ error: err.message });
  }
});

// El cliente califica (o edita su calificacion) a un trabajador con el que tiene reservacion completada y pagada.
app.post('/calificaciones', authenticateToken, async (req, res) => {
  const meUid = req.firebaseUid;
  const body = req.body || {};
  const trabajadorUid = typeof body.trabajadorUid === 'string' ? body.trabajadorUid.trim() : '';
  const estrellas = normalizarEstrellas(body.estrellas);
  if (!trabajadorUid) {
    return res.status(400).json({ error: 'trabajadorUid es obligatorio' });
  }
  if (estrellas === null) {
    return res.status(400).json({ error: 'estrellas debe ser multiplo de 0.5 entre 0.5 y 5' });
  }
  if (trabajadorUid === meUid) {
    return res.status(400).json({ error: 'No puedes calificarte a ti mismo' });
  }

  try {
    const [yo, trabajador] = await Promise.all([
      fetchUsuarioDoc(meUid),
      fetchUsuarioDoc(trabajadorUid),
    ]);
    if (!yo) return res.status(404).json({ error: 'Tu usuario no existe en usuarios' });
    if (!trabajador) return res.status(404).json({ error: 'Trabajador no encontrado' });
    if (normalizeRol(yo.rol) !== 'cliente') {
      return res.status(403).json({ error: 'Solo un cliente puede calificar' });
    }
    if (normalizeRol(trabajador.rol) !== 'trabajador') {
      return res.status(403).json({ error: 'El destino no es un trabajador' });
    }

    const tieneRelacion = await existeRelacionCalificable(meUid, trabajadorUid);
    if (!tieneRelacion) {
      return res.status(403).json({
        error: 'Debes tener una reservacion completada y pagada con este trabajador para calificarlo',
      });
    }

    const califRef = db.collection('calificaciones').doc(calificacionDocId(meUid, trabajadorUid));
    const trabajadorRef = db.collection('usuarios').doc(trabajadorUid);

    const resultado = await db.runTransaction(async (t) => {
      const [califSnap, trabajadorSnap] = await Promise.all([t.get(califRef), t.get(trabajadorRef)]);
      const tData = trabajadorSnap.exists ? trabajadorSnap.data() : {};

      let suma = Number(tData.sumaCalificaciones);
      let num = Number(tData.numCalificaciones);
      if (!Number.isFinite(suma)) suma = 0;
      if (!Number.isFinite(num)) num = 0;

      const anterior = califSnap.exists ? Number(califSnap.data().estrellas) : null;
      if (anterior != null && Number.isFinite(anterior)) {
        suma = suma - anterior + estrellas;
      } else {
        suma = suma + estrellas;
        num = num + 1;
      }

      const promedio = num > 0 ? Math.round((suma / num) * 10) / 10 : 0;

      t.set(
        califRef,
        {
          clienteUid: meUid,
          trabajadorUid,
          estrellas,
          actualizado: admin.firestore.FieldValue.serverTimestamp(),
          ...(califSnap.exists ? {} : { creado: admin.firestore.FieldValue.serverTimestamp() }),
        },
        { merge: true },
      );

      t.set(
        trabajadorRef,
        { sumaCalificaciones: suma, numCalificaciones: num, calificacion: promedio },
        { merge: true },
      );

      return { promedio, total: num, miCalificacion: estrellas };
    });

    res.status(200).json(resultado);
  } catch (err) {
    console.error('calificaciones POST', err);
    res.status(500).json({ error: err.message });
  }
});

// Registro de usuario por correo y password
app.post('/auth/register', async (req, res) => {
  const { email, password, rol = 'cliente', categoria, subcategoria, nombre } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email y password son obligatorios' });
  }

  try {
    const userRecord = await admin.auth().createUser({ email, password });
    await db.collection('usuarios').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email,
      nombre: nombre ?? null,
      rol,
      categoria: categoria ?? null,
      subcategoria: subcategoria ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.status(201).json({ uid: userRecord.uid });
  } catch (err) {
    console.error('Auth register error', err);
    if (err.code === 'auth/email-already-exists') {
      return res.status(409).json({ error: 'Email ya registrado' });
    }
    res.status(500).json({ error: err.message });
  }
});

// Login con Firebase REST API
app.post('/auth/login', ensureApiKey, async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email y password son obligatorios' });
  }

  try {
    const response = await fetch(firebaseAuthUrl('accounts:signInWithPassword'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        returnSecureToken: true,
      }),
    });
    const data = await response.json();
    if (!response.ok) {
      return res.status(response.status).json(data);
    }
    res.json(data);
  } catch (err) {
    console.error('Auth login error', err);
    res.status(500).json({ error: err.message });
  }
});

app.get('/usuarios/me', authenticateToken, async (req, res) => {
  try {
    const uid = req.firebaseUid;
    if (!uid) {
      return res.status(401).json({ error: 'UID no encontrado' });
    }
    const doc = await db.collection('usuarios').doc(uid).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    res.json({ id: doc.id, ...doc.data() });
  } catch (err) {
    console.error('Perfil error', err);
    res.status(500).json({ error: err.message });
  }
});

// Verificar token de Firebase Auth
app.post('/firebase/verify-token', async (req, res) => {
  const { token } = req.body;
  if (!token) return res.status(400).send('Token requerido');
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    res.json({ uid: decoded.uid, email: decoded.email });
  } catch (err) {
    res.status(401).json({ error: 'Token invalido' });
  }
});

// Obtener imagenes del laboratorio
app.get('/firebase/laboratorio', async (req, res) => {
  try {
    const snapshot = await db
      .collection('laboratorio_uploads')
      .get();

    const entries = snapshot.docs.map(doc => {
      const data = doc.data();
      const createdAt = data.createdAt;
      return {
        id: doc.id,
        key: data.key,
        url: data.url,
        originalName: data.originalName,
        createdAt: createdAt && typeof createdAt.toDate === 'function'
          ? createdAt.toDate().toISOString()
          : null,
      };
    });

    res.json(entries);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Leer coleccion
app.get('/firebase/:coleccion', async (req, res) => {
  try {
    let query = db.collection(req.params.coleccion);
    // Filtros opcionales: ?campo=valor (excluye parametros internos)
    const skip = new Set(['limit', 'offset']);
    for (const [key, value] of Object.entries(req.query)) {
      if (!skip.has(key)) query = query.where(key, '==', value);
    }
    const snapshot = await query.get();
    const docs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json(docs);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Insertar documento
app.post('/firebase/:coleccion', async (req, res) => {
  try {
    const ref = await db.collection(req.params.coleccion).add(req.body);
    res.json({ id: ref.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Actualizar documento por ID
app.patch('/firebase/:coleccion/:id', async (req, res) => {
  try {
    await db.collection(req.params.coleccion).doc(req.params.id).update(req.body);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Insertar multiples documentos en batch
app.post('/firebase/:coleccion/batch', async (req, res) => {
  const { docs } = req.body;
  if (!Array.isArray(docs) || docs.length === 0) {
    return res.status(400).json({ error: 'Se requiere array "docs"' });
  }
  try {
    const collection = db.collection(req.params.coleccion);
    const batch = db.batch();
    docs.forEach(doc => {
      const ref = collection.doc();
      batch.set(ref, { ...doc, creado: admin.firestore.FieldValue.serverTimestamp() });
    });
    await batch.commit();
    res.json({ insertados: docs.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Estado del backend
app.get('/status', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Facturapi: facturacion segura desde el backend
app.get('/facturacion/facturapi/estado', authenticateToken, ensureFacturapiConfig, (req, res) => {
  res.json({
    configurada: true,
    baseUrl: FACTURAPI_BASE_URL,
    tieneClave: Boolean(FACTURAPI_API_KEY),
  });
});

app.post('/facturacion/facturapi/productos', authenticateToken, ensureFacturapiConfig, async (req, res) => {
  try {
    const payload = req.body && typeof req.body === 'object' ? req.body : {};
    const respuesta = await facturapiRequest('/products', {
      method: 'POST',
      body: payload,
    });

    return res.status(respuesta.status).json(respuesta.payload);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.get('/facturacion/facturapi/productos/:id', authenticateToken, ensureFacturapiConfig, async (req, res) => {
  try {
    const respuesta = await facturapiRequest(`/products/${encodeURIComponent(req.params.id)}`);
    return res.status(respuesta.status).json(respuesta.payload);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.post('/facturacion/facturapi/facturas', authenticateToken, ensureFacturapiConfig, async (req, res) => {
  try {
    const payload = req.body && typeof req.body === 'object' ? req.body : {};
    const respuesta = await facturapiRequest('/invoices', {
      method: 'POST',
      body: payload,
    });

    return res.status(respuesta.status).json(respuesta.payload);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.get('/facturacion/facturapi/facturas', authenticateToken, ensureFacturapiConfig, async (req, res) => {
  try {
    const query = new URLSearchParams();
    Object.entries(req.query || {}).forEach(([key, value]) => {
      if (value !== undefined && value !== null && String(value).trim()) {
        query.set(key, String(value));
      }
    });

    const sufijo = query.toString() ? `?${query.toString()}` : '';
    const respuesta = await facturapiRequest(`/invoices${sufijo}`);
    return res.status(respuesta.status).json(respuesta.payload);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.get('/facturacion/facturapi/facturas/:id', authenticateToken, ensureFacturapiConfig, async (req, res) => {
  try {
    const respuesta = await facturapiRequest(`/invoices/${encodeURIComponent(req.params.id)}`);
    return res.status(respuesta.status).json(respuesta.payload);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.get('/facturacion/facturapi/facturas/:id/pdf', authenticateToken, ensureFacturapiConfig, async (req, res) => {
  try {
    const respuesta = await facturapiBinaryRequest(`/invoices/${encodeURIComponent(req.params.id)}/pdf`, {
      headers: {
        Accept: 'application/pdf',
      },
    });

    res.status(respuesta.status);
    res.setHeader('Content-Type', respuesta.contentType);
    res.setHeader('Content-Length', respuesta.buffer.length);
    return res.send(respuesta.buffer);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

app.get('/facturacion/facturapi/facturas/:id/xml', authenticateToken, ensureFacturapiConfig, async (req, res) => {
  try {
    const respuesta = await facturapiBinaryRequest(`/invoices/${encodeURIComponent(req.params.id)}/xml`, {
      headers: {
        Accept: 'application/xml, text/xml, text/plain;q=0.9',
      },
    });

    res.status(respuesta.status);
    res.setHeader('Content-Type', respuesta.contentType);
    res.setHeader('Content-Length', respuesta.buffer.length);
    return res.send(respuesta.buffer);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// --- Laboratorio (transcripcion por backend + Groq) ---

function generarRespuestaLocal(prompt, systemInstruction) {
  // Fallback local: respuestas de demostración para desarrollo
  const respuestasDemo = {
    'enigma': 'En el modo enigma, los desafíos se revelan gradualmente. Tu objetivo es descubrir la verdad oculta detrás de cada pista.',
    'default': `Recibí tu pregunta: "${prompt}". En desarrollo local, esta es una respuesta de demostración. Conecta Vertex AI con los permisos adecuados para respuestas en tiempo real.`,
  };
  
  const esEnigma = prompt.toLowerCase().includes('enigma');
  return esEnigma ? respuestasDemo.enigma : respuestasDemo.default;
}

app.post('/laboratorio/vertex', authenticateToken, async (req, res) => {
  try {
    console.log('\n========== [VERTEX] NUEVA SOLICITUD ==========');
    console.log('[VERTEX] UID:', req.firebaseUid);
    console.log('[VERTEX] Body recibido:', JSON.stringify(req.body));
    
    const prompt = typeof req.body?.prompt === 'string' ? req.body.prompt.trim() : '';
    if (!prompt) {
      console.log('[VERTEX] ❌ Prompt vacío');
      return res.status(400).json({ error: 'Se requiere prompt' });
    }
    console.log('[VERTEX] ✓ Prompt:', prompt.substring(0, 50) + (prompt.length > 50 ? '...' : ''));

    if (!VERTEX_PROJECT_ID) {
      console.log('[VERTEX] ❌ Falta VERTEX_PROJECT_ID');
      return res.status(500).json({ error: 'Falta VERTEX_PROJECT_ID o project_id en FIREBASE_SERVICE_ACCOUNT' });
    }

    const systemInstruction = typeof req.body?.systemInstruction === 'string' && req.body.systemInstruction.trim()
      ? req.body.systemInstruction.trim()
      : 'Eres el agente de modo enigma de Fixi. Responde en espanol, breve, claro y accionable.';

    const temperature = typeof req.body?.temperature === 'number' ? req.body.temperature : 0.2;
    const maxOutputTokens = typeof req.body?.maxOutputTokens === 'number' ? req.body.maxOutputTokens : 512;

    console.log('[VERTEX] ✓ System Instruction cargada');
    console.log('[VERTEX] ✓ Temperature:', temperature);
    console.log('[VERTEX] ✓ MaxOutputTokens:', maxOutputTokens);

    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
    console.log('[VERTEX] ✓ GoogleAuth inicializado');
    
    const client = await auth.getClient();
    console.log('[VERTEX] ✓ Client obtenido');
    
    const accessToken = await client.getAccessToken();
    console.log('[VERTEX] ✓ Access token generado');
    
    const token = typeof accessToken === 'string' ? accessToken : accessToken?.token;

    if (!token) {
      console.log('[VERTEX] ❌ Token vacío');
      return res.status(500).json({ error: 'No se pudo obtener un token de Vertex' });
    }
    console.log('[VERTEX] ✓ Token válido (length:', token.length, ')');

    // Log de diagnóstico detallado
    console.log('[VERTEX] ✓ Configuración:', {
      project: VERTEX_PROJECT_ID,
      location: VERTEX_LOCATION,
      model: VERTEX_MODEL,
      tokenLength: token?.length || 0,
      serviceAccountEmail: serviceAccount?.client_email || 'unknown',
    });

    const endpoint = `https://${VERTEX_LOCATION}-aiplatform.googleapis.com/v1/projects/${VERTEX_PROJECT_ID}/locations/${VERTEX_LOCATION}/publishers/google/models/${VERTEX_MODEL}:generateContent`;
    
    console.log('[VERTEX] ✓ Endpoint:', endpoint);
    console.log('[VERTEX] 🔄 Enviando solicitud a Vertex...');

    const vertexResponse = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [{ text: prompt }],
          },
        ],
        systemInstruction: {
          parts: [{ text: systemInstruction }],
        },
        generationConfig: {
          temperature,
          maxOutputTokens,
        },
      }),
    });

    const responseText = await vertexResponse.text();
    
    console.log('[VERTEX] ✓ Respuesta recibida');
    console.log('[VERTEX] ✓ Status:', vertexResponse.status);
    console.log('[VERTEX] ✓ Headers:', Object.fromEntries(vertexResponse.headers));
    
    if (!vertexResponse.ok) {
      console.log('[VERTEX] ⚠️  Respuesta no OK');
      console.log('[VERTEX] ⚠️  Primer 1000 chars:', responseText.substring(0, 1000));
    }

    // 403: Permisos insuficientes
    if (vertexResponse.status === 403) {
      console.error('🚨 [VERTEX] 403: Permiso denegado', {
        endpoint,
        serviceAccount: serviceAccount?.client_email,
        mensaje: responseText.substring(0, 500),
      });
      console.log('[VERTEX] ❌ Retornando 403');
      return res.status(403).json({
        error: 'Permiso denegado (403)',
        details: JSON.parse(responseText),
      });
    }

    // Otros errores
    if (!vertexResponse.ok) {
      const errorObj = (() => {
        try { return JSON.parse(responseText); } catch (_) { return { message: responseText }; }
      })();
      
      console.error(`[VERTEX] ❌ Error ${vertexResponse.status}:`, errorObj);
      console.log('[VERTEX] Retornando error:', vertexResponse.status);
      
      return res.status(vertexResponse.status).json({
        error: extraerMensajeErrorVertex(responseText, vertexResponse.status),
        details: errorObj,
      });
    }

    let decoded;
    try {
      decoded = JSON.parse(responseText);
      console.log('[VERTEX] ✓ Respuesta parseada');
    } catch (err) {
      console.error('[VERTEX] ❌ Error al parsear JSON:', err);
      console.log('[VERTEX] Primer 500 chars del response:', responseText.substring(0, 500));
      return res.status(502).json({ error: 'Respuesta invalida de Vertex' });
    }

    const textoExtraido = extraerTextoVertex(decoded);
    console.log('[VERTEX] ✓ Texto extraído (length:', textoExtraido.length, ')');
    console.log('[VERTEX] 🎉 Éxito - Retornando respuesta');
    
    res.json({
      text: textoExtraido,
      model: VERTEX_MODEL,
      location: VERTEX_LOCATION,
      projectId: VERTEX_PROJECT_ID,
      fallback: false,
    });
    console.log('[VERTEX] ========== FIN SOLICITUD ==========\n');
  } catch (err) {
    console.error('❌ [VERTEX] Excepción:', err.message);
    console.error('[VERTEX] Stack:', err.stack);
    return res.status(500).json({ error: err.message });
  }
});

app.post('/laboratorio/transcribir', authenticateToken, upload.single('file'), async (req, res) => {
  try {
    if (!GROQ_API_KEY) {
      return res.status(500).json({ error: 'Falta GROQ_API_KEY' });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'No se recibio archivo' });
    }
    if (typeof FormData === 'undefined' || typeof Blob === 'undefined') {
      return res.status(500).json({ error: 'El runtime no soporta subida multipart hacia Groq' });
    }

    const formData = new FormData();
    formData.append(
      'file',
      new Blob([req.file.buffer], { type: req.file.mimetype || 'application/octet-stream' }),
      req.file.originalname || 'audio.wav',
    );
    formData.append('model', GROQ_MODEL);
    formData.append('temperature', '0');
    formData.append('response_format', 'verbose_json');

    const groqResponse = await fetch(`${GROQ_BASE_URL}/audio/transcriptions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${GROQ_API_KEY}`,
      },
      body: formData,
    });

    const responseText = await groqResponse.text();
    if (!groqResponse.ok) {
      return res.status(groqResponse.status).json({
        error: extraerMensajeErrorGroq(responseText, groqResponse.status),
      });
    }

    let decoded;
    try {
      decoded = JSON.parse(responseText);
    } catch (err) {
      return res.status(502).json({ error: 'Respuesta invalida de Groq' });
    }

    res.json({
      text: extraerTextoTranscripcionGroq(decoded),
      model: GROQ_MODEL,
    });
  } catch (err) {
    console.error('laboratorio/transcribir', err);
    res.status(500).json({ error: err.message });
  }
});

// --- Rutas Backblaze B2 ---

// Subir archivo
app.post('/storage/upload', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No se recibio archivo' });
  const key = `${Date.now()}-${req.file.originalname}`;
  console.log('Upload request start:', {
    name: req.file.originalname,
    size: req.file.size,
    fieldname: req.file.fieldname,
  });
  try {
    console.log('Uploading to b2', key);
    await s3.send(new PutObjectCommand({
      Bucket: B2_BUCKET,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
    }));

    const url = `${B2_PUBLIC_BASE_URL}/${key}`;
    const docRef = await db.collection('laboratorio_uploads').add({
      key,
      url,
      originalName: req.file.originalname,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('Upload saved to Firestore', {
      id: docRef.id,
      url,
      bucket: B2_BUCKET,
      key,
    });
    console.log('Upload response ready', {
      docId: docRef.id,
      status: 'success',
    });
    res.json({ key, url, docId: docRef.id });
  } catch (err) {
    console.error('Upload failed', err);
    res.status(500).json({ error: err.message });
  }
});

// Listar archivos del bucket
app.get('/storage', async (req, res) => {
  try {
    const data = await s3.send(new ListObjectsV2Command({ Bucket: B2_BUCKET }));
    const files = (data.Contents || []).map(f => ({ key: f.Key, size: f.Size, modified: f.LastModified }));
    res.json(files);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// URL firmada para descargar un archivo (expira en 1 hora)
app.get('/storage/url/:key', async (req, res) => {
  try {
    const url = await getSignedUrl(
      s3,
      new GetObjectCommand({ Bucket: B2_BUCKET, Key: req.params.key }),
      { expiresIn: 3600 }
    );
    res.json({ url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Eliminar archivo
app.delete('/storage/:key', async (req, res) => {
  try {
    await s3.send(new DeleteObjectCommand({ Bucket: B2_BUCKET, Key: req.params.key }));
    res.json({ message: 'Archivo eliminado' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Puerto: ${PORT}`);
});
