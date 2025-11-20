import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';
import 'package:rpsinventory/src/models/m_conduce_note.dart';
import 'package:rpsinventory/src/models/m_deductible.dart';
import 'package:rpsinventory/src/models/m_inventory_products_counts.dart';
import 'package:rpsinventory/src/models/m_movement_detail.dart';
import 'package:rpsinventory/src/models/m_movements.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';
import 'package:rpsinventory/src/models/m_warehouse_product.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;
  static const Duration _puertoRicoUtcOffset = Duration(hours: -4);
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'rps_inventory.db');
    return await openDatabase(
      path,
      version: 15,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 14) {
      await _createTables(db);
    }
    if (oldVersion < 15) {
      await _upgradeDeductiblesTable(db);
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
          completed_at TEXT,
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
          pay_method TEXT,
          items_count INTEGER,
          guarantee_commitment INTEGER,
          certification_of_instructions INTEGER,
          patient_signature TEXT,
          employee_signature TEXT,
          exonerated INTEGER
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
          address_2 TEXT,
          show_mobileapp INTEGER
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

    await _createDeductiblesTable(db);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS movements(
          id INTEGER PRIMARY KEY,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          user_id INTEGER,
          warehouse_origin_id INTEGER,
          product_id INTEGER,
          warehouse_origin_product_quantity_before_movement REAL,
          product_quantity_moved REAL,
          warehouse_origin_product_quantity_after_movement REAL,
          warehouse_destination_id INTEGER,
          warehouse_destination_product_quantity_before_movement REAL,
          warehouse_destination_product_quantity_after_movement REAL,
          username TEXT,
          local_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_products_counts(
          id INTEGER PRIMARY KEY,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          user_id TEXT,
          warehouse_id TEXT,
          product_id TEXT,
          current_quantity TEXT,
          count TEXT,
          start TEXT,
          end TEXT,
          local_id INTEGER,
          username TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS last_sync(
          id INTEGER PRIMARY KEY,
          last_sync TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS last_user_sync(
          id INTEGER PRIMARY KEY,
          user_flags TEXT
      )
    ''');
  }

  Future<List<InventoryProductsCount>> getInventoryProductsCounts() async {
    final db = await database;
    const query = '''
    SELECT 
      ipc.*,
      p.id as product_table_id,
      p.name as product_name, p.sku, p.barcode_number, p.size, p.color, p.model,
      w.id as warehouse_table_id,
      w.name as warehouse_name
    FROM inventory_products_counts ipc
    LEFT JOIN products p ON ipc.product_id = p.id
    LEFT JOIN warehouses w ON ipc.warehouse_id = w.id
    ORDER BY ipc.created_at DESC
  ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    if (maps.isNotEmpty) {
      return maps.map((map) {
        final inventoryMap = Map<String, dynamic>.from(map);

        if (map['product_table_id'] != null) {
          final productData = {
            'id': map['product_table_id'],
            'name': map['product_name'],
            'sku': map['sku'],
            'barcode_number': map['barcode_number'],
            'size': map['size'],
            'color': map['color'],
            'model': map['model'],
          };
          inventoryMap['product'] = productData;
        } else {
          inventoryMap['product'] = null;
        }

        if (map['warehouse_table_id'] != null) {
          final warehouseData = {
            'id': map['warehouse_table_id'],
            'name': map['warehouse_name'],
          };
          inventoryMap['warehouse'] = warehouseData;
        } else {
          inventoryMap['warehouse'] = null;
        }

        return InventoryProductsCount.fromJson(inventoryMap);
      }).toList();
    } else {
      return [];
    }
  }

  Future<void> addMovement({
    required int originWarehouseId,
    required int destinationWarehouseId,
    required int productId,
    required double quantity,
    int? userId,
    String? username,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      final originWp = await txn.query(
        'warehouses_products',
        where: 'warehouse_id = ? AND product_id = ?',
        whereArgs: [originWarehouseId, productId],
      );

      double originBefore = 0.0;
      if (originWp.isNotEmpty) {
        originBefore = (originWp.first['current_quantity'] as num).toDouble();
      }

      if (originBefore < quantity) {
        throw Exception('Cantidad insuficiente en el almacén de origen.');
      }
      final originAfter = originBefore - quantity;

      if (originWp.isNotEmpty) {
        await txn.update(
          'warehouses_products',
          {'current_quantity': originAfter, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [originWp.first['id']],
        );
      } else {
        throw Exception(
          'El producto no existe en el almacén de origen o no hay cantidad.',
        );
      }

      final destWp = await txn.query(
        'warehouses_products',
        where: 'warehouse_id = ? AND product_id = ?',
        whereArgs: [destinationWarehouseId, productId],
      );

      double destBefore = 0.0;
      if (destWp.isNotEmpty) {
        destBefore = (destWp.first['current_quantity'] as num).toDouble();
      }
      final destAfter = destBefore + quantity;

      if (destWp.isNotEmpty) {
        await txn.update(
          'warehouses_products',
          {'current_quantity': destAfter, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [destWp.first['id']],
        );
      } else {
        await txn.insert('warehouses_products', {
          'warehouse_id': destinationWarehouseId,
          'product_id': productId,
          'current_quantity': destAfter,
          'created_at': now,
          'updated_at': now,
        });
      }

      final movementData = {
        'created_at': now,
        'updated_at': now,
        'warehouse_origin_id': originWarehouseId,
        'product_id': productId,
        'warehouse_origin_product_quantity_before_movement': originBefore,
        'product_quantity_moved': quantity,
        'warehouse_origin_product_quantity_after_movement': originAfter,
        'warehouse_destination_id': destinationWarehouseId,
        'warehouse_destination_product_quantity_before_movement': destBefore,
        'warehouse_destination_product_quantity_after_movement': destAfter,
        'user_id': userId,
        'username': username,
      };

      final movementId = await txn.insert('movements', movementData);

      await txn.update(
        'movements',
        {'local_id': movementId},
        where: 'id = ?',
        whereArgs: [movementId],
      );
    });
  }

  Future<void> addMovementFromProvider({
    required int originWarehouseId,
    required int destinationWarehouseId,
    required int productId,
    required double quantity,
    int? userId,
    String? username,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      final destWp = await txn.query(
        'warehouses_products',
        where: 'warehouse_id = ? AND product_id = ?',
        whereArgs: [destinationWarehouseId, productId],
      );

      double destBefore = 0.0;
      if (destWp.isNotEmpty) {
        destBefore = (destWp.first['current_quantity'] as num).toDouble();
      }
      final destAfter = destBefore + quantity;

      if (destWp.isNotEmpty) {
        await txn.update(
          'warehouses_products',
          {'current_quantity': destAfter, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [destWp.first['id']],
        );
      } else {
        await txn.insert('warehouses_products', {
          'warehouse_id': destinationWarehouseId,
          'product_id': productId,
          'current_quantity': destAfter,
          'created_at': now,
          'updated_at': now,
        });
      }

      final movementData = {
        'created_at': now,
        'updated_at': now,
        'warehouse_origin_id': originWarehouseId,
        'product_id': productId,
        'warehouse_origin_product_quantity_before_movement': 0.0,
        'product_quantity_moved': quantity,
        'warehouse_origin_product_quantity_after_movement': 0.0,
        'warehouse_destination_id': destinationWarehouseId,
        'warehouse_destination_product_quantity_before_movement': destBefore,
        'warehouse_destination_product_quantity_after_movement': destAfter,
        'user_id': userId,
        'username': username,
      };

      final movementId = await txn.insert('movements', movementData);

      await txn.update(
        'movements',
        {'local_id': movementId},
        where: 'id = ?',
        whereArgs: [movementId],
      );
    });
  }

  Future<List<MovementDetail>> getMovements({String? searchTerm}) async {
    final db = await database;
    String query = '''
      SELECT
        m.id,
        m.created_at,
        p.name as product_name,
        p.sku,
        p.barcode_number,
        p.size,
        p.color,
        p.model,
        m.product_quantity_moved,
        m.username,
        wo.name as warehouse_origin_name,
        wo.type as warehouse_origin_type,
        m.warehouse_origin_product_quantity_before_movement,
        m.warehouse_origin_product_quantity_after_movement,
        wd.name as warehouse_destination_name,
        wd.type as warehouse_destination_type,
        m.warehouse_destination_product_quantity_before_movement,
        m.warehouse_destination_product_quantity_after_movement
      FROM movements m
      LEFT JOIN products p ON m.product_id = p.id
      LEFT JOIN warehouses wo ON m.warehouse_origin_id = wo.id
      LEFT JOIN warehouses wd ON m.warehouse_destination_id = wd.id
      WHERE wo.type = 'warehouse'
    ''';

    List<dynamic> args = [];
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final searchPattern = '%$searchTerm%';
      query += '''
        AND (p.name LIKE ?
        OR wo.name LIKE ?
        OR wd.name LIKE ?
        OR p.sku LIKE ?
        OR p.barcode_number LIKE ?
        OR p.size LIKE ?
        OR p.color LIKE ?
        OR p.model LIKE ?
        OR m.username LIKE ?)
      ''';
      args = List.filled(9, searchPattern);
    }

    query += ' ORDER BY m.created_at DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    if (maps.isNotEmpty) {
      return maps.map((map) => MovementDetail.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<List<MovementDetail>> getProviderMovements({
    String? searchTerm,
  }) async {
    final db = await database;
    String query = '''
      SELECT
        m.id,
        m.created_at,
        p.name as product_name,
        p.sku,
        p.barcode_number,
        p.size,
        p.color,
        p.model,
        m.product_quantity_moved,
        m.username,
        wo.name as warehouse_origin_name,
        wo.type as warehouse_origin_type,
        m.warehouse_origin_product_quantity_before_movement,
        m.warehouse_origin_product_quantity_after_movement,
        wd.name as warehouse_destination_name,
        wd.type as warehouse_destination_type,
        m.warehouse_destination_product_quantity_before_movement,
        m.warehouse_destination_product_quantity_after_movement
      FROM movements m
      LEFT JOIN products p ON m.product_id = p.id
      LEFT JOIN warehouses wo ON m.warehouse_origin_id = wo.id
      LEFT JOIN warehouses wd ON m.warehouse_destination_id = wd.id
      WHERE wo.type = 'provider'
    ''';

    List<dynamic> args = [];
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final searchPattern = '%$searchTerm%';
      query += '''
        AND (p.name LIKE ?
        OR wo.name LIKE ?
        OR wd.name LIKE ?
        OR p.sku LIKE ?
        OR p.barcode_number LIKE ?
        OR p.size LIKE ?
        OR p.color LIKE ?
        OR p.model LIKE ?
        OR m.username LIKE ?)
      ''';
      args = List.filled(9, searchPattern);
    }

    query += ' ORDER BY m.created_at DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    if (maps.isNotEmpty) {
      return maps.map((map) => MovementDetail.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getConducesForSync() async {
    final db = await database;
    return await db.query('conduces');
  }

  Future<void> _createDeductiblesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deductibles(
          id INTEGER PRIMARY KEY,
          product_id INTEGER,
          hcpc_code TEXT,
          hcpc_code_id INTEGER,
          medplan_id INTEGER,
          med_plan TEXT,
          deductible_type TEXT,
          deductible TEXT,
          created_at TEXT,
          updated_at TEXT
      )
    ''');
  }

  Future<void> _upgradeDeductiblesTable(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(deductibles)');
    final hasHcpcCodeColumn = columns.any((column) => column['name'] == 'hcpc_code');
    if (hasHcpcCodeColumn) {
      return;
    }

    await db.execute('ALTER TABLE deductibles RENAME TO deductibles_old');
    await _createDeductiblesTable(db);
    await db.execute('''
      INSERT INTO deductibles (
          id,
          product_id,
          hcpc_code,
          hcpc_code_id,
          medplan_id,
          med_plan,
          deductible_type,
          deductible,
          created_at,
          updated_at
      )
      SELECT
          id,
          CASE WHEN product_id IS NULL OR product_id = '' THEN NULL ELSE CAST(product_id AS INTEGER) END,
          NULL,
          NULL,
          CASE WHEN medplan_id IS NULL OR medplan_id = '' THEN NULL ELSE CAST(medplan_id AS INTEGER) END,
          med_plan,
          deductible_type,
          deductible,
          created_at,
          updated_at
      FROM deductibles_old
    ''');
    await db.execute('DROP TABLE deductibles_old');
  }

  Future<List<Map<String, dynamic>>> getConduceDetailsForSync() async {
    final db = await database;
    return await db.query('conduce_details');
  }

  Future<List<Map<String, dynamic>>> getConduceNotesForSync() async {
    final db = await database;
    return await db.query('conduce_notes');
  }

  Future<List<Map<String, dynamic>>> getMovementsForSync() async {
    final db = await database;
    return await db.query('movements');
  }

  Future<void> syncMovementFromServer(Movement movement) async {
    final db = await database;
    await db.transaction((txn) async {
      final localId = movement.localId;

      if (localId != null) {
        final existing = await txn.query(
          'movements',
          where: 'local_id = ?',
          whereArgs: [localId],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final existingId = existing.first['id'] as int;
          if (movement.id != existingId) {
            await txn.delete(
              'movements',
              where: 'id = ?',
              whereArgs: [movement.id],
            );
          }
          final data = movement.toMap();
          data['local_id'] = localId;
          await txn.update(
            'movements',
            data,
            where: 'id = ?',
            whereArgs: [existingId],
          );
          return;
        }
      }

      await txn.delete(
        'movements',
        where: 'id = ?',
        whereArgs: [movement.id],
      );
      await txn.insert(
        'movements',
        movement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<Map<String, dynamic>>> getInventoryProductsCountsForSync() async {
    final db = await database;
    return await db.query('inventory_products_counts');
  }

  Future<void> syncInventoryCountFromServer(
    InventoryProductsCount inventoryCount,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      final localId = inventoryCount.localId;

      if (localId != null) {
        final existing = await txn.query(
          'inventory_products_counts',
          where: 'local_id = ?',
          whereArgs: [localId],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final existingId = existing.first['id'] as int;
          if (inventoryCount.id != null && inventoryCount.id != existingId) {
            await txn.delete(
              'inventory_products_counts',
              where: 'id = ?',
              whereArgs: [inventoryCount.id],
            );
          }
          final data = inventoryCount.toMap();
          data['local_id'] = localId;
          await txn.update(
            'inventory_products_counts',
            data,
            where: 'id = ?',
            whereArgs: [existingId],
          );
          return;
        }
      }

      if (inventoryCount.id != null) {
        await txn.delete(
          'inventory_products_counts',
          where: 'id = ?',
          whereArgs: [inventoryCount.id],
        );
      }
      await txn.insert(
        'inventory_products_counts',
        inventoryCount.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> addOrUpdateDeductible(Deductible deductible) async {
    final db = await database;
    await db.insert(
      'deductibles',
      deductible.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    if (maps.isNotEmpty) {
      return maps.map((map) => Product.fromMap(map)).toList();
    } else {
      return [];
    }
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

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [
      conduceId,
      productId,
    ]);

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

  Future<void> addOrUpdateConduce(
    Conduce conduce, {
    bool fromSync = false,
  }) async {
    final db = await database;
    final batch = db.batch();

    final conduceMap = conduce.toMap();

    if (conduceMap['status'] == 'Completado') {
      conduceMap['completed_at'] = DateTime.now().toIso8601String();
    }

    batch.insert(
      'conduces',
      conduceMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.delete(
      'conduce_notes',
      where: 'conduce_id = ?',
      whereArgs: [conduce.id],
    );
    batch.delete(
      'conduce_details',
      where: 'conduce_id = ?',
      whereArgs: [conduce.id],
    );

    for (final note in conduce.notes) {
      final noteMap = note.toMap();
      noteMap['conduce_id'] = conduce.id;
      batch.insert(
        'conduce_notes',
        noteMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final detail in conduce.details) {
      final detailMap = detail.toMap();
      detailMap['conduce_id'] = conduce.id;
      batch.insert(
        'conduce_details',
        detailMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
      throw Exception(
        'Conduce con ID $conduceId no encontrado para actualizar',
      );
    }

    final currentStatus = conduceMaps.first['status'] as String?;
    final newStatus = (currentStatus?.toLowerCase() == 'pendiente')
        ? 'Completado'
        : 'Pendiente';

    final Map<String, dynamic> updateData = {'status': newStatus};
    if (newStatus == 'Completado') {
      updateData['completed_at'] = DateTime.now().toIso8601String();
    } else {
      updateData['completed_at'] = null;
    }

    await db.update(
      'conduces',
      updateData,
      where: 'id = ?',
      whereArgs: [conduceId],
    );
  }

  Future<void> updateConduceDetail(
    int conduceDetailId,
    Map<String, dynamic> data,
  ) async {
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
    await db.insert(
      'warehouses',
      warehouse.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addOrUpdateWarehouseProduct(
    WarehouseProduct warehouseProduct,
  ) async {
    final db = await database;
    await db.insert(
      'warehouses_products',
      warehouseProduct.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Warehouse>> getWarehouses({String? type}) async {
    final db = await database;

    String? where;
    List<Object?>? whereArgs;

    if (type != null) {
      where = 'type = ?';
      whereArgs = [type];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'warehouses',
      where: where,
      whereArgs: whereArgs,
    );

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

    String whereClause = 'wp.warehouse_id = ?';
    List<dynamic> whereArgs = [warehouseId];

    if (productBarcodeNumber != null && productBarcodeNumber.isNotEmpty) {
      whereClause += ' AND p.barcode_number = ?';
      whereArgs.add(productBarcodeNumber);
    }

    if (hcpcCode != null && hcpcCode.isNotEmpty) {
      whereClause += ' AND p.hcpc_code = ?';
      whereArgs.add(hcpcCode);
    }

    final String query =
        '''
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
    String barcodeNumber,
    int warehouseId,
  ) async {
    final db = await database;

    const String query = '''
      SELECT p.*, wp.current_quantity FROM products p
      INNER JOIN warehouses_products wp ON p.id = wp.product_id
      WHERE p.barcode_number = ? AND wp.warehouse_id = ? AND wp.current_quantity > 0
      LIMIT 1
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [
      barcodeNumber,
      warehouseId,
    ]);

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<bool> checkIfConduceDetailsWereAssigned(int conduceId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) FROM conduce_details
      WHERE conduce_id = ? AND (product_id IS NULL OR product_id <= 0)
    ''',
      [conduceId],
    );
    final count = Sqflite.firstIntValue(result);
    return count == 0;
  }

  Future<void> addInventoryProductCount(
    InventoryProductsCount inventoryCount,
  ) async {
    final db = await database;
    final id = await db.insert(
      'inventory_products_counts',
      inventoryCount.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.update(
      'inventory_products_counts',
      {'local_id': id},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateInventoryProductCount(
    InventoryProductsCount inventoryCount,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final dataToUpdate = <String, dynamic>{
      'updated_at': now,
      'end': now,
      'count': inventoryCount.count,
      'current_quantity': inventoryCount.currentQuantity,
    };

    if (inventoryCount.userId != null) {
      dataToUpdate['user_id'] = inventoryCount.userId;
    }

    if (inventoryCount.username != null) {
      dataToUpdate['username'] = inventoryCount.username;
    }

    await db.update(
      'inventory_products_counts',
      dataToUpdate,
      where: 'id = ?',
      whereArgs: [inventoryCount.id],
    );
  }

  Future<void> updateLastSyncDate(DateTime dateTime, {int syncId = 1}) async {
    final db = await database;
    final formattedDate = _formatAsPuertoRico(dateTime);

    await db.insert('last_sync', {
      'id': syncId,
      'last_sync': formattedDate,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getLastSyncDate({int syncId = 1}) async {
    final db = await database;
    final result = await db.query(
      'last_sync',
      columns: ['last_sync'],
      where: 'id = ?',
      whereArgs: [syncId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final value = result.first['last_sync'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  Future<void> saveLastUserFlags(String? flags, {int recordId = 1}) async {
    final db = await database;
    await db.insert(
      'last_user_sync',
      {
        'id': recordId,
        'user_flags': flags,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getLastUserFlags({int recordId = 1}) async {
    final db = await database;
    final result = await db.query(
      'last_user_sync',
      columns: ['user_flags'],
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    final value = result.first['user_flags'];
    return value is String ? value : null;
  }

  Future<void> clearWarehousesData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('warehouses_products');
      await txn.delete('warehouses');
    });
  }

  String _formatAsPuertoRico(DateTime dateTime) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final puertoRicoTime = utc.add(_puertoRicoUtcOffset);

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final year = puertoRicoTime.year.toString().padLeft(4, '0');
    final month = twoDigits(puertoRicoTime.month);
    final day = twoDigits(puertoRicoTime.day);
    final hour = twoDigits(puertoRicoTime.hour);
    final minute = twoDigits(puertoRicoTime.minute);
    final second = twoDigits(puertoRicoTime.second);

    return '$year-$month-$day $hour:$minute:$second';
  }
}
