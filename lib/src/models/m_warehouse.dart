import 'dart:convert';

// Funciones auxiliares para parseo seguro
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<Warehouse> warehousesFromJson(String str) => List<Warehouse>.from(json.decode(str).map((x) => Warehouse.fromJson(x)));
String warehouseToJson(Warehouse data) => json.encode(data.toMap());

class Warehouse {
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int? userId;
  final String? name;
  final String? type;
  final int? storageCapacity;
  final String? locationLat;
  final String? locationLng;
  final String? lastLocationLat;
  final String? lastLocationLng;
  final String? address1;
  final String? address2;

  Warehouse({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.userId,
    this.name,
    this.type,
    this.storageCapacity,
    this.locationLat,
    this.locationLng,
    this.lastLocationLat,
    this.lastLocationLng,
    this.address1,
    this.address2,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    id: json["id"],
    createdAt: _parseDate(json["created_at"]),
    updatedAt: _parseDate(json["updated_at"]),
    deletedAt: _parseDate(json["deleted_at"]),
    userId: _parseInt(json["user_id"]),
    name: json["name"],
    type: json["type"],
    storageCapacity: _parseInt(json["storage_capacity"]),
    locationLat: json["location_lat"],
    locationLng: json["location_lng"],
    lastLocationLat: json["last_location_lat"],
    lastLocationLng: json["last_location_lng"],
    address1: json["address_1"],
    address2: json["address_2"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt?.toIso8601String(),
    "user_id": userId,
    "name": name,
    "type": type,
    "storage_capacity": storageCapacity,
    "location_lat": locationLat,
    "location_lng": locationLng,
    "last_location_lat": lastLocationLat,
    "last_location_lng": lastLocationLng,
    "address_1": address1,
    "address_2": address2,
  };
}
