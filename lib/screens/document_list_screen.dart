import 'dart:io';
import 'dart:typed_data';  // Added for Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';  // For PDF viewing (add to pubspec.yaml)
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/document_service.dart';  // Import your DocumentService

class DocumentListScreen extends StatefulWidget {
  @override
  _DocumentListScreenState createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentService _documentService = DocumentService();
  final _storage = FlutterSecureStorage();
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final documents = await _documentService.getDocuments();
    setState(() {
      _documents = documents;
    });
  }

  Future<void> _deleteDocument(int id) async {
    await _documentService.deleteDocument(id);
    _loadDocuments();  // Reload the list after deletion
  }

  Future<void> _openDocument(String encryptedPath, String name) async {
    // Retrieve the encryption key
    String? keyString = await _storage.read(key: 'encryption_key');
    if (keyString == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Encryption key not found')),
      );
      return;
    }
    encrypt.Key key = encrypt.Key.fromUtf8(keyString);
    encrypt.IV iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Read and decrypt the file
    File encryptedFile = File(encryptedPath);
    List<int> encryptedBytes = await encryptedFile.readAsBytes();
    Uint8List uint8EncryptedBytes = Uint8List.fromList(encryptedBytes);  // Convert to Uint8List to fix the type error
    encrypt.Encrypted encrypted = encrypt.Encrypted(uint8EncryptedBytes);  // Now uses Uint8List
    List<int> decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);

    // Save the decrypted file temporarily for viewing
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/$name';
    File tempFile = File(tempPath);
    await tempFile.writeAsBytes(decryptedBytes);

    // Navigate to a viewer screen (example for PDF)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFView(filePath: tempPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document List')),
      body: _documents.isEmpty
          ? Center(child: Text('No documents uploaded yet.'))
          : ListView.builder(
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return ListTile(
                  title: Text(doc['name']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(doc['id']),
                  ),
                  onTap: () => _openDocument(doc['path'], doc['name']),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteDocument(id);
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}