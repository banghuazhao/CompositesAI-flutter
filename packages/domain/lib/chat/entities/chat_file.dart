class ChatFile {
  final String type;
  final String id;
  final String name;
  final String url;
  final String collectionName;
  final String status;
  final int size;
  final Map<String, dynamic>? file;

  const ChatFile({
    this.type = 'file',
    required this.id,
    required this.name,
    required this.url,
    this.collectionName = '',
    this.status = 'uploaded',
    this.size = 0,
    this.file,
  });

  factory ChatFile.fromJson(Map<String, dynamic> json) {
    final fileRaw = json['file'];
    return ChatFile(
      type: json['type']?.toString() ?? 'file',
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['filename']?.toString() ??
          json['id']?.toString() ??
          'file',
      url: json['url']?.toString() ?? '',
      collectionName: json['collection_name']?.toString() ??
          json['collectionName']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'uploaded',
      size: _parseInt(json['size']),
      file: fileRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(fileRaw)
          : null,
    );
  }

  factory ChatFile.fromUploadResponse({
    required Map<String, dynamic> json,
    required String url,
  }) {
    final meta = json['meta'];
    final collectionName = meta is Map<String, dynamic>
        ? meta['collection_name']?.toString() ?? ''
        : json['collection_name']?.toString() ?? '';
    final name = meta is Map<String, dynamic>
        ? meta['name']?.toString() ?? json['filename']?.toString()
        : json['filename']?.toString();

    return ChatFile(
      id: json['id']?.toString() ?? '',
      name: name ?? 'file',
      url: url,
      collectionName: collectionName,
      size: meta is Map<String, dynamic> ? _parseInt(meta['size']) : 0,
      file: Map<String, dynamic>.from(json),
    );
  }

  factory ChatFile.fromKnowledgeFile(
    Map<String, dynamic> json,
    Map<String, dynamic> knowledge,
  ) {
    final meta = json['meta'];
    final metaMap =
        meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
    final name = metaMap['name']?.toString() ??
        json['name']?.toString() ??
        json['filename']?.toString() ??
        json['id']?.toString() ??
        'file';
    final knowledgeId = knowledge['id']?.toString() ?? '';

    return ChatFile(
      type: 'file',
      id: json['id']?.toString() ?? '',
      name: name,
      url: json['url']?.toString() ?? '',
      collectionName: json['collection_name']?.toString() ??
          metaMap['collection_name']?.toString() ??
          knowledgeId,
      status: json['status']?.toString() ?? 'uploaded',
      size: metaMap.isNotEmpty
          ? _parseInt(metaMap['size'])
          : _parseInt(json['size']),
      file: {
        ...Map<String, dynamic>.from(json),
        'collection': {
          'id': knowledgeId,
          'name': knowledge['name']?.toString() ?? '',
          'description': knowledge['description']?.toString() ?? '',
        },
      },
    );
  }

  bool get isKnowledgeCollection => type == 'collection';

  bool get isKnowledgeFile => collectionName.isNotEmpty && type == 'file';

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
        'url': url,
        'collection_name': collectionName,
        'status': status,
        'size': size,
        if (file != null) 'file': file,
      };

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
