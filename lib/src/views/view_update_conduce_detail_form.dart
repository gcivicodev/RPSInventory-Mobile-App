import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/models/m_conduce_detail.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/providers/conduce_detail_provider.dart';
import 'package:rpsinventory/src/providers/conduce_provider.dart';
import 'package:rpsinventory/src/providers/product_provider.dart';
import 'package:rpsinventory/src/views/view_conduce_detail.dart';

import '../providers/conduces_provider.dart' show conducesProvider;

class ViewUpdateConduceDetailForm extends ConsumerStatefulWidget {
  static const path = '/conduce/update/form';
  final int productId;
  final ConduceDetail conduceDetail;
  final int warehouseId;

  const ViewUpdateConduceDetailForm({
    super.key,
    required this.productId,
    required this.conduceDetail,
    required this.warehouseId,
  });

  @override
  ConsumerState<ViewUpdateConduceDetailForm> createState() =>
      _ViewUpdateConduceDetailFormState();
}

class _ViewUpdateConduceDetailFormState
    extends ConsumerState<ViewUpdateConduceDetailForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    if (widget.productId == widget.conduceDetail.productId) {
      _tagController =
          TextEditingController(text: widget.conduceDetail.tagNumber ?? '');
    } else {
      _tagController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(Product product) async {
    if (!_formKey.currentState!.validate()) {
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
      await ref.read(updateConduceDetailProvider((
      originalDetailId: widget.conduceDetail.id,
      product: product,
      tag: _tagController.text,
      warehouseId: widget.warehouseId,
      productQuantity: widget.conduceDetail.productQuantity ?? 0.0,
      )).future);

      final conduceId = widget.conduceDetail.conduceId;
      if (conduceId != null) {
        ref.invalidate(getConduceProvider(conduceId));
      }
      ref.invalidate(conducesProvider);

      if (mounted) Navigator.of(context).pop();

      if (mounted && conduceId != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ViewConduceDetail(
              conduceId: conduceId,
              showSuccessSnackbar: true,
            ),
          ),
              (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      // throw Exception('Error al actualizar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff0088CC);

    final params = ProductProviderParams(
      productId: widget.productId,
      conduceId: widget.conduceDetail.conduceId!,
    );

    final productAsyncValue = ref.watch(productProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar Producto en Conduce',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: productAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error al cargar producto: $err')),
        data: (product) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildReadOnlyTextField(
                      label: 'Producto', value: product.name),
                  _buildReadOnlyTextField(
                      label: 'Barcode', value: product.barcodeNumber),
                  _buildReadOnlyTextField(label: 'SKU', value: product.sku),
                  _buildReadOnlyTextField(label: 'Size', value: product.size),
                  _buildReadOnlyTextField(label: 'Color', value: product.color),
                  _buildReadOnlyTextField(
                      label: 'Modelo', value: product.model),
                  _buildReadOnlyTextField(
                      label: 'Cantidad',
                      value: widget.conduceDetail.productQuantity?.toString()),
                  _buildReadOnlyTextField(
                      label: 'Deducible', value: product.deductible ?? '0.00'),
                  _buildReadOnlyTextField(
                      label: 'Tipo de Deducible',
                      value: product.deductibleType ?? 'N/A'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Tag',
                      border: OutlineInputBorder(),
                      helperText: 'Ingrese el número de tag del producto.',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El tag es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _submitForm(product),
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
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyTextField({required String label, String? value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: value ?? 'N/A',
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          fillColor: Colors.grey.shade200,
          filled: true,
        ),
      ),
    );
  }
}
