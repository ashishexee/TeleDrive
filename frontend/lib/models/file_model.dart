class FileItem {
  final String id;
  final String name;
  final int size;
  final DateTime uploadDate;
  final bool isDeleted;
  final DateTime? deletedAt;

  FileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadDate,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'],
      name: json['name'],
      size: json['size'],
      uploadDate: DateTime.parse(json['uploadDate']),
      isDeleted: json['isDeleted'] ?? false,
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'uploadDate': uploadDate.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
