class Document {
  final String id;
  final String name;
  final String filePath;  // Path to the encrypted file
  final DateTime uploadDate;

  Document({required this.id, required this.name, required this.filePath, required this.uploadDate});

  // Optional: Add methods to serialize to/from JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'uploadDate': uploadDate.toIso8601String(),
  };

  factory Document.fromJson(Map<String, dynamic> json) => Document(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    uploadDate: DateTime.parse(json['uploadDate']),
  );
}