import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DocumentService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'documents.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version for schema update
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE documents('
          'id INTEGER PRIMARY KEY, '
          'name TEXT, '
          'path TEXT, '
          'encrypted_key TEXT, '
          'iv TEXT, '
          'upload_date TEXT'
          ')',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration from version 1 to 2
          await db.execute('ALTER TABLE documents ADD COLUMN encrypted_key TEXT');
          await db.execute('ALTER TABLE documents ADD COLUMN iv TEXT');
          await db.execute('ALTER TABLE documents ADD COLUMN upload_date TEXT');
        }
      },
    );
  }

  Future<void> addDocument(
    String name,
    String path,
    String encryptedKey,
    String iv,
  ) async {
    final db = await database;
    await db.insert('documents', {
      'name': name,
      'path': path,
      'encrypted_key': encryptedKey,
      'iv': iv,
      'upload_date': DateTime.now().toIso8601String(),
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

  Future<void> deleteDocument(int id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllDocuments() async {
    final db = await database;
    await db.delete('documents');
  }
}
