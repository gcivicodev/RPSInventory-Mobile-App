import 'package:flutter/material.dart';

class ViewMovements extends StatelessWidget {
  const ViewMovements({super.key});
  static String path = '/movements';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
      ),
      body: const Center(
        child: Text('Movimientos'),
      ),
    );
  }
}
