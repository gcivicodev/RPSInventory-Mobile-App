// lib/src/models/m_deductible.dart

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class Deductible {
  final int id;
  final int? productId;
  final String? hcpcCode;
  final int? hcpcCodeId;
  final int? medplanId;
  final String? medPlan;
  final String? deductibleType;
  final String? deductible;
  final String? createdAt;
  final String? updatedAt;

  Deductible({
    required this.id,
    this.productId,
    this.hcpcCode,
    this.hcpcCodeId,
    this.medplanId,
    this.medPlan,
    this.deductibleType,
    this.deductible,
    this.createdAt,
    this.updatedAt,
  });

  /// Constructor de fabrica para crear una instancia de Deductible desde un mapa (JSON).
  /// Util para decodificar la respuesta de la API.
  factory Deductible.fromMap(Map<String, dynamic> map) {
    return Deductible(
      id: map['id'],
      productId: _parseInt(map['product_id']),
      hcpcCode: map['hcpc_code'],
      hcpcCodeId: _parseInt(map['hcpc_code_id']),
      medplanId: _parseInt(map['medplan_id']),
      medPlan: map['med_plan'],
      deductibleType: map['deductible_type'],
      deductible: map['deductible']?.toString(),
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  /// Metodo para convertir una instancia de Deductible a un mapa.
  /// Esencial para insertar/actualizar datos en la base de datos SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'hcpc_code': hcpcCode,
      'hcpc_code_id': hcpcCodeId,
      'medplan_id': medplanId,
      'med_plan': medPlan,
      'deductible_type': deductibleType,
      'deductible': deductible,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
