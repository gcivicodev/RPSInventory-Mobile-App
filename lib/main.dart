import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importa el paquete de localización
import 'package:rpsinventory/src/views/view_conduces.dart';
import 'package:rpsinventory/src/views/view_login.dart';
import 'package:rpsinventory/src/views/view_sync_carrero.dart';

void main() {
  // Asegura que los bindings de Flutter estén inicializados.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los datos de localización para español ANTES de correr la app.
  // Esta es la línea clave que soluciona el error.
  initializeDateFormatting('es_ES', null).then((_) {
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RPS Inventory',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0088CC)),
        useMaterial3: true,
      ),
      initialRoute: ViewLogin.path,
      routes: {
        ViewLogin.path: (context) => const ViewLogin(),
        ViewSyncCarrero.path: (context) => const ViewSyncCarrero(),
        ViewConduces.path: (context) => const ViewConduces(),
      },
    );
  }
}
