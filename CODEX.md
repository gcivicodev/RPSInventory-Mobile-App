## Contexto: 
- DBHelper.addOrUpdateProduct escribe cada producto con ConflictAlgorithm.replace, lo que actualiza o inserta sin vaciar la tabla (lib/src/db_helper.dart:641). 
- No existe ningún DELETE o limpieza masiva sobre products, así que los datos previos permanecen aunque cambie el usuario. 
- El historial de sincronización se guarda en la tabla last_sync y se expone vía getLastSyncDate / updateLastSyncDate (lib/src/db_helper.dart:1051, lib/src/db_helper.dart:1063). 
- Esto permite reciclar la misma marca de tiempo entre inicios de sesión. 
- La descarga de productos usa esa marca de tiempo para pedir solo los cambios posteriores (lib/src/providers/sync_provider.dart:253-271), y cada respuesta se inserta con el mismo método de “upsert”, por lo que también se añaden productos que aún no estaban en SQLite. 
- Las pantallas de sincronización consultan y actualizan el last_sync adecuado en los momentos correctos: ViewSyncCarrero trabaja con syncId por defecto (lib/src/views/view_sync_carrero.dart:32-59) y ViewSyncAlmacen usa un syncId independiente para su ciclo (lib/src/views/view_sync_almacen.dart:31-63). 
- Tras completarse la sincronización, ambos guardan la nueva marca de tiempo antes de redirigir. 

## Ajustes: 
- Actualmente la marca de tiempo guardada es DateTime.now() del dispositivo. 
- Si el reloj local está adelantado respecto al servidor, podrían omitirse actualizaciones posteriores hasta que la hora real alcance ese valor.

---

## Cambios Clave
- lib/src/providers/sync_provider.dart:4,83-87,741-769 ahora toma la cabecera HTTP Date (con parseHttpDate) para registrar la última hora de servidor, la alinea con el reloj del dispositivo para corregir deriva y la           
  reaprovecha a lo largo del ciclo de descarga. Cada petición exitosa invoca _recordServerSync, garantizando que el timestamp persistido nunca esté por delante del backend.
- lib/src/views/view_sync_carrero.dart:52-59 y lib/src/views/view_sync_almacen.dart:54-58 usan el timestamp alineado proveniente del syncProvider al cerrar la sincronización (con fallback seguro a DateTime.now() si el backend
  no expone la cabecera), eliminando la dependencia directa del reloj local.
- pubspec.yaml:39 declara http_parser como dependencia directa para cumplir con los lints al consumir parseHttpDate.

## Validación
- Ejecuté flutter pub get para asegurar que la nueva dependencia quede registrada. No corrí pruebas manuales ni automatizadas. 

## Ajustes Realizados
- lib/src/db_helper.dart:33 define una constante _puertoRicoUtcOffset (-4 h) para usar siempre el huso horario America/Puerto_Rico.
- lib/src/db_helper.dart:1102-1107 hace que updateLastSyncDate utilice _formatAsPuertoRico antes de guardar, de modo que cualquier DateTime (sea local o UTC) se normaliza contra la zona horaria del backend.
- lib/src/db_helper.dart:1131-1141 incorpora el helper _formatAsPuertoRico, que convierte el timestamp a UTC, aplica el offset fijo y construye manualmente la cadena yyyy-MM-dd HH:mm:ss para evitar que DateFormat lo vuelva a  
  ajustar al horario del dispositivo.
- Ejecuté dart format sobre lib/src/db_helper.dart para mantener el estilo consistente.  