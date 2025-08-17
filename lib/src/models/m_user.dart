import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  String? id;
  String? username;
  String? password;
  String? email;
  String? flags;
  String? assocMedplanId;
  String? assocMedplans;
  String? status;
  String? fullName;
  String? employee;
  String? coordinadordeservicios;
  String? token;
  String? error;

  User({
    this.id,
    this.username,
    this.password,
    this.email,
    this.flags,
    this.assocMedplanId,
    this.assocMedplans,
    this.status,
    this.fullName,
    this.employee,
    this.coordinadordeservicios,
    this.token,
    this.error,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    username: json["username"],
    email: json["email"],
    flags: json["flags"],
    assocMedplanId: json["assoc_medplan_id"],
    assocMedplans: json["assoc_medplans"],
    status: json["status"],
    fullName: json["full_name"],
    employee: json["employee"],
    coordinadordeservicios: json["coordinadordeservicios"],
    token: json["token"],
    error: json["error"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "password": password,
    "email": email,
    "flags": flags,
    "assoc_medplan_id": assocMedplanId,
    "assoc_medplans": assocMedplans,
    "status": status,
    "full_name": fullName,
    "employee": employee,
    "coordinadordeservicios": coordinadordeservicios,
    "token": token,
    "error": error,
  };
}
