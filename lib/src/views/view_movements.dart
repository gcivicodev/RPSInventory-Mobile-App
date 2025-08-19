import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/models/m_movement_detail.dart';
import 'package:rpsinventory/src/providers/movements_provider.dart';

class ViewMovements extends ConsumerWidget {
  const ViewMovements({super.key});
  static String path = '/movements';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(movementsProvider);
    const primaryColor = Color(0xff0088CC);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Movimientos de Almacén',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: movementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar movimientos: $err')),
        data: (movements) {
          if (movements.isEmpty) {
            return const Center(
              child: Text(
                'No hay movimientos para mostrar.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];
              return _buildMovementCard(context, movement);
            },
          );
        },
      ),
    );
  }

  Widget _buildMovementCard(BuildContext context, MovementDetail movement) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    movement.productName ?? 'Producto no disponible',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cantidad movida: ${movement.productQuantityMoved?.toStringAsFixed(2) ?? "0.00"}\npor ${movement.username ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductColumn(context, movement),
                _buildMovementInfoColumn(context, 'Origen', movement.warehouseOriginName, movement.warehouseOriginProductQuantityBeforeMovement, movement.warehouseOriginProductQuantityAfterMovement),
                _buildMovementInfoColumn(context, 'Destino', movement.warehouseDestinationName, movement.warehouseDestinationProductQuantityBeforeMovement, movement.warehouseDestinationProductQuantityAfterMovement),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductColumn(BuildContext context, MovementDetail movement) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Producto', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDetailRow('No. de producto:', movement.sku),
          _buildDetailRow('Barcode:', movement.barcodeNumber),
          _buildDetailRow('Tamaño:', movement.size),
          _buildDetailRow('Color:', movement.color),
          _buildDetailRow('Modelo:', movement.model),
        ],
      ),
    );
  }

  Widget _buildMovementInfoColumn(BuildContext context, String title, String? warehouseName, double? before, double? after) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Almacen: ${warehouseName ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Antes: ${before?.toStringAsFixed(2) ?? "0.00"}'),
          const SizedBox(height: 4),
          Text('Después: ${after?.toStringAsFixed(2) ?? "0.00"}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' ${value ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}
