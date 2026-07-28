import 'dart:convert';

/// A citation/RAG source attached to an assistant message.
///
/// Mirrors the CompositesAI/Open WebUI source payload shape:
/// `{ citation_id, source: { name, url, ... }, metadata: [{ source, name, bibliographic, ... }], document: [...] }`.
class ChatSource {
  const ChatSource({
    this.citationId,
    this.name,
    this.url,
    this.excerpt,
    this.excerpts = const [],
    this.bibliographicText,
  });

  final int? citationId;
  final String? name;
  final String? url;
  final String? excerpt;
  final List<String> excerpts;
  final String? bibliographicText;

  Uri? get uri {
    final value = url?.trim() ?? '';
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  factory ChatSource.fromJson(Map<String, dynamic> json) {
    final metadata = _firstMetadata(json['metadata']);
    final sourceObj =
        json['source'] is Map ? Map<String, dynamic>.from(json['source']) : null;
    final bibliographic = _bibliographicMap(metadata, sourceObj);

    final citationId = _asInt(json['citation_id']) ??
        _asInt(metadata?['citation_id']) ??
        _asInt(metadata?['source_id']);

    var name = _decodeName(
      _nonEmpty(sourceObj?['name']) ??
          _nonEmpty(metadata?['name']) ??
          _nonEmpty(metadata?['title']) ??
          _nonEmpty(bibliographic?['title']) ??
          _nonEmpty(metadata?['file_name']) ??
          _nonEmpty(metadata?['filename']) ??
          _nonEmpty(sourceObj?['file_name']),
    );
    if (_isWeakSourceLabel(name)) name = null;

    var url = _httpUrl(sourceObj?['url']) ??
        _httpUrl(metadata?['url']) ??
        _httpUrl(metadata?['source']) ??
        _httpUrl(sourceObj?['id']) ??
        _formatDoi(bibliographic?['doi'] ?? metadata?['doi']);

    if (url == null && sourceObj?['urls'] is List) {
      for (final entry in sourceObj!['urls'] as List) {
        final candidate = _httpUrl(entry);
        if (candidate != null) {
          url = candidate;
          break;
        }
      }
    }

    final excerpts = <String>[];
    final documents = json['document'];
    if (documents is List) {
      for (final doc in documents) {
        final text = doc?.toString().trim() ?? '';
        if (text.isEmpty) continue;
        excerpts.add(text.length > 1200 ? '${text.substring(0, 1200)}…' : text);
      }
    }

    final bibliographicText = _buildBibliographicText(
      bibliographic: bibliographic,
      metadata: metadata,
      fallbackName: name,
      url: url,
    );

    return ChatSource(
      citationId: citationId,
      name: name,
      url: url,
      excerpt: excerpts.isEmpty ? null : excerpts.first,
      excerpts: List<String>.unmodifiable(excerpts),
      bibliographicText: bibliographicText,
    );
  }

  Map<String, dynamic> toJson() => {
        if (citationId != null) 'citation_id': citationId,
        'source': {
          if (name != null) 'name': name,
          if (url != null) 'url': url,
        },
        if (excerpts.isNotEmpty)
          'document': excerpts
        else if (excerpt != null)
          'document': [excerpt],
        'metadata': [
          {
            if (citationId != null) 'citation_id': citationId,
            if (name != null) 'name': name,
            if (url != null) 'source': url,
            if (bibliographicText != null)
              'bibliographic_text': bibliographicText,
          },
        ],
      };

  static List<ChatSource> listFromPayload(Object? payload) {
    if (payload == null) return const [];
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((raw) => ChatSource.fromJson(Map<String, dynamic>.from(raw)))
          .where((source) =>
              source.citationId != null ||
              (source.name?.isNotEmpty ?? false) ||
              source.uri != null ||
              (source.bibliographicText?.isNotEmpty ?? false) ||
              source.excerpts.isNotEmpty)
          .toList(growable: false);
    }
    if (payload is Map) {
      return listFromPayload([payload]);
    }
    return const [];
  }

  /// Merge [incoming] into [existing], preferring entries that already have a URL
  /// or excerpt when keys collide.
  static List<ChatSource> merge(
    List<ChatSource> existing,
    List<ChatSource> incoming,
  ) {
    if (incoming.isEmpty) return List<ChatSource>.from(existing);
    if (existing.isEmpty) return List<ChatSource>.from(incoming);

    final byKey = <String, ChatSource>{};
    var fallbackIndex = 0;

    void add(ChatSource source) {
      final key = source.citationId != null
          ? 'id:${source.citationId}'
          : source.uri != null
              ? 'url:${source.uri}'
              : source.name != null
                  ? 'name:${source.name}'
                  : 'idx:${fallbackIndex++}';
      final current = byKey[key];
      if (current == null) {
        byKey[key] = source;
        return;
      }
      byKey[key] = ChatSource(
        citationId: current.citationId ?? source.citationId,
        name: (current.name?.isNotEmpty == true) ? current.name : source.name,
        url: current.uri != null ? current.url : source.url,
        excerpt: (current.excerpt?.isNotEmpty == true)
            ? current.excerpt
            : source.excerpt,
        excerpts: current.excerpts.isNotEmpty ? current.excerpts : source.excerpts,
        bibliographicText: (current.bibliographicText?.isNotEmpty == true)
            ? current.bibliographicText
            : source.bibliographicText,
      );
    }

    existing.forEach(add);
    incoming.forEach(add);
    return byKey.values.toList(growable: false);
  }

