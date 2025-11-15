import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../services/document_service.dart';
import '../services/encryption_service.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentService _documentService = DocumentService();
  final _encryptionService = EncryptionService();
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

  Future<void> _openDocument(int documentId, String encryptedPath, String name) async {
    try {
      // Get document metadata from database
      final doc = await _documentService.getDocument(documentId);
      if (doc == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document not found in database')),
          );
        }
        return;
      }

      // Get encrypted key and IV from database
      String encryptedKeyBase64 = doc['encrypted_key'];
      String ivBase64 = doc['iv'];

      // Convert from base64
      Uint8List encryptedKey = base64.decode(encryptedKeyBase64);
      Uint8List iv = base64.decode(ivBase64);

      // Read encrypted file
      File encryptedFile = File(encryptedPath);
      Uint8List encryptedData = await encryptedFile.readAsBytes();

      // Decrypt using hybrid decryption
      Uint8List decryptedBytes = await _encryptionService.decryptFile(
        encryptedData,
        encryptedKey,
        iv,
      );

      // Save the decrypted file temporarily for viewing
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/$name';
      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedBytes);

      // Navigate to a viewer screen (example for PDF)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFView(filePath: tempPath),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  onTap: () => _openDocument(doc['id'], doc['path'], doc['name']),
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