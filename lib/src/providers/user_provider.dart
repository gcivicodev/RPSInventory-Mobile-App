import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rpsinventory/src/config/main_config.dart';
import 'package:rpsinventory/src/models/m_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Estado para el proveedor de usuario
class UserState {
  final bool isLoading;
  final String? error;
  final User? userData;

  UserState({this.isLoading = false, this.error, this.userData});

  UserState copyWith({bool? isLoading, String? error, User? userData}) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userData: userData ?? this.userData,
    );
  }
}

// Notificador para la lógica del usuario
class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState());

  Future<void> fetchUserByToken(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = Uri.parse('${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/get_user_by_token');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({'token': token});

      final response = await http.post(url, headers: headers, body: body);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['error'] == null) {
        final user = User.fromJson(responseBody);
        await _saveUserData(response.body); // Guardamos el JSON crudo
        state = state.copyWith(isLoading: false, userData: user, error: null);
      } else {
        final errorMessage = responseBody['error'] ?? 'No se pudieron obtener los datos del usuario.';
        state = state.copyWith(isLoading: false, error: errorMessage);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: ${e.toString()}');
    }
  }

  Future<void> _saveUserData(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', userJson);
  }
}

// El Provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(userProvider).userData;
});
