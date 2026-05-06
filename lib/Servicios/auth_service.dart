import 'servicio_laboratorio.dart';

class AuthService {
  final ServicioLaboratorio _laboratorioService;

  AuthService({ServicioLaboratorio? laboratorioService})
      : _laboratorioService = laboratorioService ?? ServicioLaboratorio();

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final data = await _laboratorioService.login(
      email: email,
      password: password,
    );
    final idToken = data['idToken'] as String?;
    if (idToken == null) throw Exception('Token no recibido');
    await _laboratorioService.guardarToken(idToken);
    final perfil = await _laboratorioService.fetchPerfil(idToken);
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
    await _laboratorioService.register(
      email: email,
      password: password,
      rol: rol,
      nombre: nombre,
      categoria: categoria,
      subcategoria: subcategoria,
      descripcion: descripcion,
    );
    await login(email: email, password: password);
    final perfil = await _laboratorioService.obtenerPerfilActivo();
    return perfil['rol'] as String? ?? 'cliente';
  }

  Future<String?> restoreSession() async {
    final token = await _laboratorioService.recuperarToken();
    if (token == null) return null;
    final perfil = await _laboratorioService.fetchPerfil(token);
    return perfil['rol'] as String? ?? 'cliente';
  }
}
