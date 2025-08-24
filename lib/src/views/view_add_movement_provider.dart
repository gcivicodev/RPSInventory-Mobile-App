import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';
import 'package:rpsinventory/src/providers/movement_provider.dart';
import 'package:rpsinventory/src/providers/product_provider.dart';
import 'package:rpsinventory/src/providers/products_provider.dart';
import 'package:rpsinventory/src/providers/user_provider.dart';
import 'package:rpsinventory/src/providers/warehouses_provider.dart';
import 'package:rpsinventory/src/views/view_movements.dart';
import 'package:rpsinventory/src/views/view_scanner.dart';

class AddMovementProviderView extends ConsumerStatefulWidget {
  static const path = '/movements/add';
  const AddMovementProviderView({super.key});

  @override
  ConsumerState<AddMovementProviderView> createState() => _AddMovementProviderViewState();
}

class _AddMovementProviderViewState extends ConsumerState<AddMovementProviderView> {
  final _formKey = GlobalKey<FormState>();
  Warehouse? _selectedOriginWarehouse;
  Warehouse? _selectedDestinationWarehouse;
  Product? _selectedProduct;
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
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
      final results = await Future.wait([
        ref.read(productByBarcodeNumberProvider(scannedBarcode).future),
        ref.read(allProductsProvider.future),
      ]);

      if (!mounted) return;

      final productFromScan = results[0] as Product?;
      final allProducts = results[1] as List<Product>;

      if (productFromScan != null) {
        Product? productInList;
        try {
          productInList =
              allProducts.firstWhere((p) => p.id == productFromScan.id);
        } catch (e) {
          productInList = null;
        }

        if (productInList != null) {
          setState(() {
            _selectedProduct = productInList;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Producto encontrado pero no está en la lista de selección.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Producto con barcode "$scannedBarcode" no encontrado.'),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedOriginWarehouse == null ||
          _selectedDestinationWarehouse == null ||
          _selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, completa todos los campos.'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      if (_selectedOriginWarehouse!.id == _selectedDestinationWarehouse!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('El almacén de origen y destino no pueden ser el mismo.'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        final currentUser = ref.read(currentUserProvider);
        final userId =
        currentUser?.id != null ? int.tryParse(currentUser!.id!) : null;

        await ref.read(movementProvider.notifier).addMovement(
          originWarehouseId: _selectedOriginWarehouse!.id,
          destinationWarehouseId: _selectedDestinationWarehouse!.id,
          productId: _selectedProduct!.id,
          quantity: double.parse(_quantityController.text),
          userId: userId,
          username: currentUser?.username,
        );

        ref.invalidate(movementsProvider);

        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ViewMovements(
                showSuccessSnackbar: true,
                successMessage: 'Movimiento añadido con éxito.',
              ),
            ),
                (route) => route.isFirst,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al añadir el movimiento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff0088CC);
    final warehousesAsyncValue = ref.watch(movementWarehousesProvider);
    final productsAsyncValue = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Movimiento',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
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
              warehousesAsyncValue.when(
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
                data: (warehouses) {
                  return DropdownButtonFormField<Warehouse>(
                    value: _selectedOriginWarehouse,
                    decoration: const InputDecoration(
                      labelText: 'Almacén de Origen',
                      border: OutlineInputBorder(),
                    ),
                    items: warehouses.map((Warehouse warehouse) {
                      return DropdownMenuItem<Warehouse>(
                        value: warehouse,
                        child: Text(warehouse.name ?? 'N/A'),
                      );
                    }).toList(),
                    onChanged: (Warehouse? newValue) {
                      setState(() {
                        _selectedOriginWarehouse = newValue;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Campo requerido' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              productsAsyncValue.when(
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
                data: (products) {
                  return DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                    ),
                    items: products.map((Product product) {
                      final sku = product.sku ?? 'N/A';
                      final color = product.color ?? 'N/A';
                      final model = product.model ?? 'N/A';
                      final size = product.size ?? 'N/A';
                      return DropdownMenuItem<Product>(
                        value: product,
                        child: Text(
                          '${product.name ?? 'N/A'} - ($sku) - $color - $model - $size',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (Product? newValue) {
                      setState(() {
                        _selectedProduct = newValue;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Campo requerido' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad a Mover',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, ingrese un número válido';
                  }
                  if (double.parse(value) <= 0) {
                    return 'La cantidad debe ser mayor a cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              warehousesAsyncValue.when(
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
                data: (warehouses) {
                  return DropdownButtonFormField<Warehouse>(
                    value: _selectedDestinationWarehouse,
                    decoration: const InputDecoration(
                      labelText: 'Almacén de Destino',
                      border: OutlineInputBorder(),
                    ),
                    items: warehouses.map((Warehouse warehouse) {
                      return DropdownMenuItem<Warehouse>(
                        value: warehouse,
                        child: Text(warehouse.name ?? 'N/A'),
                      );
                    }).toList(),
                    onChanged: (Warehouse? newValue) {
                      setState(() {
                        _selectedDestinationWarehouse = newValue;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Campo requerido' : null,
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Guardar Movimiento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
