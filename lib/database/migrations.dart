import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static Future<void> migrateTo(Database db, int oldVersion, int newVersion) async {
    // Future database migrations can be added here
    // Example:
    // if (oldVersion < 2) {
    //   await _migrateToVersion2(db);
    // }
    // if (oldVersion < 3) {
    //   await _migrateToVersion3(db);
    // }
  }

  // Example migration function
  static Future<void> _migrateToVersion2(Database db) async {
    // Add new columns or tables for version 2
    // await db.execute('ALTER TABLE users ADD COLUMN new_column TEXT');
  }

  // Utility function to check if a table exists
  static Future<bool> tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // Utility function to check if a column exists in a table
  static Future<bool> columnExists(Database db, String tableName, String columnName) async {
    final result = await db.rawQuery("PRAGMA table_info($tableName)");
    for (var row in result) {
      if (row['name'] == columnName) {
        return true;
      }
    }
    return false;
  }

  // Backup and restore functions
  static Future<Map<String, List<Map<String, dynamic>>>> backupAllData(Database db) async {
    final backup = <String, List<Map<String, dynamic>>>{};
    
    final tables = ['users', 'medications', 'daily_tasks', 'chat_messages', 'clinics', 'mobile_clinics'];
    
    for (String table in tables) {
      try {
        backup[table] = await db.query(table);
      } catch (e) {
        print('Error backing up table $table: $e');
        backup[table] = [];
      }
    }
    
    return backup;
  }

  static Future<void> restoreData(Database db, Map<String, List<Map<String, dynamic>>> backup) async {
    for (String table in backup.keys) {
      try {
        // Clear existing data
        await db.delete(table);
        
        // Restore backup data
        for (Map<String, dynamic> row in backup[table]!) {
          await db.insert(table, row);
        }
      } catch (e) {
        print('Error restoring table $table: $e');
      }
    }
  }
}
