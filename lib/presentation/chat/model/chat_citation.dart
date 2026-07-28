import 'package:domain/chat/entities/chat_stream_event.dart';
import 'package:flutter/foundation.dart';

@immutable
class ChatCitation {
  const ChatCitation({
    required this.number,
    this.uri,
    this.label,
    this.context,
  });

  final int number;
  final Uri? uri;
  final String? label;
  final String? context;

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

    final sourceUris = _sourceUris(statusHistory);
    final context = _sourceContext(statusHistory);
    if (builders.isEmpty) {
      for (var index = 0; index < sourceUris.length; index++) {
        builders[index + 1] = _CitationBuilder(index + 1)
          ..uri = sourceUris[index];
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
            context: context,
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

  static String? _sourceContext(List<ToolStatus> statusHistory) {
    for (final status in statusHistory.reversed) {
      final query = status.query.trim();
      if (query.isNotEmpty) return 'Referenced while researching “$query”.';
      final description = status.description.trim();
      if (description.isNotEmpty) return description;
    }
    return null;
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
}
