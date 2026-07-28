import 'package:domain/chat/entities/chat_source.dart';
import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:flutter/foundation.dart';

@immutable
class ChatCitation {
  const ChatCitation({
    required this.number,
    this.uri,
    this.label,
    this.context,
    this.bibliographicText,
    this.excerpts = const [],
  });

  final int number;
  final Uri? uri;
  final String? label;
  final String? context;
  final String? bibliographicText;
  final List<String> excerpts;

  String get host {
    final value = uri?.host ?? '';
    return value.startsWith('www.') ? value.substring(4) : value;
  }

  String get displayTitle {
    final trimmedLabel = label?.trim() ?? '';
    if (trimmedLabel.isNotEmpty) return trimmedLabel;
    if (host.isNotEmpty) return host;
    return 'Source $number';
  }

  bool get canOpen => uri != null;

  String get copyText {
    final parts = <String>[
      if (bibliographicText?.trim().isNotEmpty == true) bibliographicText!.trim(),
      if (uri != null &&
          !(bibliographicText?.contains(uri.toString()) ?? false))
        uri.toString(),
    ];
    if (parts.isNotEmpty) return parts.join('\n');
    return displayTitle;
  }
}

class ChatCitationParser {
  const ChatCitationParser._();

  static final RegExp _markdownCitationLink = RegExp(
    r'\[(\d+)\]\((https?://[^\s)]+)\)',
    caseSensitive: false,
  );
  static final RegExp _openAiCitation = RegExp(
    r'【(\d+)(?::\d+)?†([^】]+)】',
  );
  static final RegExp _prefixedCitation = RegExp(
    r'【([^】]+)】\[(\d+)\]',
  );
  static final RegExp _numberedTag = RegExp(r'\[(\d+)\]');
  static final RegExp _toolDetails = RegExp(
    r'<details[^>]*type="tool_calls"[\s\S]*?<\/details>',
  );

