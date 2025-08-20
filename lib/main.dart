import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rpsinventory/src/views/view_conduces.dart';
import 'package:rpsinventory/src/views/view_inventory.dart';
import 'package:rpsinventory/src/views/view_login.dart';
import 'package:rpsinventory/src/views/view_movements.dart';
import 'package:rpsinventory/src/views/view_sync_almacen.dart';
import 'package:rpsinventory/src/views/view_sync_carrero.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        ViewSyncAlmacen.path: (context) => const ViewSyncAlmacen(),
        ViewMovements.path: (context) => const ViewMovements(),
        ViewInventory.path: (context) => const ViewInventory(),
      },
    );
  }
}
