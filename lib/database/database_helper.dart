import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smartcare.db');
    
    // Check if database exists and get its version
    bool dbExists = await databaseExists(path);
    if (dbExists) {
      final tempDb = await openDatabase(path, readOnly: true);
      final version = await tempDb.rawQuery('PRAGMA user_version');
      final currentVersion = version.first['user_version'] as int;
      await tempDb.close();
      
      print('📊 Existing database version: $currentVersion');
      
      if (currentVersion < 3) {
        print('⚠️ Database needs upgrade, forcing it now...');
      }
    }
    
    return await openDatabase(
      path,
      version: 3, // Updated version for appointments
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Added upgrade support
    );
  }

  // ADDED: Database upgrade method
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add appointments table if upgrading from version 1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          date_time TEXT NOT NULL,
          location TEXT NOT NULL,
          doctor_name TEXT,
          type TEXT NOT NULL DEFAULT 'routine',
          notes TEXT,
          phone_number TEXT,
          completed INTEGER NOT NULL DEFAULT 0,
          reminder_date TEXT,
          status TEXT NOT NULL DEFAULT 'scheduled',
          address TEXT,
          estimated_duration_minutes INTEGER,
          created_at TEXT,
          updated_at TEXT
        )
      ''');
      
      // Insert sample appointments for version 2
      await _insertSampleAppointments(db);
    }
    
    if (oldVersion < 3) {
      // Ensure appointments table exists in version 3
      await _ensureAppointmentsTable(db);
    }
    
    print('✅ Database upgrade completed');
  }

  // ADDED: Method to ensure appointments table exists
  Future<void> _ensureAppointmentsTable(Database db) async {
    try {
      final List<Map<String, dynamic>> tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='appointments'"
      );
      
      if (tableCheck.isEmpty) {
        print('⚠️ Creating missing appointments table...');
        
        await db.execute('''
          CREATE TABLE appointments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            date_time TEXT NOT NULL,
            location TEXT NOT NULL,
            doctor_name TEXT,
            type TEXT NOT NULL DEFAULT 'routine',
            notes TEXT,
            phone_number TEXT,
            completed INTEGER NOT NULL DEFAULT 0,
            reminder_date TEXT,
            status TEXT NOT NULL DEFAULT 'scheduled',
            address TEXT,
            estimated_duration_minutes INTEGER,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        
        await _insertSampleAppointments(db);
        print('✅ Appointments table created with sample data');
      }
    } catch (e) {
      print('❌ Error ensuring appointments table: $e');
    }
  }

  // ADDED: Public method to ensure appointments table exists
  Future<void> ensureAppointmentsTableExists() async {
    try {
      final db = await database;
      
      // Check if appointments table exists
      final List<Map<String, dynamic>> tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='appointments'"
      );
      
      if (tableCheck.isEmpty) {
        print('⚠️ Appointments table missing, creating it now...');
        
        // Create appointments table
        await db.execute('''
          CREATE TABLE appointments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            date_time TEXT NOT NULL,
            location TEXT NOT NULL,
            doctor_name TEXT,
            type TEXT NOT NULL DEFAULT 'routine',
            notes TEXT,
            phone_number TEXT,
            completed INTEGER NOT NULL DEFAULT 0,
            reminder_date TEXT,
            status TEXT NOT NULL DEFAULT 'scheduled',
            address TEXT,
            estimated_duration_minutes INTEGER,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        
        print('✅ Appointments table created successfully');
        
        // Add sample appointments
        await _insertSampleAppointments(db);
        
        // Verify table creation
        final appointments = await db.query('appointments');
        print('✅ ${appointments.length} sample appointments added');
        
      } else {
        print('✅ Appointments table already exists');
      }
    } catch (e) {
      print('❌ Error ensuring appointments table: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table (removed next_appointment field)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        adherence_streak INTEGER DEFAULT 0,
        location TEXT,
        viral_load TEXT,
        cd4_count TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Enhanced medications table with comprehensive tracking
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        alarms TEXT NOT NULL,
        current_stock INTEGER DEFAULT 0,
        original_stock INTEGER DEFAULT 0,
        collection_date TEXT,
        days_until_collection INTEGER DEFAULT 0,
        instructions TEXT,
        dosage TEXT,
        color TEXT,
        shape TEXT,
        is_temporary INTEGER DEFAULT 0,
        category TEXT DEFAULT 'daily',
        temporary_end_date TEXT,
        pharmacy_info TEXT,
        last_refill_date TEXT NOT NULL,
        interactions TEXT,
        food_requirements TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Enhanced daily tasks table
    await db.execute('''
      CREATE TABLE daily_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT NOT NULL,
        completed INTEGER DEFAULT 0,
        medication_id INTEGER,
        time TEXT,
        category TEXT,
        task_date TEXT,
        pills_to_take INTEGER,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (medication_id) REFERENCES medications (id)
      )
    ''');

    // Medication doses tracking table - tracks each time medication is taken
    await db.execute('''
      CREATE TABLE medication_doses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        time TEXT NOT NULL,
        pills_taken INTEGER NOT NULL,
        pills_scheduled INTEGER NOT NULL,
        date_taken TEXT NOT NULL,
        was_on_time INTEGER DEFAULT 1,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (medication_id) REFERENCES medications (id)
      )
    ''');

    // Stock changes tracking table - tracks when pills are added/removed
    await db.execute('''
      CREATE TABLE stock_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        change_amount INTEGER NOT NULL,
        change_type TEXT NOT NULL,
        reason TEXT,
        previous_stock INTEGER NOT NULL,
        new_stock INTEGER NOT NULL,
        created_at TEXT,
        FOREIGN KEY (medication_id) REFERENCES medications (id)
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    // Clinics table
    await db.execute('''
      CREATE TABLE clinics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        distance TEXT,
        services TEXT,
        rating REAL,
        is_open INTEGER DEFAULT 1,
        phone TEXT,
        address TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Mobile clinics table
    await db.execute('''
      CREATE TABLE mobile_clinics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        date TEXT,
        time TEXT,
        services TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Appointments table
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date_time TEXT NOT NULL,
        location TEXT NOT NULL,
        doctor_name TEXT,
        type TEXT NOT NULL DEFAULT 'routine',
        notes TEXT,
        phone_number TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        reminder_date TEXT,
        status TEXT NOT NULL DEFAULT 'scheduled',
        address TEXT,
        estimated_duration_minutes INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Insert default data
    await _insertDefaultData(db);
  }

  // ADDED: Separate method for inserting sample appointments
  Future<void> _insertSampleAppointments(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    try {
      // Insert sample appointments
      await db.insert('appointments', {
        'title': 'Check-up with Dr. Smith',
        'date_time': DateTime.now().add(Duration(days: 6)).toIso8601String(),
        'location': 'Charlotte Maxeke Hospital',
        'doctor_name': 'Dr. Sarah Smith',
        'type': 'routine',
        'notes': 'Bring previous test results',
        'phone_number': '011 488 4911',
        'completed': 0,
        'status': 'scheduled',
        'address': '7 York Road, Parktown, Johannesburg',
        'estimated_duration_minutes': 60,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('appointments', {
        'title': 'Blood Test - Viral Load',
        'date_time': DateTime.now().add(Duration(days: 26)).toIso8601String(),
        'location': 'Lancet Laboratories',
        'doctor_name': null,
        'type': 'lab',
        'notes': 'Fasting required - no food 12 hours before',
        'phone_number': '010 001 0001',
        'completed': 0,
        'status': 'scheduled',
        'address': 'Sandton Medical Centre, Sandton',
        'estimated_duration_minutes': 30,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('appointments', {
        'title': 'Follow-up - ARV Adjustment',
        'date_time': DateTime.now().add(Duration(days: 3)).toIso8601String(),
        'location': 'Helen Joseph Hospital',
        'doctor_name': 'Dr. Michael Johnson',
        'type': 'follow-up',
        'notes': 'Discuss side effects and medication adjustments',
        'phone_number': '011 276 8000',
        'completed': 0,
        'status': 'scheduled',
        'address': 'Perth Road, Westdene, Johannesburg',
        'estimated_duration_minutes': 45,
        'created_at': now,
        'updated_at': now,
      });
      
      print('✅ Sample appointments inserted successfully');
    } catch (e) {
      print('❌ Error inserting sample appointments: $e');
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Insert default user (removed next_appointment)
    await db.insert('users', {
      'name': 'Alex',
      'adherence_streak': 12,
      'location': 'Johannesburg, Gauteng',
      'viral_load': 'Undetectable',
      'cd4_count': '650',
      'created_at': now,
      'updated_at': now,
    });

    // Insert default medications with enhanced alarm system
    await db.insert('medications', {
      'name': 'Multivitamins',
      'alarms': '[{"time":"08:00","pillsPerDose":2,"notes":"Take with breakfast"},{"time":"20:00","pillsPerDose":1,"notes":"Take with dinner"}]',
      'current_stock': 27,
      'original_stock': 30,
      'collection_date': 'June 25, 2025',
      'days_until_collection': 9,
      'instructions': 'Take with food to improve absorption',
      'dosage': '3 tablets daily',
      'color': 'Yellow',
      'shape': 'Round',
      'is_temporary': 0,
      'category': 'daily',
      'pharmacy_info': 'Clicks Pharmacy - Sandton',
      'last_refill_date': '2025-06-08T00:00:00.000Z',
      'food_requirements': 'Take with food',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('medications', {
      'name': 'Efavirenz/Emtricitabine/Tenofovir (Atroiza)',
      'alarms': '[{"time":"20:00","pillsPerDose":1,"notes":"Take at bedtime"}]',
      'current_stock': 12,
      'original_stock': 30,
      'collection_date': 'June 25, 2025',
      'days_until_collection': 9,
      'instructions': 'Take once daily at bedtime on empty stomach',
      'dosage': '1 tablet daily',
      'color': 'Orange',
      'shape': 'Oval',
      'is_temporary': 0,
      'category': 'daily',
      'pharmacy_info': 'Government Clinic',
      'last_refill_date': '2025-05-28T00:00:00.000Z',
      'food_requirements': 'Empty stomach preferred',
      'created_at': now,
      'updated_at': now,
    });

    // Insert sample temporary medication (Paracetamol for cold)
    await db.insert('medications', {
      'name': 'Paracetamol (for flu)',
      'alarms': '[{"time":"08:00","pillsPerDose":2,"notes":"As needed for fever"},{"time":"14:00","pillsPerDose":2,"notes":"As needed"},{"time":"20:00","pillsPerDose":2,"notes":"As needed"}]',
      'current_stock': 16,
      'original_stock': 20,
      'collection_date': '',
      'days_until_collection': 0,
      'instructions': 'Take as needed for pain/fever. Max 8 tablets per day',
      'dosage': '2 tablets up to 4 times daily',
      'color': 'White',
      'shape': 'Round',
      'is_temporary': 1,
      'category': 'as_needed',
      'temporary_end_date': '2025-06-25T00:00:00.000Z',
      'pharmacy_info': 'Dischem Pharmacy',
      'last_refill_date': '2025-06-15T00:00:00.000Z',
      'interactions': '["Warfarin","Alcohol"]',
      'food_requirements': 'Can take with or without food',
      'created_at': now,
      'updated_at': now,
    });

    // Insert default daily tasks
    String today = DateTime.now().toIso8601String().split('T')[0];
    
    await db.insert('daily_tasks', {
      'task': 'Take 2 Multivitamins (Morning)',
      'completed': 1,
      'medication_id': 1,
      'time': '08:00',
      'category': 'medication',
      'task_date': today,
      'pills_to_take': 2,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('daily_tasks', {
      'task': 'Take 1 Multivitamin (Evening)',
      'completed': 0,
      'medication_id': 1,
      'time': '20:00',
      'category': 'medication',
      'task_date': today,
      'pills_to_take': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('daily_tasks', {
      'task': 'Take Atroiza (Bedtime)',
      'completed': 0,
      'medication_id': 2,
      'time': '20:00',
      'category': 'medication',
      'task_date': today,
      'pills_to_take': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('daily_tasks', {
      'task': 'Log Daily Wellness Check',
      'completed': 1,
      'category': 'wellness',
      'task_date': today,
      'created_at': now,
      'updated_at': now,
    });

    // Insert sample medication dose (morning vitamins already taken)
    await db.insert('medication_doses', {
      'medication_id': 1,
      'time': '08:00',
      'pills_taken': 2,
      'pills_scheduled': 2,
      'date_taken': today,
      'was_on_time': 1,
      'notes': 'Took with breakfast as scheduled',
      'created_at': now,
    });

    // Insert stock change record (morning vitamins taken)
    await db.insert('stock_changes', {
      'medication_id': 1,
      'change_amount': -2,
      'change_type': 'taken',
      'reason': 'Morning dose taken',
      'previous_stock': 29,
      'new_stock': 27,
      'created_at': now,
    });

    // Insert default clinics
    await db.insert('clinics', {
      'name': 'Charlotte Maxeke Johannesburg Academic Hospital',
      'distance': '2.3 km',
      'services': '["HIV Care", "Social Worker", "Pharmacy"]',
      'rating': 4.2,
      'is_open': 1,
      'phone': '011 488 4911',
      'address': '7 York Road, Parktown, Johannesburg',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('clinics', {
      'name': 'Helen Joseph Hospital',
      'distance': '5.7 km',
      'services': '["HIV Care", "Counseling", "Social Worker"]',
      'rating': 4.0,
      'is_open': 1,
      'phone': '011 276 8000',
      'address': 'Perth Road, Westdene, Johannesburg',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('clinics', {
      'name': 'Rahima Moosa Mother & Child Hospital',
      'distance': '8.1 km',
      'services': '["HIV Care", "Pharmacy"]',
      'rating': 3.8,
      'is_open': 0,
      'phone': '011 276 8200',
      'address': 'Coronation Avenue, Coronationville, Johannesburg',
      'created_at': now,
      'updated_at': now,
    });

    // Insert default mobile clinics
    await db.insert('mobile_clinics', {
      'name': 'Community Outreach Mobile Unit',
      'location': 'Soweto - Freedom Square',
      'date': 'June 17, 2025',
      'time': '09:00-15:00',
      'services': '["HIV Testing", "ARV Pickup", "Counseling"]',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('mobile_clinics', {
      'name': 'Healthcare on Wheels',
      'location': 'Alexandra - 8th Avenue',
      'date': 'June 18, 2025',
      'time': '08:00-14:00',
      'services': '["HIV Care", "Social Worker", "Pharmacy"]',
      'created_at': now,
      'updated_at': now,
    });

    // Insert sample appointments using the separate method
    await _insertSampleAppointments(db);

    // Insert welcome chat message
    await db.insert('chat_messages', {
      'text': "Hello! I'm your SmartCare assistant. I can help you with medication questions, side effects, interactions, and general health advice. How can I assist you today?",
      'is_user': 0,
      'timestamp': DateTime.now().toIso8601String(),
      'created_at': now,
    });
  }

  // User operations
  Future<User?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Enhanced medication operations
  Future<List<Medication>> getMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medications');
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<List<Medication>> getActiveMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'is_temporary = 0 OR temporary_end_date > ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<List<Medication>> getTemporaryMedications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'is_temporary = 1',
    );
    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<List<Medication>> getLowStockMedications({int threshold = 7}) async {
    final medications = await getMedications();
    return medications.where((med) => med.daysRemaining <= threshold).toList();
  }

  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    return await db.insert('medications', medication.toMap()
      ..['created_at'] = DateTime.now().toIso8601String()
      ..['updated_at'] = DateTime.now().toIso8601String());
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // Stock management operations
  Future<bool> takeMedication(int medicationId, String time, int pillsTaken, {String? notes}) async {
    final db = await database;
    
    try {
      await db.transaction((txn) async {
        // Get current medication
        final medMaps = await txn.query('medications', where: 'id = ?', whereArgs: [medicationId]);
        if (medMaps.isEmpty) throw Exception('Medication not found');
        
        final medication = Medication.fromMap(medMaps.first);
        final newStock = medication.currentStock - pillsTaken;
        
        if (newStock < 0) throw Exception('Not enough pills remaining');
        
        // Update medication stock
        await txn.update(
          'medications',
          {
            'current_stock': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [medicationId],
        );
        
        // Record the dose taken
        await txn.insert('medication_doses', {
          'medication_id': medicationId,
          'time': time,
          'pills_taken': pillsTaken,
          'pills_scheduled': pillsTaken, // Assume taken as scheduled for now
          'date_taken': DateTime.now().toIso8601String().split('T')[0],
          'was_on_time': 1,
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        // Record stock change
        await txn.insert('stock_changes', {
          'medication_id': medicationId,
          'change_amount': -pillsTaken,
          'change_type': 'taken',
          'reason': 'Medication taken at $time',
          'previous_stock': medication.currentStock,
          'new_stock': newStock,
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      
      return true;
    } catch (e) {
      print('Error taking medication: $e');
      return false;
    }
  }

  Future<bool> addStock(int medicationId, int pillsAdded, String reason) async {
    final db = await database;
    
    try {
      await db.transaction((txn) async {
        // Get current medication
        final medMaps = await txn.query('medications', where: 'id = ?', whereArgs: [medicationId]);
        if (medMaps.isEmpty) throw Exception('Medication not found');
        
        final medication = Medication.fromMap(medMaps.first);
        final newStock = medication.currentStock + pillsAdded;
        
        // Update medication stock and refill date if it's a new bottle
        Map<String, dynamic> updateData = {
          'current_stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (reason.toLowerCase().contains('new bottle') || reason.toLowerCase().contains('refill')) {
          updateData['last_refill_date'] = DateTime.now().toIso8601String();
          updateData['original_stock'] = newStock; // Update original stock for new bottles
        }
        
        await txn.update(
          'medications',
          updateData,
          where: 'id = ?',
          whereArgs: [medicationId],
        );
        
        // Record stock change
        await txn.insert('stock_changes', {
          'medication_id': medicationId,
          'change_amount': pillsAdded,
          'change_type': 'added',
          'reason': reason,
          'previous_stock': medication.currentStock,
          'new_stock': newStock,
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      
      return true;
    } catch (e) {
      print('Error adding stock: $e');
      return false;
    }
  }

  // Daily tasks operations
  Future<List<DailyTask>> getDailyTasks([String? date]) async {
    final db = await database;
    String taskDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_tasks',
      where: 'task_date = ?',
      whereArgs: [taskDate],
    );
    return List.generate(maps.length, (i) => DailyTask.fromMap(maps[i]));
  }

  Future<int> insertDailyTask(DailyTask task) async {
    final db = await database;
    return await db.insert('daily_tasks', task.toMap()
      ..['created_at'] = DateTime.now().toIso8601String()
      ..['updated_at'] = DateTime.now().toIso8601String());
  }

  Future<int> updateDailyTask(DailyTask task) async {
    final db = await database;
    return await db.update(
      'daily_tasks',
      task.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> completeDailyTask(int id) async {
    final db = await database;
    return await db.update(
      'daily_tasks',
      {
        'completed': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Chat messages operations
  Future<List<ChatMessage>> getChatMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  Future<int> insertChatMessage(ChatMessage message) async {
    final db = await database;
    return await db.insert('chat_messages', message.toMap()
      ..['created_at'] = DateTime.now().toIso8601String());
  }

  Future<void> clearChatMessages() async {
    final db = await database;
    await db.delete('chat_messages');
    // Re-insert welcome message
    await insertChatMessage(ChatMessage(
      text: "Hello! I'm your SmartCare assistant. I can help you with medication questions, side effects, interactions, and general health advice. How can I assist you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // Clinics operations
  Future<List<Clinic>> getClinics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clinics');
    return List.generate(maps.length, (i) => Clinic.fromMap(maps[i]));
  }

  Future<int> insertClinic(Clinic clinic) async {
    final db = await database;
    return await db.insert('clinics', clinic.toMap()
      ..['created_at'] = DateTime.now().toIso8601String()
      ..['updated_at'] = DateTime.now().toIso8601String());
  }

  // Mobile clinics operations
  Future<List<MobileClinic>> getMobileClinics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('mobile_clinics');
    return List.generate(maps.length, (i) => MobileClinic.fromMap(maps[i]));
  }

  Future<int> insertMobileClinic(MobileClinic clinic) async {
    final db = await database;
    return await db.insert('mobile_clinics', clinic.toMap()
      ..['created_at'] = DateTime.now().toIso8601String()
      ..['updated_at'] = DateTime.now().toIso8601String());
  }

  // FIXED: Appointment Database Operations with table existence check
  Future<List<Appointment>> getAppointments() async {
    try {
      // ENSURE TABLE EXISTS FIRST
      await ensureAppointmentsTableExists();
      
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'appointments',
        orderBy: 'date_time ASC',
      );

      print('✅ Retrieved ${maps.length} appointments from database');
      return List.generate(maps.length, (i) {
        return Appointment.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error getting appointments: $e');
      return [];
    }
  }

  Future<int> insertAppointment(Appointment appointment) async {
    try {
      // ENSURE TABLE EXISTS FIRST
      await ensureAppointmentsTableExists();
      
      final db = await database;
      print('📝 Inserting appointment: ${appointment.title}');
      
      final result = await db.insert(
        'appointments',
        appointment.toMap()
          ..['created_at'] = DateTime.now().toIso8601String()
          ..['updated_at'] = DateTime.now().toIso8601String(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✅ Appointment inserted with ID: $result');
      return result;
    } catch (e) {
      print('❌ Error inserting appointment: $e');
      return 0;
    }
  }

  Future<int> updateAppointment(Appointment appointment) async {
    try {
      // ENSURE TABLE EXISTS FIRST
      await ensureAppointmentsTableExists();
      
      final db = await database;
      print('📝 Updating appointment: ${appointment.title}');
      
      final result = await db.update(
        'appointments',
        appointment.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
        where: 'id = ?',
        whereArgs: [appointment.id],
      );
      
      print('✅ Appointment updated, rows affected: $result');
      return result;
    } catch (e) {
      print('❌ Error updating appointment: $e');
      return 0;
    }
  }

  Future<int> deleteAppointment(int appointmentId) async {
    try {
      // ENSURE TABLE EXISTS FIRST
      await ensureAppointmentsTableExists();
      
      final db = await database;
      print('🗑️ Deleting appointment with ID: $appointmentId');
      
      final result = await db.delete(
        'appointments',
        where: 'id = ?',
        whereArgs: [appointmentId],
      );
      
      print('✅ Appointment deleted, rows affected: $result');
      return result;
    } catch (e) {
      print('❌ Error deleting appointment: $e');
      return 0;
    }
  }

  // Analytics operations
  Future<Map<String, dynamic>> getMedicationHistory(int medicationId, {int days = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T')[0];
    
    final doses = await db.query(
      'medication_doses',
      where: 'medication_id = ? AND date_taken >= ?',
      whereArgs: [medicationId, cutoffDate],
      orderBy: 'date_taken DESC',
    );
    
    final stockChanges = await db.query(
      'stock_changes',
      where: 'medication_id = ? AND created_at >= ?',
      whereArgs: [medicationId, cutoffDate],
      orderBy: 'created_at DESC',
    );
    
    return {
      'doses': doses.map((dose) => MedicationDose.fromMap(dose)).toList(),
      'stockChanges': stockChanges,
    };
  }

  // ADDED: Debugging and utility methods
  Future<List<String>> getAllTableNames() async {
    final db = await database;
    final List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    return tables.map((table) => table['name'] as String).toList();
  }

  Future<void> debugDatabaseInfo() async {
    try {
      final tables = await getAllTableNames();
      print('🔍 Database Debug Info:');
      print('📋 Available tables: $tables');
      
      if (tables.contains('appointments')) {
        final appointments = await getAppointments();
        print('📅 Total appointments: ${appointments.length}');
        for (var apt in appointments) {
          print('   - ${apt.title} on ${apt.formattedDateTime}');
        }
      } else {
        print('❌ Appointments table not found!');
      }
    } catch (e) {
      print('❌ Error debugging database: $e');
    }
  }

  Future<int> getCurrentDatabaseVersion() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('PRAGMA user_version');
    return result.first['user_version'] as int;
  }

  // Utility operations
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'smartcare.db');
    await databaseFactory.deleteDatabase(path);
  }
}