import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';
import 'package:rpsinventory/src/models/m_conduce_note.dart';
import 'package:rpsinventory/src/models/m_deductible.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';
import 'package:rpsinventory/src/models/m_warehouse_product.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'rps_inventory.db');
    return await openDatabase(
      path,
      // Se incrementa la versión de la base de datos a 7 para activar la migración.
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE conduces ADD COLUMN guarantee_commitment INTEGER;");
        await db.execute("ALTER TABLE conduces ADD COLUMN certification_of_instructions INTEGER;");
      } catch (e) {
        if (kDebugMode) {
          print("Error al agregar columnas a 'conduces' (v4), puede que ya existan: $e");
        }
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE conduces ADD COLUMN patient_signature TEXT;");
        await db.execute("ALTER TABLE conduces ADD COLUMN employee_signature TEXT;");
      } catch (e) {
        if (kDebugMode) {
          print("Error al agregar columnas de firma a 'conduces' (v5), puede que ya existan: $e");
        }
      }
    }
    // Nueva migración para añadir la columna warehouse_id a conduce_details.
    if (oldVersion < 7) {
      try {
        await db.execute("ALTER TABLE conduce_details ADD COLUMN warehouse_id INTEGER;");
      } catch (e) {
        if (kDebugMode) {
          print("Error al agregar la columna 'warehouse_id' a 'conduce_details' (v7), puede que ya exista: $e");
        }
      }
    }
    if (oldVersion < newVersion) {
      // En caso de una nueva versión no manejada explícitamente, se recrean las tablas.
      await _createTables(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
          id INTEGER PRIMARY KEY,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          item_number TEXT,
          sku TEXT,
          tag_number TEXT,
          category_id INTEGER,
          category TEXT,
          name TEXT,
          description TEXT,
          size TEXT,
          color TEXT,
          model TEXT,
          extra TEXT,
          barcode_number TEXT,
          barcode_image TEXT,
          deductible TEXT,
          deductible_type TEXT,
          price TEXT,
          manufactured INTEGER,
          hcpc_code TEXT,
          hcpc_short_description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conduces(
          id INTEGER PRIMARY KEY,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          service_date TEXT,
          po_number TEXT,
          user_id INTEGER,
          service_type TEXT,
          record_number TEXT,
          patient_name TEXT,
          patient_plan_number TEXT,
          patient_plan INTEGER,
          patient_plan_name TEXT,
          patient_address TEXT,
          physical_city TEXT,
          physical_state TEXT,
          document_id INTEGER,
          patient_phone TEXT,
          patient_phone_2 TEXT,
          patient_dob TEXT,
          patient_sex TEXT,
          patient_weight REAL,
          patient_height REAL,
          insulin INTEGER,
          patient_signature_datetime TEXT,
          employee_signature_datetime TEXT,
          patient_no_signature_reason TEXT,
          other_person_signature_relationship TEXT,
          denial_id INTEGER,
          status TEXT,
          user_name TEXT,
          local_id INTEGER,
          deductible_total1 TEXT,
          deductible_total2 TEXT,
          deductible_total2_overwritten TEXT,
          annual_total TEXT,
          annual_total_label TEXT,
          total TEXT,
          payment_status TEXT,
          payment_amount TEXT,
          payment_amount_type TEXT,
          items_count INTEGER,
          guarantee_commitment INTEGER,
          certification_of_instructions INTEGER,
          patient_signature TEXT,
          employee_signature TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conduce_notes(
          id INTEGER PRIMARY KEY,
          conduce_id INTEGER,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          user_id INTEGER,
          note TEXT,
          username TEXT,
          editor_user_id INTEGER,
          editor_username TEXT,
          FOREIGN KEY (conduce_id) REFERENCES conduces(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conduce_details(
          id INTEGER PRIMARY KEY,
          conduce_id INTEGER,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          user_id INTEGER,
          username TEXT,
          product_id INTEGER,
          product_category_id INTEGER,
          product_name TEXT,
          product_item_number TEXT,
          product_barcode_number TEXT,
          product_sku TEXT,
          product_quantity REAL,
          product_deductible TEXT,
          product_deductible_type TEXT,
          product_deductible_total TEXT,
          product_manufactured INTEGER,
          amount_paid TEXT,
          product_extra TEXT,
          movement_id INTEGER,
          tag_number TEXT,
          product_hcpc_code TEXT,
          product_hcpc_short_description TEXT,
          product_size TEXT,
          product_model TEXT,
          product_color TEXT,
          -- Se añade la nueva columna warehouse_id.
          warehouse_id INTEGER,
          FOREIGN KEY (conduce_id) REFERENCES conduces(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS warehouses(
          id INTEGER PRIMARY KEY,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          user_id INTEGER,
          name TEXT,
          type TEXT,
          storage_capacity INTEGER,
          location_lat TEXT,
          location_lng TEXT,
          last_location_lat TEXT,
          last_location_lng TEXT,
          address_1 TEXT,
          address_2 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS warehouses_products(
          id INTEGER PRIMARY KEY,
          created_at TEXT,
          updated_at TEXT,
          warehouse_id INTEGER,
          product_id INTEGER,
          before_last_movement_quantity REAL,
          current_quantity REAL,
          FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS deductibles(
          id INTEGER PRIMARY KEY,
          product_id TEXT,
          medplan_id TEXT,
          med_plan TEXT,
          deductible_type TEXT,
          deductible TEXT,
          created_at TEXT,
          updated_at TEXT
      )
    ''');
  }

  // --- NUEVOS MÉTODOS PARA OBTENER DATOS PARA SINCRONIZAR (SUBIDA) ---

  /// Obtiene todos los registros de la tabla 'conduces' como una lista de mapas.
  Future<List<Map<String, dynamic>>> getConducesForSync() async {
    final db = await database;
    return await db.query('conduces');
  }

  /// Obtiene todos los registros de la tabla 'conduce_details' como una lista de mapas.
  Future<List<Map<String, dynamic>>> getConduceDetailsForSync() async {
    final db = await database;
    return await db.query('conduce_details');
  }

  /// Obtiene todos los registros de la tabla 'conduce_notes' como una lista de mapas.
  Future<List<Map<String, dynamic>>> getConduceNotesForSync() async {
    final db = await database;
    return await db.query('conduce_notes');
  }

  // --- MÉTODOS EXISTENTES (SIN CAMBIOS) ---

  Future<void> addOrUpdateDeductible(Deductible deductible) async {
    final db = await database;
    await db.insert('deductibles', deductible.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Deductible>> getDeductibles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('deductibles');

    if (maps.isNotEmpty) {
      return maps.map((map) => Deductible.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<void> addOrUpdateProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getProducts({String? hcpcCode}) async {
    final db = await database;
    if (hcpcCode == null || hcpcCode.isEmpty) {
      return [];
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'hcpc_code = ?',
      whereArgs: [hcpcCode],
    );
    if (maps.isNotEmpty) {
      return maps.map((map) => Product.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<Product> getProduct(int productId, int conduceId) async {
    final db = await database;
    final String query = '''
      SELECT
        p.*,
        d.deductible as pdeductible,
        d.deductible_type as pdeductible_type
      FROM products p
      LEFT JOIN deductibles d ON p.id = d.product_id AND d.medplan_id = (
        SELECT c.patient_plan FROM conduces c WHERE c.id = ?
      )
      WHERE p.id = ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [conduceId, productId]);

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      final List<Map<String, dynamic>> productMaps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (productMaps.isNotEmpty) {
        return Product.fromMap(productMaps.first);
      }
      throw Exception('Product with ID $productId not found');
    }
  }

  Future<Product?> getProductByBarcodeNumber(String barcodeNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode_number = ?',
      whereArgs: [barcodeNumber],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> addOrUpdateConduce(Conduce conduce) async {
    final db = await database;
    final batch = db.batch();

    batch.insert('conduces', conduce.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.delete('conduce_notes', where: 'conduce_id = ?', whereArgs: [conduce.id]);
    batch.delete('conduce_details', where: 'conduce_id = ?', whereArgs: [conduce.id]);

    for (final note in conduce.notes) {
      final noteMap = note.toMap();
      noteMap['conduce_id'] = conduce.id;
      batch.insert('conduce_notes', noteMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    for (final detail in conduce.details) {
      final detailMap = detail.toMap();
      detailMap['conduce_id'] = conduce.id;
      batch.insert('conduce_details', detailMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Conduce>> getConduces() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> conduceMaps = await db.query('conduces');
    final List<Conduce> conduces = [];

    for (var conduceMap in conduceMaps) {
      try {
        final mutableConduceMap = Map<String, dynamic>.from(conduceMap);
        final conduceId = mutableConduceMap['id'];

        final List<Map<String, dynamic>> noteMaps = await db.query(
          'conduce_notes',
          where: 'conduce_id = ?',
          whereArgs: [conduceId],
        );
        final List<Map<String, dynamic>> detailMaps = await db.query(
          'conduce_details',
          where: 'conduce_id = ?',
          whereArgs: [conduceId],
        );

        mutableConduceMap['notes'] = noteMaps;
        mutableConduceMap['details'] = detailMaps;

        conduces.add(Conduce.fromJson(mutableConduceMap));
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('Error al parsear conduce con ID ${conduceMap['id']}: $e');
          print(stackTrace);
        }
      }
    }
    return conduces;
  }

  Future<Conduce> getConduce(int conduceId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> conduceMaps = await db.query(
      'conduces',
      where: 'id = ?',
      whereArgs: [conduceId],
      limit: 1,
    );

    if (conduceMaps.isEmpty) {
      throw Exception('Conduce con ID $conduceId no encontrado');
    }

    final mutableConduceMap = Map<String, dynamic>.from(conduceMaps.first);

    final List<Map<String, dynamic>> noteMaps = await db.query(
      'conduce_notes',
      where: 'conduce_id = ?',
      whereArgs: [conduceId],
    );

    final List<Map<String, dynamic>> detailMaps = await db.query(
      'conduce_details',
      where: 'conduce_id = ?',
      whereArgs: [conduceId],
    );

    mutableConduceMap['notes'] = noteMaps;
    mutableConduceMap['details'] = detailMaps;

    return Conduce.fromJson(mutableConduceMap);
  }

  Future<void> updateConduceStatus(int conduceId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> conduceMaps = await db.query(
      'conduces',
      where: 'id = ?',
      whereArgs: [conduceId],
      limit: 1,
    );

    if (conduceMaps.isEmpty) {
      throw Exception('Conduce con ID $conduceId no encontrado para actualizar');
    }

    final currentStatus = conduceMaps.first['status'] as String?;
    final newStatus =
    (currentStatus?.toLowerCase() == 'pendiente') ? 'Completado' : 'Pendiente';

    await db.update(
      'conduces',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [conduceId],
    );
  }

  Future<void> updateConduceDetail(
      int conduceDetailId, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.update(
      'conduce_details',
      data,
      where: 'id = ?',
      whereArgs: [conduceDetailId],
    );
  }

  Future<void> addOrUpdateWarehouse(Warehouse warehouse) async {
    final db = await database;
    await db.insert('warehouses', warehouse.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addOrUpdateWarehouseProduct(
      WarehouseProduct warehouseProduct) async {
    final db = await database;
    await db.insert('warehouses_products', warehouseProduct.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Warehouse>> getWarehouses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('warehouses');

    if (maps.isNotEmpty) {
      return maps.map((map) => Warehouse.fromJson(map)).toList();
    } else {
      return [];
    }
  }

  Future<List<Product>> getProductsByWarehouse({
    required int warehouseId,
    String? productBarcodeNumber,
    String? hcpcCode,
  }) async {
    final db = await database;

    String whereClause = 'wp.warehouse_id = ? AND wp.current_quantity > 0';
    List<dynamic> whereArgs = [warehouseId];

    if (productBarcodeNumber != null && productBarcodeNumber.isNotEmpty) {
      whereClause += ' AND p.barcode_number = ?';
      whereArgs.add(productBarcodeNumber);
    }

    if (hcpcCode != null && hcpcCode.isNotEmpty) {
      whereClause += ' AND p.hcpc_code = ?';
      whereArgs.add(hcpcCode);
    }

    final String query = '''
      SELECT p.*, wp.current_quantity FROM products p
      INNER JOIN warehouses_products wp ON p.id = wp.product_id
      WHERE $whereClause
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    if (maps.isNotEmpty) {
      return maps.map((map) => Product.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<void> updateOrCreateConduceNote({
    required int conduceId,
    required Map<String, dynamic> data,
    int? conduceNoteId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    if (conduceNoteId != null) {
      final updateData = {
        'note': data['note'],
        'updated_at': now,
        'editor_user_id': data['user_id'],
        'editor_username': data['username'],
      };

      await db.update(
        'conduce_notes',
        updateData,
        where: 'id = ?',
        whereArgs: [conduceNoteId],
      );
    } else {
      final insertData = Map<String, dynamic>.from(data);
      insertData['conduce_id'] = conduceId;
      insertData['created_at'] = now;
      insertData['updated_at'] = now;

      await db.insert('conduce_notes', insertData);
    }
  }

  Future<ConduceNote?> getConduceNote(int conduceNoteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conduce_notes',
      where: 'id = ?',
      whereArgs: [conduceNoteId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ConduceNote.fromJson(maps.first);
    }
    return null;
  }

  Future<Product?> getProductByBarcodeNumberAndWarehouse(
      String barcodeNumber, int warehouseId) async {
    final db = await database;

    const String query = '''
      SELECT p.*, wp.current_quantity FROM products p
      INNER JOIN warehouses_products wp ON p.id = wp.product_id
      WHERE p.barcode_number = ? AND wp.warehouse_id = ? AND wp.current_quantity > 0
      LIMIT 1
    ''';

    final List<Map<String, dynamic>> maps =
    await db.rawQuery(query, [barcodeNumber, warehouseId]);

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<bool> checkIfConduceDetailsWereAssigned(int conduceId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM conduce_details
      WHERE conduce_id = ? AND (product_id IS NULL OR product_id <= 0)
    ''', [conduceId]);
    final count = Sqflite.firstIntValue(result);
    return count == 0;
  }
}
