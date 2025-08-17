import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/models/m_user.dart';
import 'package:rpsinventory/src/providers/auth_provider.dart';
import 'package:rpsinventory/src/providers/user_provider.dart'; // Importa el provider de usuario
import 'package:rpsinventory/src/views/view_sync_carrero.dart'; // Importa la vista de sincronización

class ViewLogin extends ConsumerStatefulWidget {
  const ViewLogin({super.key});
  static String path = '/login';

  @override
  ConsumerState<ViewLogin> createState() => _ViewLoginState();
}

class _ViewLoginState extends ConsumerState<ViewLogin> {
  final _formKey = GlobalKey<FormState>();
  final _user = User();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ref.read(authProvider.notifier).login(_user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);

    // Escucha el estado del usuario para la navegación
    ref.listen<UserState>(userProvider, (previous, next) {
      if (next.userData != null) {
        if (next.userData!.flags == 'CC') {
          Navigator.of(context).pushReplacementNamed(ViewSyncCarrero.path);
        } else {
          // Aquí puedes manejar otros roles, por ejemplo, navegar a otra vista
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rol de usuario no manejado.')),
          );
        }
      }
    });

    final isLoading = authState.isLoading || userState.isLoading;
    final errorMessage = authState.error ?? userState.error;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/img/logo.png', height: 120),
              const SizedBox(height: 48.0),
              SizedBox(
                width: screenWidth * 0.6,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'El campo Usuario es requerido.' : null,
                        onSaved: (v) => _user.username = v,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24.0),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                        obscureText: true,
                        validator: (v) => v!.isEmpty ? 'El campo Contraseña es requerido.' : null,
                        onSaved: (v) => _user.password = v,
                        onFieldSubmitted: (_) => isLoading ? null : _submit(),
                      ),
                      const SizedBox(height: 24.0),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (isLoading)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text("Autenticando..."),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 48.0),
                          ),
                          child: const Text('Iniciar Sesión'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
