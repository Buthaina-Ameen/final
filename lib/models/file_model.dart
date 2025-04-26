class FileModel {
  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final String? cloudPath;
  bool isModified;

  FileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
    this.cloudPath,
    this.isModified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'size': size,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'cloudPath': cloudPath,
      'isModified': isModified,
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      size: map['size'],
      lastModified: DateTime.fromMillisecondsSinceEpoch(map['lastModified']),
      cloudPath: map['cloudPath'],
      isModified: map['isModified'] ?? false,
    );
  }
}
