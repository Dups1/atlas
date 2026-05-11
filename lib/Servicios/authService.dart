import 'autenticacionStorage.dart';
import 'servicioAuth.dart';
import 'servicioPerfilApi.dart';

class AutenticacionService {
  final ServicioAuth _auth;
  final ServicioPerfilApi _perfilApi;
  final AutenticacionStorage _storage;

  AutenticacionService({
    ServicioAuth? servicioAuth,
    ServicioPerfilApi? perfilApi,
    AutenticacionStorage? storage,
  })  : _auth = servicioAuth ?? ServicioAuth(),
        _perfilApi = perfilApi ?? ServicioPerfilApi(),
        _storage = storage ?? AutenticacionStorage();

  Future<void> limpiarToken() => _storage.limpiarToken();

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
    final perfil = await _perfilApi.fetchPerfil(token);
    return perfil['rol'] as String? ?? 'cliente';
  }
}
