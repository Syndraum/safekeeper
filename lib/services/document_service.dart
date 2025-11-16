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

  Future<Database> _initDB() async {
    // databaseFactory = databaseFactoryFfi;
    String path = join(await getDatabasesPath(), 'documents.db');
    return await openDatabase(
      path,
      version: 4, // Incremented version for MIME type and file type support
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
          'file_type TEXT'
          ')',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration from version 1 to 2
          await db.execute(
            'ALTER TABLE documents ADD COLUMN encrypted_key TEXT',
          );
          await db.execute('ALTER TABLE documents ADD COLUMN iv TEXT');
          await db.execute('ALTER TABLE documents ADD COLUMN upload_date TEXT');
        }
        if (oldVersion < 3) {
          // Migration from version 2 to 3 - Add HMAC column
          await db.execute('ALTER TABLE documents ADD COLUMN hmac TEXT');
        }
        if (oldVersion < 4) {
          // Migration from version 3 to 4 - Add MIME type and file type columns
          await db.execute('ALTER TABLE documents ADD COLUMN mime_type TEXT');
          await db.execute('ALTER TABLE documents ADD COLUMN file_type TEXT');
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
