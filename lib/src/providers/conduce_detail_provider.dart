import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_product.dart';

final updateConduceDetailProvider = FutureProvider.autoDispose.family<void, ({
int originalDetailId,
Product product,
String tag,
int warehouseId,
double productQuantity
})>(
      (ref, data) async {
    final db = DBHelper.instance;

    final productPrice = double.tryParse(data.product.price ?? '0.0') ?? 0.0;
    final productDeductible = double.tryParse(data.product.deductible ?? '0.0') ?? 0.0;
    final quantity = data.productQuantity;

    final deductibleTotal = (quantity * productPrice) - (quantity * productDeductible);

    final Map<String, dynamic> updatedData = {
      'product_id': data.product.id,
      'product_name': data.product.name,
      'product_item_number': data.product.itemNumber,
      'product_barcode_number': data.product.barcodeNumber,
      'product_sku': data.product.sku,
      'product_color': data.product.color,
      'product_size': data.product.size,
      'product_model': data.product.model,
      'product_manufactured': data.product.manufactured,
      'product_deductible': data.product.deductible,
      'product_deductible_type': data.product.deductibleType,
      'product_deductible_total': deductibleTotal.toString(),
      'tag_number': data.tag,
      'warehouse_id': data.warehouseId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await db.updateConduceDetail(data.originalDetailId, updatedData);
  },
);
