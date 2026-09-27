class KnowledgeDocumentVersion {
  const KnowledgeDocumentVersion({
    required this.version,
    this.kind = '',
    this.note = '',
  });

  final int version;
  final String kind;
  final String note;

  factory KnowledgeDocumentVersion.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['version'];
    return KnowledgeDocumentVersion(
      version: rawVersion is int
          ? rawVersion
          : int.tryParse(rawVersion?.toString() ?? '') ?? -1,
      kind: json['kind']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }
}

class KnowledgeDocument {
  const KnowledgeDocument({
    required this.content,
    required this.freshness,
    required this.versions,
    this.actionStatus = '',
    this.actionError = '',
  });

  final String content;
  final String freshness;
  final List<KnowledgeDocumentVersion> versions;
  final String actionStatus;
  final String actionError;

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    final index = json['versions'];
    final rawVersions = index is Map ? index['versions'] : null;
    final action = json['action_status'];
    return KnowledgeDocument(
      content: json['content']?.toString() ?? '',
      freshness: json['freshness']?.toString() ?? 'unknown',
      versions: rawVersions is List
          ? rawVersions
              .whereType<Map<String, dynamic>>()
              .map(KnowledgeDocumentVersion.fromJson)
              .where((entry) => entry.version >= 0)
              .toList()
          : const [],
      actionStatus: action is Map ? action['status']?.toString() ?? '' : '',
      actionError: action is Map ? action['error']?.toString() ?? '' : '',
    );
  }
}
