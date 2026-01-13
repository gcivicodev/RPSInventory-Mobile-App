import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_inventory_products_counts.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';
import 'package:rpsinventory/src/providers/inventory_products_counts_provider.dart';
import 'package:rpsinventory/src/providers/products_provider.dart';
import 'package:rpsinventory/src/providers/warehouses_provider.dart';
import 'package:rpsinventory/src/providers/user_provider.dart';
import 'package:rpsinventory/src/views/view_scanner.dart';

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
  TextEditingController? _warehouseSearchController;
  TextEditingController? _productSearchController;

  bool get isEditing => widget.inventoryCount != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final item = widget.inventoryCount!;
      _startTime = item.start;
      _selectedWarehouse = item.warehouse;
      _selectedProduct = item.product;
      if (item.warehouse != null) {
        _warehouseSearchController?.text = _warehouseLabel(item.warehouse!);
      }
      if (item.product != null) {
        _productSearchController?.text = _productLabel(item.product!);
      }
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

  String _warehouseLabel(Warehouse warehouse) => warehouse.name ?? 'N/A';

  String _productLabel(Product product) {
    final parts = [
      product.name,
      product.sku,
      product.color,
      product.model,
      product.size,
    ].where((part) => part != null && part.toString().isNotEmpty);
    return parts.isEmpty ? 'N/A' : parts.join(' - ');
  }

  Future<void> _scanBarcode() async {
    if (_selectedWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione un almacén primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final scannedBarcode = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const ViewScanner()),
    );

    if (scannedBarcode == null || scannedBarcode.isEmpty || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final productFromScan = await DBHelper.instance
          .getProductByBarcodeNumberAndWarehouse(
          scannedBarcode, _selectedWarehouse!.id);

      if (!mounted) return;

      if (productFromScan != null) {
        ref.invalidate(productsByWarehouseProvider(_selectedWarehouse!.id));
        final productsInWarehouse = await ref
            .read(productsByWarehouseProvider(_selectedWarehouse!.id).future);

        Product? productInList;
        try {
          productInList =
              productsInWarehouse.firstWhere((p) => p.id == productFromScan.id);
        } catch (e) {
          productInList = null;
        }

        if (productInList != null) {
          setState(() {
            _selectedProduct = productInList;
            _productSearchController?.text = _productLabel(productInList!);
            _previousQuantityController.text =
                productInList?.currentQuantity?.toString() ?? '0';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'El producto no pertenece a este almacén o no tiene inventario.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto con barcode "$scannedBarcode" no encontrado.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
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

      final currentUser = ref.read(currentUserProvider);
      final userId = currentUser?.id;
      final username = currentUser?.username;

      if (userId == null || userId.isEmpty || username == null || username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo identificar al usuario autenticado.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (isEditing) {
        final updatedCount = InventoryProductsCount(
          id: widget.inventoryCount!.id,
          count: _countedQuantityController.text,
          currentQuantity: _previousQuantityController.text,
          userId: userId,
          username: username,
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
          userId: userId,
          username: username,
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
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanBarcode,
            ),
        ],
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
                  return Autocomplete<Warehouse>(
                    displayStringForOption: _warehouseLabel,
                    optionsBuilder: (textEditingValue) {
                      final query = textEditingValue.text.trim().toLowerCase();
                      if (query.isEmpty) {
                        return warehouses;
                      }
                      return warehouses.where((warehouse) {
                        final name = warehouse.name ?? '';
                        return name.toLowerCase().contains(query);
                      });
                    },
                    onSelected: isEditing
                        ? null
                        : (warehouse) {
                            setState(() {
                              _selectedWarehouse = warehouse;
                              _selectedProduct = null;
                              _productSearchController?.clear();
                              _previousQuantityController.clear();
                              _countedQuantityController.clear();
                            });
                          },
                    fieldViewBuilder: (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      if (_warehouseSearchController != textEditingController) {
                        _warehouseSearchController = textEditingController;
                        if ((_warehouseSearchController?.text.isEmpty ?? true) &&
                            _selectedWarehouse != null) {
                          _warehouseSearchController!.text =
                              _warehouseLabel(_selectedWarehouse!);
                        }
                      }
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Almacén',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !isEditing,
                        validator: (_) => _selectedWarehouse == null
                            ? 'Seleccione un almacén'
                            : null,
                        onChanged: (value) {
                          if (_selectedWarehouse != null &&
                              value != _warehouseLabel(_selectedWarehouse!)) {
                            setState(() {
                              _selectedWarehouse = null;
                              _selectedProduct = null;
                              _productSearchController?.clear();
                              _previousQuantityController.clear();
                              _countedQuantityController.clear();
                            });
                          }
                        },
                        onFieldSubmitted: (_) => onFieldSubmitted(),
                      );
                    },
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
                        return Autocomplete<Product>(
                          displayStringForOption: _productLabel,
                          optionsBuilder: (textEditingValue) {
                            final query =
                                textEditingValue.text.trim().toLowerCase();
                            if (query.isEmpty) {
                              return products;
                            }
                            return products.where((product) {
                              final haystack = _productLabel(product).toLowerCase();
                              return haystack.contains(query);
                            });
                          },
                          onSelected: isEditing
                              ? null
                              : (product) {
                                  setState(() {
                                    _selectedProduct = product;
                                    _previousQuantityController.text =
                                        product.currentQuantity?.toString() ?? '0';
                                  });
                                },
                          fieldViewBuilder: (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            if (_productSearchController != textEditingController) {
                              _productSearchController = textEditingController;
                              if ((_productSearchController?.text.isEmpty ?? true) &&
                                  _selectedProduct != null) {
                                _productSearchController!.text =
                                    _productLabel(_selectedProduct!);
                              }
                            }
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Producto',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !isEditing,
                              validator: (_) => _selectedProduct == null
                                  ? 'Seleccione un producto'
                                  : null,
                              onChanged: (value) {
                                if (_selectedProduct != null &&
                                    value != _productLabel(_selectedProduct!)) {
                                  setState(() {
                                    _selectedProduct = null;
                                    _previousQuantityController.clear();
                                  });
                                }
                              },
                              onFieldSubmitted: (_) => onFieldSubmitted(),
                            );
                          },
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
