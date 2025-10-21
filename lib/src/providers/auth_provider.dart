import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rpsinventory/src/config/main_config.dart';
import 'package:rpsinventory/src/models/m_user.dart';
import 'user_provider.dart'; // Importamos el nuevo provider

// El estado no cambia
class AuthState {
  final bool isLoading;
  final String? error;
  final String? token;

  AuthState({this.isLoading = false, this.error, this.token});

  AuthState copyWith({bool? isLoading, String? error, String? token}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      token: token ?? this.token,
    );
  }
}

// El notificador ahora necesita una referencia (ref) para llamar a otros providers
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(AuthState());

  Future<void> login(User user) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = Uri.parse('${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/login');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({'username': user.username, 'password': user.password});

      final response = await http.post(url, headers: headers, body: body);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['token'] != null) {
        final token = responseBody['token'];
        await _saveToken(token);
        state = state.copyWith(isLoading: false, token: token, error: null);

        // Después de un login exitoso, obtenemos los datos del usuario.
        await _ref.read(userProvider.notifier).fetchUserByToken(token);

      } else {
        final errorMessage = responseBody['error'] ?? 'Error desconocido';
        state = state.copyWith(isLoading: false, error: errorMessage);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: ${e.toString()}');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userData');
    state = AuthState();
  }
}

// El provider ahora pasa el 'ref' al notificador
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
