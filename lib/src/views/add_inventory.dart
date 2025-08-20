import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_inventory_products_counts.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';
import 'package:rpsinventory/src/providers/inventory_products_counts_provider.dart';
import 'package:rpsinventory/src/providers/products_provider.dart';
import 'package:rpsinventory/src/providers/warehouses_provider.dart';

class AddInventory extends ConsumerStatefulWidget {
  final InventoryProductsCount? inventoryCount;

  const AddInventory({super.key, this.inventoryCount});
  static String path = '/inventory/add';

  @override
  ConsumerState<AddInventory> createState() => _AddInventoryState();
}

class _AddInventoryState extends ConsumerState<AddInventory> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startTime;
  Warehouse? _selectedWarehouse;
  Product? _selectedProduct;
  final _countedQuantityController = TextEditingController();
  final _previousQuantityController = TextEditingController();

  bool get isEditing => widget.inventoryCount != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final item = widget.inventoryCount!;
      _startTime = item.start;
      _selectedWarehouse = item.warehouse;
      _selectedProduct = item.product;
      _previousQuantityController.text = item.currentQuantity ?? '';
      _countedQuantityController.text = item.count ?? '';
    } else {
      _startTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _countedQuantityController.dispose();
    _previousQuantityController.dispose();
    super.dispose();
  }

  Future<void> _saveInventory() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedWarehouse == null || _selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, seleccione un almacén y un producto.')),
        );
        return;
      }

      if (isEditing) {
        final updatedCount = InventoryProductsCount(
          id: widget.inventoryCount!.id,
          count: _countedQuantityController.text,
          currentQuantity: _previousQuantityController.text,
        );
        await DBHelper.instance.updateInventoryProductCount(updatedCount);
      } else {
        final end = DateTime.now();
        final newCount = InventoryProductsCount(
          warehouseId: _selectedWarehouse!.id.toString(),
          productId: _selectedProduct!.id.toString(),
          currentQuantity: _previousQuantityController.text,
          count: _countedQuantityController.text,
          start: _startTime,
          end: end,
          createdAt: _startTime,
          updatedAt: end,
          userId: '1',
          username: 'default_user',
        );
        await DBHelper.instance.addInventoryProductCount(newCount);
      }

      ref.invalidate(inventoryProductsCountsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Inventario ${isEditing ? 'actualizado' : 'guardado'} con éxito.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff0088CC);
    final warehousesAsync = ref.watch(warehousesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Actualizar Inventario' : 'Añadir Inventario',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              warehousesAsync.when(
                data: (warehouses) {
                  return DropdownButtonFormField<Warehouse>(
                    decoration: const InputDecoration(
                      labelText: 'Almacén',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedWarehouse,
                    items: warehouses
                        .map((w) => DropdownMenuItem(
                      value: w,
                      child: Text(w.name ?? 'N/A'),
                    ))
                        .toList(),
                    onChanged: isEditing
                        ? null
                        : (value) {
                      setState(() {
                        _selectedWarehouse = value;
                        _selectedProduct = null;
                        _previousQuantityController.clear();
                        _countedQuantityController.clear();
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Seleccione un almacén' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                const Text('No se pudieron cargar los almacenes'),
              ),
              const SizedBox(height: 16),
              if (_selectedWarehouse != null)
                Consumer(
                  builder: (context, ref, child) {
                    final productsAsync = ref.watch(
                        productsByWarehouseProvider(_selectedWarehouse!.id));
                    return productsAsync.when(
                      data: (products) {
                        return DropdownButtonFormField<Product>(
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedProduct,
                          items: products
                              .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} - ${p.sku} - ${p.color} - ${p.model} - ${p.size}'),
                          ))
                              .toList(),
                          onChanged: isEditing
                              ? null
                              : (value) {
                            setState(() {
                              _selectedProduct = value;
                              _previousQuantityController.text =
                                  value?.currentQuantity?.toString() ??
                                      '0';
                            });
                          },
                          validator: (value) =>
                          value == null ? 'Seleccione un producto' : null,
                        );
                      },
                      loading: () =>
                      const Center(child: CircularProgressIndicator()),
                      error: (err, stack) =>
                      const Text('No se pudieron cargar los productos'),
                    );
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _previousQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad Previa',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black12,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countedQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad Contada',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la cantidad contada';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveInventory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isEditing ? 'Actualizar' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
