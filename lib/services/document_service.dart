import 'package:sqflite/sqflite.dart';
import 'dart:io';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DocumentService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // static void init() {
  //   databaseFactory = databaseFactoryFfi;
  // }

  /// Helper function to check if a column exists in a table
  Future<bool> _columnExists(Database db, String tableName, String columnName) async {
    try {
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      return result.any((column) => column['name'] == columnName);
    } catch (e) {
      print('Error checking column existence: $e');
      return false;
    }
  }

  /// Helper function to safely add a column if it doesn't exist
  Future<void> _addColumnIfNotExists(
    Database db,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    final exists = await _columnExists(db, tableName, columnName);
    if (!exists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
      print('Added column $columnName to $tableName');
    } else {
      print('Column $columnName already exists in $tableName, skipping');
    }
  }

  Future<Database> _initDB() async {
    // databaseFactory = databaseFactoryFfi;
    String path = join(await getDatabasesPath(), 'documents.db');
    return await openDatabase(
      path,
      version: 5, // Incremented version for cloud backup support
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE documents('
          'id INTEGER PRIMARY KEY, '
          'name TEXT, '
          'path TEXT, '
          'encrypted_key TEXT, '
          'iv TEXT, '
          'hmac TEXT, '
          'upload_date TEXT, '
          'mime_type TEXT, '
          'file_type TEXT, '
          'google_drive_backup_status TEXT, '
          'google_drive_file_id TEXT, '
          'dropbox_backup_status TEXT, '
          'dropbox_file_path TEXT, '
          'last_backup_date TEXT'
          ')',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration from version 1 to 2
          await _addColumnIfNotExists(db, 'documents', 'encrypted_key', 'TEXT');
          await _addColumnIfNotExists(db, 'documents', 'iv', 'TEXT');
          await _addColumnIfNotExists(db, 'documents', 'upload_date', 'TEXT');
        }
        if (oldVersion < 3) {
          // Migration from version 2 to 3 - Add HMAC column
          await _addColumnIfNotExists(db, 'documents', 'hmac', 'TEXT');
        }
        if (oldVersion < 4) {
          // Migration from version 3 to 4 - Add MIME type and file type columns
          await _addColumnIfNotExists(db, 'documents', 'mime_type', 'TEXT');
          await _addColumnIfNotExists(db, 'documents', 'file_type', 'TEXT');
        }
        if (oldVersion < 5) {
          // Migration from version 4 to 5 - Add cloud backup columns
          await _addColumnIfNotExists(db, 'documents', 'google_drive_backup_status', 'TEXT');
          await _addColumnIfNotExists(db, 'documents', 'google_drive_file_id', 'TEXT');
          await _addColumnIfNotExists(db, 'documents', 'dropbox_backup_status', 'TEXT');
          await _addColumnIfNotExists(db, 'documents', 'dropbox_file_path', 'TEXT');
          await _addColumnIfNotExists(db, 'documents', 'last_backup_date', 'TEXT');
        }
      },
    );
  }

  Future<void> addDocument(
    String name,
    String path,
    String encryptedKey,
    String iv, {
    String? hmac,
    String? mimeType,
    String? fileType,
  }) async {
    final db = await database;
    await db.insert('documents', {
      'name': name,
      'path': path,
      'encrypted_key': encryptedKey,
      'iv': iv,
      if (hmac != null) 'hmac': hmac,
      'upload_date': DateTime.now().toIso8601String(),
      if (mimeType != null) 'mime_type': mimeType,
      if (fileType != null) 'file_type': fileType,
    });
  }

  Future<List<Map<String, dynamic>>> getDocuments() async {
    final db = await database;
    return await db.query('documents');
  }

  Future<Map<String, dynamic>?> getDocument(int id) async {
    final db = await database;
    final results = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateDocumentName(int id, String newName) async {
    final db = await database;
    await db.update(
      'documents',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDocument(int id) async {
    final db = await database;

    // Get the document to retrieve the file path
    final doc = await getDocument(id);

    if (doc != null) {
      // Delete the physical encrypted file
      final filePath = doc['path'] as String?;
      if (filePath != null && filePath.isNotEmpty) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            print('Deleted encrypted file: $filePath');
          } else {
            print('File not found (already deleted?): $filePath');
          }
        } catch (e) {
          print('Error deleting file $filePath: $e');
          // Continue with database deletion even if file deletion fails
        }
      }
    }

    // Delete the database entry
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllDocuments() async {
    final db = await database;
    await db.delete('documents');
  }
}
