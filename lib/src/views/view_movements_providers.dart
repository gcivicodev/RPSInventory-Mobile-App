import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/models/m_movement_detail.dart';
import 'package:rpsinventory/src/providers/auth_provider.dart';
import 'package:rpsinventory/src/providers/conduces_provider.dart';
import 'package:rpsinventory/src/providers/movement_provider.dart';
import 'package:rpsinventory/src/views/view_add_movement.dart';
import 'package:rpsinventory/src/views/view_add_movement_provider.dart';
import 'package:rpsinventory/src/views/view_inventory.dart';
import 'package:rpsinventory/src/views/view_login.dart';
import 'package:rpsinventory/src/views/view_movements.dart';
import 'package:rpsinventory/src/views/view_movements_providers.dart';
import 'package:rpsinventory/src/views/view_sync_almacen.dart';
import 'package:rpsinventory/src/views/view_sync_carrero.dart';

class ViewMovementsProviders extends ConsumerStatefulWidget {
  const ViewMovementsProviders(
      {super.key, this.showSuccessSnackbar = false, this.successMessage});
  static String path = '/movements';
  final bool showSuccessSnackbar;
  final String? successMessage;

  @override
  ConsumerState<ViewMovementsProviders> createState() =>
      _ViewMovementsProvidersState();
}

class _ViewMovementsProvidersState
    extends ConsumerState<ViewMovementsProviders> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        ref.read(movementSearchQueryProvider.notifier).state =
            _searchController.text;
      }
    });

    if (widget.showSuccessSnackbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.successMessage ?? 'Operación exitosa.'),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(providerMovementsProvider);
    const primaryColor = Color(0xff0088CC);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Movimientos de Proveedores',
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
              ref.invalidate(providerMovementsProvider);
            },
            tooltip: 'Sincronizar',
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddMovementProviderView(),
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Añadir movimiento',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar movimiento...',
                hintText: 'Buscar por producto, almacén, usuario, etc.',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error al cargar movimientos: $err')),
              data: (movements) {
                if (movements.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron movimientos.',
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
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) =>
                const ViewInventory(),
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
                _buildMovementInfoColumn(
                    context,
                    'Origen',
                    movement.warehouseOriginName,
                    movement.warehouseOriginProductQuantityBeforeMovement,
                    movement.warehouseOriginProductQuantityAfterMovement,
                    warehouseType: movement.warehouseOriginType),
                _buildMovementInfoColumn(
                    context,
                    'Destino',
                    movement.warehouseDestinationName,
                    movement.warehouseDestinationProductQuantityBeforeMovement,
                    movement.warehouseDestinationProductQuantityAfterMovement,
                    warehouseType: movement.warehouseDestinationType),
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
          Text('Producto',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
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

  Widget _buildMovementInfoColumn(BuildContext context, String title,
      String? warehouseName, double? before, double? after,
      {String? warehouseType}) {
    String typeString = '';
    if (warehouseType == 'warehouse') {
      typeString = ' (almacen)';
    } else if (warehouseType == 'provider') {
      typeString = ' (proveedor)';
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Almacen: ${warehouseName ?? 'N/A'}$typeString',
              style: const TextStyle(fontWeight: FontWeight.w500)),
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
            TextSpan(
                text: label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' ${value ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}