  static List<ChatCitation> parse({
    required String markdown,
    List<ToolStatus> statusHistory = const [],
    List<ChatSource> sources = const [],
  }) {
    final builders = <int, _CitationBuilder>{};

    _markdownCitationLink.allMatches(markdown).forEach((match) {
      final number = int.tryParse(match.group(1) ?? '');
      final uri = _safeHttpUri(match.group(2));
      if (number == null) return;
      builders.putIfAbsent(number, () => _CitationBuilder(number)).uri ??= uri;
    });

    _openAiCitation.allMatches(markdown).forEach((match) {
      final number = int.tryParse(match.group(1) ?? '');
      if (number == null) return;
      final builder =
          builders.putIfAbsent(number, () => _CitationBuilder(number));
      builder.label ??= _cleanLabel(match.group(2));
    });

    _prefixedCitation.allMatches(markdown).forEach((match) {
      final number = int.tryParse(match.group(2) ?? '');
      if (number == null) return;
      final source = match.group(1)?.trim();
      final builder =
          builders.putIfAbsent(number, () => _CitationBuilder(number));
      builder.uri ??= _safeHttpUri(source);
      if (builder.uri == null) builder.label ??= _cleanLabel(source);
    });

    _numberedTag.allMatches(markdown).forEach((match) {
      final number = int.tryParse(match.group(1) ?? '');
      if (number != null) {
        builders.putIfAbsent(number, () => _CitationBuilder(number));
      }
    });

    _applyMessageSources(builders, sources);

    final sourceUris = _sourceUris(statusHistory);
    final context = _sourceContext(statusHistory, sources);
    if (builders.isEmpty) {
      for (var index = 0; index < sourceUris.length; index++) {
        builders[index + 1] = _CitationBuilder(index + 1)
          ..uri = sourceUris[index];
      }
      if (builders.isEmpty) {
        for (final source in sources) {
          final number = source.citationId ?? builders.length + 1;
          builders.putIfAbsent(number, () => _CitationBuilder(number))
            ..uri ??= source.uri
            ..label ??= _cleanLabel(source.name)
            ..bibliographicText ??= source.bibliographicText
            ..excerpts = source.excerpts.isNotEmpty
                ? source.excerpts
                : (source.excerpt == null ? const [] : [source.excerpt!]);
        }
      }
    } else {
      final assignedUris = builders.values
          .map((builder) => builder.uri)
          .whereType<Uri>()
          .map((uri) => uri.toString())
          .toSet();
      final unassignedUris = sourceUris
          .where((uri) => !assignedUris.contains(uri.toString()))
          .iterator;

      for (final builder in builders.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number))) {
        if (builder.uri == null && unassignedUris.moveNext()) {
          builder.uri = unassignedUris.current;
        }
      }
    }

    return (builders.values.toList()
          ..sort((a, b) => a.number.compareTo(b.number)))
        .map(
          (builder) => ChatCitation(
            number: builder.number,
            uri: builder.uri,
            label: builder.label,
            context: builder.context ?? context,
            bibliographicText: builder.bibliographicText,
            excerpts: List<String>.unmodifiable(builder.excerpts),
          ),
        )
        .toList(growable: false);
  }

  static String normalizeMarkdown(String markdown) {
    return markdown
        .replaceAll('\r\n', '\n')
        .replaceAll(_toolDetails, '')
        .replaceAllMapped(
          _markdownCitationLink,
          (match) => '[${match.group(1)}]',
        )
        .replaceAllMapped(
          _openAiCitation,
          (match) => '[${match.group(1)}]',
        )
        .replaceAllMapped(
          _prefixedCitation,
          (match) => '[${match.group(2)}]',
        )
        .trimRight();
  }

  static void _applyMessageSources(
    Map<int, _CitationBuilder> builders,
    List<ChatSource> sources,
  ) {
    if (sources.isEmpty) return;

    final orderedWithoutId = <ChatSource>[];

    for (final source in sources) {
      final citationId = source.citationId;
      if (citationId == null) {
        orderedWithoutId.add(source);
        continue;
      }
      final builder =
          builders.putIfAbsent(citationId, () => _CitationBuilder(citationId));
      _fillFromSource(builder, source);
    }

    // Positional fallback for markers that still lack document details.
    final unresolved = builders.values
        .where(_needsSourceDetails)
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    if (unresolved.isEmpty) return;

    final leftoverSources = List<ChatSource>.from(orderedWithoutId);

    for (final builder in unresolved) {
      ChatSource? source;
      if (builder.number >= 1 && builder.number <= sources.length) {
        final candidate = sources[builder.number - 1];
        final candidateId = candidate.citationId;
        if (candidateId == null || candidateId == builder.number) {
          source = candidate;
        }
      }
      if (source == null && leftoverSources.isNotEmpty) {
        source = leftoverSources.removeAt(0);
      }
      if (source == null) continue;
      _fillFromSource(builder, source);
    }
  }

  static bool _needsSourceDetails(_CitationBuilder builder) {
    return builder.label == null &&
        builder.bibliographicText == null &&
        builder.excerpts.isEmpty;
  }

  static void _fillFromSource(_CitationBuilder builder, ChatSource source) {
    builder.uri ??= source.uri;
    builder.label ??= _cleanLabel(source.name) ??
        _titleFromBibliographic(source.bibliographicText);
    builder.bibliographicText ??= source.bibliographicText ??
        _fallbackBibliographic(source);
    if (builder.excerpts.isEmpty) {
      builder.excerpts = source.excerpts.isNotEmpty
          ? source.excerpts
          : (source.excerpt == null ? const [] : [source.excerpt!]);
    }
    builder.context ??= _excerptContext(source.excerpt);
  }

  static String? _titleFromBibliographic(String? bibliographic) {
    final text = bibliographic?.trim() ?? '';
    if (text.isEmpty) return null;
    final firstSentence = text.split(RegExp(r'(?<=\.)\s+')).first.trim();
    if (firstSentence.isEmpty || _safeHttpUri(firstSentence) != null) {
      return null;
    }
    return firstSentence.replaceAll(RegExp(r'\.$'), '');
  }

  static String? _fallbackBibliographic(ChatSource source) {
    final name = _cleanLabel(source.name);
    if (name != null && source.uri != null) {
      return '$name\n${source.uri}';
    }
    return name ?? source.uri?.toString();
  }

  static List<Uri> _sourceUris(List<ToolStatus> statusHistory) {
    final seen = <String>{};
    final uris = <Uri>[];
    for (final status in statusHistory) {
      for (final value in status.urls) {
        final uri = _safeHttpUri(value);
        if (uri != null && seen.add(uri.toString())) uris.add(uri);
      }
    }
    return uris;
  }

  static String? _sourceContext(
    List<ToolStatus> statusHistory,
    List<ChatSource> sources,
  ) {
    for (final status in statusHistory.reversed) {
      final query = status.query.trim();
      if (query.isNotEmpty) return 'Referenced while researching “$query”.';
      final description = status.description.trim();
      if (description.isNotEmpty) return description;
    }
    for (final source in sources) {
      final excerpt = _excerptContext(source.excerpt);
      if (excerpt != null) return excerpt;
    }
    return null;
  }

  static String? _excerptContext(String? excerpt) {
    final text = excerpt?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static Uri? _safeHttpUri(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  static String? _cleanLabel(String? value) {
    final label = value?.trim() ?? '';
    if (label.isEmpty || _safeHttpUri(label) != null) return null;
    return label;
  }
}

class _CitationBuilder {
  _CitationBuilder(this.number);

  final int number;
  Uri? uri;
  String? label;
  String? context;
  String? bibliographicText;
  List<String> excerpts = const [];
}
