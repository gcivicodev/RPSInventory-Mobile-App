import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/models/m_conduce_detail.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';
import 'package:rpsinventory/src/providers/product_provider.dart';
import 'package:rpsinventory/src/providers/products_provider.dart';
import 'package:rpsinventory/src/providers/warehouses_provider.dart';
import 'package:rpsinventory/src/views/view_scanner.dart';
import 'package:rpsinventory/src/views/view_update_conduce_detail_form.dart';


final _selectedWarehouseProvider = StateProvider.autoDispose<int?>((ref) => null);

final _searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class ViewUpdateConduceDetail extends ConsumerStatefulWidget {
  static String path = '/conduce/update';
  final ConduceDetail conduceDetail;

  const ViewUpdateConduceDetail({super.key, required this.conduceDetail});

  @override
  ConsumerState<ViewUpdateConduceDetail> createState() => _ViewUpdateConduceDetailState();
}

class _ViewUpdateConduceDetailState extends ConsumerState<ViewUpdateConduceDetail> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(warehousesProvider, (previous, next) {
      if (next.hasValue && next.value!.isNotEmpty) {
        final warehouses = next.value!;
        if (ref.read(_selectedWarehouseProvider) == null) {
          ref.read(_selectedWarehouseProvider.notifier).state = warehouses.first.id;
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final warehouseId = ref.read(_selectedWarehouseProvider);

    if (warehouseId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione una bodega antes de escanear.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final checkparams = ProductsByWarehouseParams(
      warehouseId: warehouseId,
      hcpcCode: widget.conduceDetail.productHcpcCode,
    );
    final availableProducts = await ref.read(getProductsByWarehouseProvider(checkparams).future);

    if (availableProducts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No existen productos disponibles en bodega para escanear.'),
          backgroundColor: Colors.redAccent,
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

    if (kDebugMode) {
      print(' ========================= Barcode escaneado: $scannedBarcode en Bodega ID: $warehouseId');
    }

    final params = ProductByBarcodeParams(barcode: scannedBarcode, warehouseId: warehouseId);
    final product = await ref.read(productByBarcodeNumberAndWarehouseProvider(params).future);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (product != null) {
      double availableQuantity = product.currentQuantity ?? 0.0;
      double requestedQuantity = widget.conduceDetail.productQuantity ?? 0.0;

      if (availableQuantity >= requestedQuantity) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewUpdateConduceDetailForm(
              productId: product.id,
              conduceDetail: widget.conduceDetail,
              warehouseId: warehouseId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cantidad solicitada ($requestedQuantity) mayor a la disponible ($availableQuantity).'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto con barcode "$scannedBarcode" no encontrado o sin stock en la bodega seleccionada.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff0088CC);
    final selectedWarehouseId = ref.watch(_selectedWarehouseProvider);
    final warehousesAsyncValue = ref.watch(warehousesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seleccionar Producto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoSection(context),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: warehousesAsyncValue.when(
                        data: (warehouses) {
                          if (warehouses.isEmpty) {
                            return const Text('No hay bodegas');
                          }

                          final isSelectedIdValid = warehouses.any((w) => w.id == selectedWarehouseId);
                          final displayId = isSelectedIdValid ? selectedWarehouseId : warehouses.first.id;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (ref.read(_selectedWarehouseProvider) == null && warehouses.isNotEmpty) {
                              ref.read(_selectedWarehouseProvider.notifier).state = displayId;
                            }
                          });

                          return DropdownButtonFormField<int>(
                            value: displayId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Bodega',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            items: warehouses.map((Warehouse warehouse) {
                              return DropdownMenuItem<int>(
                                value: warehouse.id,
                                child: Text(
                                  warehouse.name ?? 'Sin nombre',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              ref.read(_selectedWarehouseProvider.notifier).state = newValue;
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => const Text('Error bodegas'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Filtrar productos...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(_searchQueryProvider.notifier).state = value;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedWarehouseId == null
                ? const Center(child: Text('Por favor, seleccione una bodega.'))
                : _buildProductList(selectedWarehouseId, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleMedium,
              children: [
                const TextSpan(text: 'HCPC: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: widget.conduceDetail.productHcpcCode ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.normal)),
              ],
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleMedium,
              children: [
                const TextSpan(text: 'Cantidad: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: widget.conduceDetail.productQuantity?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.normal)),
              ],
            ),
          ),
        ),
        Expanded(
          child: RichText(
            textAlign: TextAlign.end,
            text: TextSpan(
              style: Theme.of(context).textTheme.titleMedium,
              children: [
                const TextSpan(text: 'Desc: ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: widget.conduceDetail.productHcpcShortDescription ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.normal, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(int warehouseId, Color primaryColor) {
    final params = ProductsByWarehouseParams(
      warehouseId: warehouseId,
      hcpcCode: widget.conduceDetail.productHcpcCode,
    );
    final productsAsyncValue = ref.watch(getProductsByWarehouseProvider(params));
    final searchQuery = ref.watch(_searchQueryProvider);

    return productsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error al cargar productos: $err')),
      data: (products) {
        final filteredProducts = products.where((product) {
          final query = searchQuery.toLowerCase();
          if (query.isEmpty) return true;

          return (product.name?.toLowerCase() ?? '').contains(query) ||
              (product.sku?.toLowerCase() ?? '').contains(query) ||
              (product.barcodeNumber?.toLowerCase() ?? '').contains(query) ||
              (product.itemNumber?.toLowerCase() ?? '').contains(query);
        }).toList();

        if (filteredProducts.isEmpty) {
          return const Center(
            child: Text(
              'No se encontraron productos disponibles en esta bodega.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return _buildProductCard(context, product, primaryColor, widget.conduceDetail, warehouseId);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, Color primaryColor, ConduceDetail conduceDetail, int warehouseId) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.name ?? 'Nombre no disponible',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Disponible: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: product.currentQuantity?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    double quant = product.currentQuantity ?? 0.0;
                    if(quant >= (widget.conduceDetail.productQuantity ?? 0.0)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewUpdateConduceDetailForm(
                            productId: product.id,
                            conduceDetail: conduceDetail,
                            warehouseId: warehouseId,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cantidad solicitada mayor a la disponible.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Seleccionar'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
                5: FlexColumnWidth(2.5),
                6: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('HCPC'),
                    _buildTableHeader('Size'),
                    _buildTableHeader('Color'),
                    _buildTableHeader('Modelo'),
                    _buildTableHeader('Número'),
                    _buildTableHeader('Barcode'),
                    _buildTableHeader('Categoría'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableCell(product.hcpcCode),
                    _buildTableCell(product.size),
                    _buildTableCell(product.color),
                    _buildTableCell(product.model),
                    _buildTableCell(product.itemNumber),
                    _buildTableCell(product.barcodeNumber),
                    _buildTableCell(product.category),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTableCell(String? text) {
    return Text(
      text ?? 'N/A',
      style: const TextStyle(fontSize: 12),
    );
  }
}
