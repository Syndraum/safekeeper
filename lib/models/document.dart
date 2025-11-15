class Document {
  final String id;
  final String name;
  final String filePath;  // Path to the encrypted file
  final DateTime uploadDate;
  final String encryptedKey;  // RSA-encrypted AES key (base64)
  final String iv;  // Initialization vector (base64)

  Document({
    required this.id,
    required this.name,
    required this.filePath,
    required this.uploadDate,
    required this.encryptedKey,
    required this.iv,
  });

  // Serialize to JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'uploadDate': uploadDate.toIso8601String(),
    'encryptedKey': encryptedKey,
    'iv': iv,
  };

  // Deserialize from JSON
  factory Document.fromJson(Map<String, dynamic> json) => Document(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    uploadDate: DateTime.parse(json['uploadDate']),
    encryptedKey: json['encryptedKey'],
    iv: json['iv'],
  );
}