  static Map<String, dynamic>? _firstMetadata(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    final first = raw.first;
    if (first is Map) return Map<String, dynamic>.from(first);
    return null;
  }

  static Map<String, dynamic>? _bibliographicMap(
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? sourceObj,
  ) {
    final candidates = [
      metadata?['bibliographic'],
      metadata?['meta'] is Map
          ? (metadata!['meta'] as Map)['bibliographic']
          : null,
      sourceObj?['bibliographic'],
      metadata?['file_table_metadata'],
    ];
    for (final candidate in candidates) {
      final parsed = _asMap(candidate);
      if (parsed != null) return parsed;
    }
    return metadata;
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty || (!text.startsWith('{') && !text.startsWith('['))) {
        return null;
      }
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String? _buildBibliographicText({
    required Map<String, dynamic>? bibliographic,
    required Map<String, dynamic>? metadata,
    required String? fallbackName,
    required String? url,
  }) {
    final stored = _nonEmpty(metadata?['bibliographic_text']);
    if (stored != null && !_isWeakSourceLabel(stored)) return stored;

    final author = _nonEmpty(bibliographic?['author_full_name']) ??
        _nonEmpty(bibliographic?['authors']) ??
        _nonEmpty(metadata?['author_full_name']) ??
        _nonEmpty(metadata?['author']);
    final title = _nonEmpty(bibliographic?['title']) ??
        _nonEmpty(metadata?['title']) ??
        _nonEmpty(metadata?['file_table_metadata'] is Map
            ? (metadata!['file_table_metadata'] as Map)['title']
            : null);
    final journal = _nonEmpty(bibliographic?['journal']) ??
        _nonEmpty(bibliographic?['container_title']) ??
        _nonEmpty(metadata?['journal']);
    final publisher = _nonEmpty(bibliographic?['publisher']) ??
        _nonEmpty(metadata?['publisher']);
    final year = _nonEmpty(bibliographic?['publication_year']) ??
        _nonEmpty(bibliographic?['year']) ??
        _nonEmpty(metadata?['publication_year']);
    final place = _nonEmpty(bibliographic?['publication_place']) ??
        _nonEmpty(metadata?['publication_place']);
    final doi = _formatDoi(bibliographic?['doi'] ?? metadata?['doi']);

    final parts = <String>[];
    void appendSentence(String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return;
      parts.add(RegExp(r'''[.!?]["']?$''').hasMatch(text) ? text : '$text.');
    }

    if (author != null) appendSentence(author);
    if (title != null) appendSentence(title);

    final publicationBits = <String>[
      if (journal != null) journal,
      if (place != null) place,
      if (publisher != null) publisher,
      if (year != null) year,
    ];
    if (publicationBits.isNotEmpty) {
      appendSentence(publicationBits.join(', '));
    }

    if (doi != null) {
      appendSentence(doi);
    } else if (url != null &&
        (author != null || title != null || publicationBits.isNotEmpty)) {
      appendSentence(url);
    }

    if (parts.isNotEmpty) return parts.join(' ');

    if (fallbackName != null &&
        !_isWeakSourceLabel(fallbackName) &&
        url != null &&
        fallbackName != url) {
      return '$fallbackName\n$url';
    }
    if (fallbackName != null && !_isWeakSourceLabel(fallbackName)) {
      return fallbackName;
    }
    return url;
  }

  static String? _formatDoi(Object? value) {
    final raw = _nonEmpty(value);
    if (raw == null) return null;
    var doi = raw;
    if (doi.toLowerCase().startsWith('doi:')) {
      doi = doi.substring(4).trim();
    }
    if (doi.startsWith('http://') || doi.startsWith('https://')) return doi;
    return 'https://doi.org/$doi';
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String? _decodeName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    try {
      return Uri.decodeComponent(text);
    } catch (_) {
      return text;
    }
  }

  static bool _isWeakSourceLabel(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return true;
    return RegExp(r'^Source\s*\[?\d+\]?$', caseSensitive: false).hasMatch(text);
  }

  static String? _httpUrl(Object? value) {
    final text = _nonEmpty(value);
    if (text == null) return null;
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri.toString();
  }
}
