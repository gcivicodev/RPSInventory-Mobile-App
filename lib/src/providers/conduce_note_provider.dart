import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/providers/user_provider.dart'; // Importar el provider del usuario

// El Record se mantiene igual, simple y limpio.
typedef ConduceNoteParams = ({int conduceId, int? conduceNoteId, String note});

/// Provider para crear o actualizar una nota de un conduce.
final conduceNoteProvider = FutureProvider.autoDispose.family<void, ConduceNoteParams>((ref, params) async {
  final dbHelper = DBHelper.instance;

  // Obtenemos el usuario actual directamente desde el provider.
  final currentUser = ref.read(currentUserProvider);

  // Validamos que el usuario esté autenticado.
  if (currentUser == null || currentUser.id == null || currentUser.username == null) {
    throw Exception('Error: Usuario no autenticado.');
  }

  // Creamos el mapa de datos para la nota con la información real del usuario.
  final data = {
    'note': params.note,
    'user_id': int.tryParse(currentUser.id!) ?? 0, // La DB espera un INTEGER
    'username': currentUser.username,
  };

  // Llamamos al método de la base de datos.
  await dbHelper.updateOrCreateConduceNote(
    conduceId: params.conduceId,
    data: data,
    conduceNoteId: params.conduceNoteId,
  );
});