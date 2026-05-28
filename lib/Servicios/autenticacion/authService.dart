import 'autenticacionStorage.dart';
import 'servicioAuth.dart';
import 'servicioFirebaseSync.dart';
import '../perfil/servicioPerfilApi.dart';

class autenticacionService {
  final servicioAuth _auth;
  final servicioPerfilApi _perfilApi;
  final autenticacionStorage _storage;

  autenticacionService({
    servicioAuth? authService,
    servicioPerfilApi? perfilApi,
    autenticacionStorage? storage,
  })  : _auth = authService ?? servicioAuth(),
        _perfilApi = perfilApi ?? servicioPerfilApi(),
        _storage = storage ?? autenticacionStorage();

  Future<void> limpiarToken() async {
    await servicioFirebaseSync.cerrarSesionFirebase();
    await _storage.limpiarToken();
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final data = await _auth.login(
      email: email,
      password: password,
    );
    final idToken = data['idToken'] as String?;
    if (idToken == null) throw Exception('Token no recibido');
    await _storage.guardarToken(idToken);
    try {
      await servicioFirebaseSync.sincronizarConTokenGuardado();
    } catch (_) {}
    final perfil = await _perfilApi.fetchPerfil(idToken);
    return perfil['rol'] as String? ?? 'cliente';
  }

  Future<String> register({
    required String email,
    required String password,
    required String rol,
    String? nombre,
    String? categoria,
    String? subcategoria,
    String? descripcion,
  }) async {
    await _auth.register(
      email: email,
      password: password,
      rol: rol,
      nombre: nombre,
      categoria: categoria,
      subcategoria: subcategoria,
      descripcion: descripcion,
    );
    return login(email: email, password: password);
  }

  Future<String?> restoreSession() async {
    final token = await _storage.recuperarToken();
    if (token == null) return null;
    try {
      await servicioFirebaseSync.sincronizarConTokenGuardado();
    } catch (_) {}
    final perfil = await _perfilApi.fetchPerfil(token);
    return perfil['rol'] as String? ?? 'cliente';
  }
}
