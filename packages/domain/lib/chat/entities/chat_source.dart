/// A citation/RAG source attached to an assistant message.
///
/// Mirrors the CompositesAI/Open WebUI source payload shape:
/// `{ citation_id, source: { name, url, ... }, metadata: [{ source, name, ... }], document: [...] }`.
class ChatSource {
  const ChatSource({
    this.citationId,
    this.name,
    this.url,
    this.excerpt,
  });

  final int? citationId;
  final String? name;
  final String? url;
  final String? excerpt;

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

    final citationId = _asInt(json['citation_id']) ??
        _asInt(metadata?['citation_id']) ??
        _asInt(metadata?['source_id']);

    var name = _nonEmpty(sourceObj?['name']) ??
        _nonEmpty(metadata?['name']) ??
        _nonEmpty(metadata?['title']);

    var url = _httpUrl(sourceObj?['url']) ??
        _httpUrl(metadata?['url']) ??
        _httpUrl(metadata?['source']) ??
        _httpUrl(sourceObj?['id']) ??
        _httpUrl(sourceObj?['name']);

    if (url == null && sourceObj?['urls'] is List) {
      for (final entry in sourceObj!['urls'] as List) {
        final candidate = _httpUrl(entry);
        if (candidate != null) {
          url = candidate;
          break;
        }
      }
    }

    name ??= _nonEmpty(url);

    final documents = json['document'];
    String? excerpt;
    if (documents is List) {
      for (final doc in documents) {
        final text = doc?.toString().trim() ?? '';
        if (text.isNotEmpty) {
          excerpt = text.length > 280 ? '${text.substring(0, 280)}…' : text;
          break;
        }
      }
    }

    return ChatSource(
      citationId: citationId,
      name: name,
      url: url,
      excerpt: excerpt,
    );
  }

  Map<String, dynamic> toJson() => {
        if (citationId != null) 'citation_id': citationId,
        if (name != null || url != null)
          'source': {
            if (name != null) 'name': name,
            if (url != null) 'url': url,
          },
        if (excerpt != null) 'document': [excerpt],
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
              source.uri != null)
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

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
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
