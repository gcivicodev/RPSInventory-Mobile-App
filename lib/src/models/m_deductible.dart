// lib/src/models/m_deductible.dart

class Deductible {
  final int id;
  final String? productId;
  final String? medplanId;
  final String? medPlan;
  final String? deductibleType;
  final String? deductible;
  final String? createdAt;
  final String? updatedAt;

  Deductible({
    required this.id,
    this.productId,
    this.medplanId,
    this.medPlan,
    this.deductibleType,
    this.deductible,
    this.createdAt,
    this.updatedAt,
  });

  /// Constructor de fábrica para crear una instancia de Deductible desde un mapa (JSON).
  /// Útil para decodificar la respuesta de la API.
  factory Deductible.fromMap(Map<String, dynamic> map) {
    return Deductible(
      id: map['id'],
      productId: map['product_id']?.toString(),
      medplanId: map['medplan_id']?.toString(),
      medPlan: map['med_plan'],
      deductibleType: map['deductible_type'],
      deductible: map['deductible']?.toString(),
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  /// Método para convertir una instancia de Deductible a un mapa.
  /// Esencial para insertar/actualizar datos en la base de datos SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'medplan_id': medplanId,
      'med_plan': medPlan,
      'deductible_type': deductibleType,
      'deductible': deductible,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
