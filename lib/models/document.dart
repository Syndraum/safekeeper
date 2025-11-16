import 'dart:convert'; // For base64 encoding/decoding
import 'dart:typed_data'; // For Uint8List

class Document {
  final String id;
  final String name;
  final String filePath;
  final DateTime uploadDate;
  final String encryptedKey;
  final String iv;
  final Uint8List? hmac; // Declare the hmac field as nullable Uint8List
  final String? mimeType; // MIME type of the file
  final String? fileType; // File type category (pdf, image, text, etc.)

  Document({
    required this.id,
    required this.name,
    required this.filePath,
    required this.uploadDate,
    required this.encryptedKey,
    required this.iv,
    this.hmac, // Optional field
    this.mimeType, // Optional field
    this.fileType, // Optional field
  });

  // Serialize to JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'uploadDate': uploadDate.toIso8601String(),
    'encryptedKey': encryptedKey,
    'iv': iv,
    if (hmac != null) 'hmac': base64.encode(hmac!),
    if (mimeType != null) 'mimeType': mimeType,
    if (fileType != null) 'fileType': fileType,
  };

  // Deserialize from JSON
  factory Document.fromJson(Map<String, dynamic> json) => Document(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    uploadDate: DateTime.parse(json['uploadDate']),
    encryptedKey: json['encryptedKey'],
    iv: json['iv'],
    hmac: json['hmac'] != null ? base64.decode(json['hmac']) : null,
    mimeType: json['mimeType'],
    fileType: json['fileType'],
  );
}
