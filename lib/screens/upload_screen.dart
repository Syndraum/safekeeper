import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _storage = FlutterSecureStorage();

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      // Générer une clé de chiffrement (stockée en sécurité)
      String keyString = await _storage.read(key: 'encryption_key') ?? _generateKey();
      await _storage.write(key: 'encryption_key', value: keyString);
      encrypt.Key key = encrypt.Key.fromUtf8(keyString);
      encrypt.IV iv = encrypt.IV.fromLength(16);

      // Chiffrer le fichier
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      List<int> fileBytes = await file.readAsBytes();
      encrypt.Encrypted encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      // Sauvegarder le fichier chiffré localement
      Directory appDir = await getApplicationDocumentsDirectory();
      String encryptedPath = '${appDir.path}/${result.files.single.name}.enc';
      File encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encrypted.bytes);

      // Ici, tu peux ajouter à une liste ou DB (voir étape 5)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Document uploadé et sécurisé !')));
    }
  }

  String _generateKey() {
    // Génère une clé aléatoire (en prod, utilise une vraie génération sécurisée)
    return encrypt.Key.fromSecureRandom(32).base64;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Uploader un document')),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickAndUploadFile,
          child: Text('Sélectionner et uploader'),
        ),
      ),
    );
  }
}