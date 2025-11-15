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
    return await openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE documents(id INTEGER PRIMARY KEY, name TEXT, path TEXT)',
      );
    });
  }

  Future<void> addDocument(String name, String path) async {
    final db = await database;
    await db.insert('documents', {'name': name, 'path': path});
  }

  Future<List<Map<String, dynamic>>> getDocuments() async {
    final db = await database;
    return await db.query('documents');
  }

  Future<void> deleteDocument(int id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }
}