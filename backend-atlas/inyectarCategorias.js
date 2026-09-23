require('dotenv').config({ path: __dirname + '/.env' });
const admin = require('firebase-admin');

if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
  console.error('Error: FIREBASE_SERVICE_ACCOUNT no encontrada en .env');
  process.exit(1);
}

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

const categoriasInformales = [
  {
    id: 'plomeria',
    nombre: 'Plomería',
    emoji: '',
    orden: 1,
    subcategorias: [
      'Reparación de fugas de agua y gas',
      'Instalación y cambio de sanitarios',
      'Destape de cañerías y drenajes',
      'Mantenimiento de boilers y calentadores',
      'Lavado e instalación de tinacos y cisternas',
      'Instalación de grifería y llaves de paso',
      'Bombas de agua y presurizadores',
    ],
  },
  {
    id: 'electricidad',
    nombre: 'Electricidad',
    emoji: '',
    orden: 2,
    subcategorias: [
      'Reparación de cortos circuitos',
      'Instalación de contactos y apagadores',
      'Cableado general y bajadas de luz',
      'Instalación de lámparas y ventiladores de techo',
      'Centros de carga e interruptores termomagnéticos',
      'Balanceo de cargas y tierra física',
      'Instalación de timbres y reflectores',
    ],
  },
  {
    id: 'carpinteria',
    nombre: 'Carpintería',
    emoji: '',
    orden: 3,
    subcategorias: [
      'Fabricación y armado de muebles a medida',
      'Reparación y ajuste de puertas y marcos',
      'Barnizado, pulido y lacado de madera',
      'Instalación y mantenimiento de clósets',
      'Cocinas integrales y repisas',
      'Cambio de bisagras y correderas de cajones',
    ],
  },
  {
    id: 'albanileria',
    nombre: 'Albañilería',
    emoji: '',
    orden: 4,
    subcategorias: [
      'Pegado de piso cerámico y azulejo',
      'Enjarres, repellados y aplanados de yeso',
      'Reparación de grietas y humedades',
      'Construcción de bardas y muretes',
      'Fundición de firmes y banquetas',
      'Pequeñas demoliciones y retiro de escombro',
    ],
  },
  {
    id: 'pintura',
    nombre: 'Pintura',
    emoji: '',
    orden: 5,
    subcategorias: [
      'Pintura en interiores y techos',
      'Pintura de fachadas y muros exteriores',
      'Impermeabilización de azoteas',
      'Resanado y preparación de paredes',
      'Pintura de herrería y barandales con esmalte',
      'Texturizados y pastas decorativas',
    ],
  },
  {
    id: 'limpieza',
    nombre: 'Limpieza',
    emoji: '',
    orden: 6,
    subcategorias: [
      'Limpieza general profunda de casas y departamentos',
      'Lavado de salas, sillones y colchones',
      'Limpieza post-construcción o remodelación',
      'Lavado y desinfección de tinacos',
      'Limpieza de vidrios, ventanas y canceles',
      'Lavado y detallado de patios y cocheras',
    ],
  },
  {
    id: 'jardineria',
    nombre: 'Jardinería',
    emoji: '',
    orden: 7,
    subcategorias: [
      'Poda y corte de pasto / césped',
      'Poda estética de árboles y arbustos',
      'Deshierbe y limpieza de terrenos y maleza',
      'Fumigación contra plagas de jardín',
      'Siembra de plantas, flores y pasto en rollo',
      'Instalación y reparación de sistemas de riego',
    ],
  },
  {
    id: 'herreria',
    nombre: 'Herrería',
    emoji: '',
    orden: 8,
    subcategorias: [
      'Fabricación y colocación de protecciones para ventana',
      'Puertas y portones metálicos',
      'Reparación de barandales y pasamanos',
      'Soldadura general a domicilio',
      'Estructuras para techumbres y sombras',
      'Colocación de cerrojos y chapas de seguridad en herrería',
    ],
  },
  {
    id: 'cerrajeria',
    nombre: 'Cerrajería',
    emoji: '',
    orden: 9,
    subcategorias: [
      'Apertura de chapas residenciales trabadas',
      'Apertura de puertas de automóviles',
      'Cambio de combinación y cilindros',
      'Duplicado de llaves a domicilio',
      'Instalación de cerrojos, manijas y cerraduras digitales',
    ],
  },
  {
    id: 'mecanica',
    nombre: 'Mecánica',
    emoji: '',
    orden: 10,
    subcategorias: [
      'Afinación básica y cambio de aceite y filtros',
      'Cambio de balatas y rectificado de frenos',
      'Talachera a domicilio / parchado de llantas',
      'Auxilio vial y paso de corriente / cambio de batería',
      'Diagnóstico automotriz por escáner OBD2',
      'Revisión y cambio de amortiguadores y suspensión',
    ],
  },
  {
    id: 'linea_blanca',
    nombre: 'Línea Blanca y Climas',
    emoji: '',
    orden: 11,
    subcategorias: [
      'Reparación y mantenimiento de lavadoras',
      'Reparación de refrigeradores y congeladores',
      'Mantenimiento e instalación de Minisplits / Aire acondicionado',
      'Reparación de hornos de microondas',
      'Mantenimiento de secadoras de ropa',
      'Reparación de estufas y hornos de gas',
    ],
  },
  {
    id: 'fletes',
    nombre: 'Fletes y Mudanzas',
    emoji: '',
    orden: 12,
    subcategorias: [
      'Fletes locales en camioneta',
      'Mudanzas residenciales pequeñas',
      'Acarreo y traslado de materiales de construcción',
      'Carga, descarga y maniobra de muebles pesados',
      'Retiro y desalojo de muebles viejos o escombros',
    ],
  },
  {
    id: 'costura',
    nombre: 'Costura y Tapicería',
    emoji: '',
    orden: 13,
    subcategorias: [
      'Ajuste de bastillas, dobladillos y cierres',
      'Arreglo y entallado de prendas de vestir',
      'Confección de cortinas, cojines y mantelería',
      'Tapizado de sillas, sillones y taburetes',
      'Bordados y arreglos de uniformes escolares y de trabajo',
    ],
  },
  {
    id: 'cuidado_personal',
    nombre: 'Cuidado Personal y Belleza',
    emoji: '',
    orden: 14,
    subcategorias: [
      'Corte de cabello y barbería a domicilio',
      'Manicura, pedicura y uñas acrílicas',
      'Peinado y maquillaje para eventos',
      'Depilación y diseño de cejas',
      'Masajes relajantes a domicilio',
    ],
  },
];

async function inyectar() {
  console.log('Actualizando categorías en Firestore (sin emojis)...');
  const batch = db.batch();

  for (const cat of categoriasInformales) {
    const docRef = db.collection('categorias').doc(cat.id);
    batch.set(docRef, {
      nombre: cat.nombre,
      emoji: '',
      orden: cat.orden,
      subcategorias: cat.subcategorias,
      actualizadoEn: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`✓ Actualizada categoría: ${cat.nombre}`);
  }

  await batch.commit();
  console.log(`\n¡Listo! ${categoriasInformales.length} categorías actualizadas sin emojis.`);
}

inyectar()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error al actualizar categorías:', err);
    process.exit(1);
  });
