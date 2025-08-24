import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rpsinventory/src/models/m_inventory_products_counts.dart';
import 'package:rpsinventory/src/providers/auth_provider.dart';
import 'package:rpsinventory/src/providers/conduces_provider.dart';
import 'package:rpsinventory/src/providers/inventory_products_counts_provider.dart';
import 'package:rpsinventory/src/views/add_inventory.dart';
import 'package:rpsinventory/src/views/view_login.dart';
import 'package:rpsinventory/src/views/view_movements.dart';
import 'package:rpsinventory/src/views/view_movements_providers.dart';
import 'package:rpsinventory/src/views/view_sync_almacen.dart';
import 'package:rpsinventory/src/views/view_sync_carrero.dart';

class ViewInventory extends ConsumerWidget {
  const ViewInventory({super.key});
  static String path = '/inventory';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProductsCountsProvider);
    const primaryColor = Color(0xff0088CC);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              // ignore: use_build_context_synchronously
              Navigator.pushNamedAndRemoveUntil(
                  context, ViewLogin.path, (route) => false);
            },
            tooltip: 'Cerrar sesión',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await Navigator.pushNamed(context, ViewSyncAlmacen.path);
              ref.invalidate(inventoryProductsCountsProvider);
            },
            tooltip: 'Sincronizar',
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddInventory()),
              ).then((_) => ref.invalidate(inventoryProductsCountsProvider));
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Añadir inventario',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error al cargar el inventario: $err')),
        data: (inventory) {
          if (inventory.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron registros de inventario.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(inventoryProductsCountsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                return _buildInventoryCard(context, ref, item);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                const ViewMovements(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                const ViewMovementsProviders(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Movimientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Proveedores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(
      BuildContext context, WidgetRef ref, InventoryProductsCount item) {
    const primaryColor = Color(0xff0088CC);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product?.name ?? 'Producto no disponible',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usuario: ${item.username ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  child: const Text('Editar',
                      style: TextStyle(color: primaryColor)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddInventory(inventoryCount: item),
                      ),
                    ).then(
                            (_) => ref.invalidate(inventoryProductsCountsProvider));
                  },),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductColumn(context, item),
                _buildDateTimeColumn(context, item),
                _buildInventoryInfoColumn(context, item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductColumn(
      BuildContext context, InventoryProductsCount item) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Producto',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDetailRow('No. de producto:', item.product?.sku),
          _buildDetailRow('Barcode:', item.product?.barcodeNumber),
          _buildDetailRow('Tamaño:', item.product?.size),
          _buildDetailRow('Color:', item.product?.color),
          _buildDetailRow('Modelo:', item.product?.model),
        ],
      ),
    );
  }

  Widget _buildDateTimeColumn(
      BuildContext context, InventoryProductsCount item) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fecha/Hora',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDetailRow('Inicio:',
              item.start != null ? dateFormat.format(item.start!) : 'N/A'),
          _buildDetailRow(
              'Final:', item.end != null ? dateFormat.format(item.end!) : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInventoryInfoColumn(
      BuildContext context, InventoryProductsCount item) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inventario',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDetailRow(
              'Almacén:', item.warehouse?.name ?? 'Almacén no disponible'),
          _buildDetailRow('Cant. Previa:', item.currentQuantity),
          _buildDetailRow('Cant. Contada:', item.count),
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
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}
