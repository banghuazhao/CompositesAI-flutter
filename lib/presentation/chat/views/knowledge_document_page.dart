import 'dart:typed_data';

import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/knowledge_document.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class KnowledgeDocumentPage extends StatefulWidget {
  const KnowledgeDocumentPage({
    super.key,
    required this.file,
    required this.useCase,
  });

  final ChatFile file;
  final ChatUseCase useCase;

  @override
  State<KnowledgeDocumentPage> createState() => _KnowledgeDocumentPageState();
}

class _KnowledgeDocumentPageState extends State<KnowledgeDocumentPage> {
  static const int _previewLimit = 80000;
  static const int _maxCachedImages = 8;
  late Future<KnowledgeDocument> _documentFuture;
  Future<String>? _versionFuture;
  final Map<String, Future<Uint8List>> _images = {};
  int? _selectedVersion;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _documentFuture = widget.useCase.fetchKnowledgeDocument(widget.file.id);
  }

  void _reload() {
    setState(() {
      _selectedVersion = null;
      _versionFuture = null;
      _images.clear();
      _documentFuture = widget.useCase.fetchKnowledgeDocument(widget.file.id);
    });
  }

  void _showHistory(KnowledgeDocument document) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Document history')),
            ListTile(
              title: const Text('Current version'),
              trailing: _selectedVersion == null
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedVersion = null;
                  _versionFuture = null;
                });
              },
            ),
            for (final entry in document.versions.reversed)
              ListTile(
                title: Text('Version ${entry.version}'),
                subtitle: entry.note.isNotEmpty
                    ? Text(entry.note)
                    : Text(entry.kind.isEmpty ? 'Archived text' : entry.kind),
                trailing: _selectedVersion == entry.version
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedVersion = entry.version;
                    _versionFuture = widget.useCase
                        .fetchKnowledgeDocumentVersion(
                            widget.file.id, entry.version);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Refresh document',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<KnowledgeDocument>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return _LoadError(onRetry: _reload);
            }
            return const Center(child: CircularProgressIndicator());
          }
          final document = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedVersion == null
                            ? 'Current text'
                            : 'Version $_selectedVersion · archived',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showHistory(document),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('History'),
                    ),
                    IconButton(
                      tooltip:
                          _preview ? 'Show Markdown text' : 'Preview Markdown',
                      icon: Icon(_preview
                          ? Icons.code_rounded
                          : Icons.preview_rounded),
                      onPressed: () => setState(() => _preview = !_preview),
                    ),
                  ],
                ),
              ),
              if (_selectedVersion == null) _DocumentStatus(document: document),
              Expanded(
                child: _selectedVersion == null
                    ? _buildContent(document.content)
                    : FutureBuilder<String>(
                        future: _versionFuture,
                        builder: (context, versionSnapshot) {
                          if (!versionSnapshot.hasData) {
                            if (versionSnapshot.hasError) {
                              return _LoadError(onRetry: () {
                                final version = _selectedVersion;
                                if (version == null) return;
                                setState(() {
                                  _versionFuture = widget.useCase
                                      .fetchKnowledgeDocumentVersion(
                                          widget.file.id, version);
                                });
                              });
                            }
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return _buildContent(versionSnapshot.data!);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(String content) {
    if (content.trim().isEmpty) {
      return const Center(child: Text('No extracted text available.'));
    }
    if (!_preview) {
      final chunks = _textChunks(content);
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chunks.length,
        itemBuilder: (context, index) => SelectableText(
          chunks[index],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      );
    }

    final previewText = content.length > _previewLimit
        ? content.substring(0, _previewLimit)
        : content;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (content.length > _previewLimit)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Preview shows the first 80,000 characters. Switch to text to read the full document.',
            ),
          ),
        GptMarkdown(
          previewText,
          imageBuilder: _buildImage,
          onLinkTap: (_, __) {},
        ),
      ],
    );
  }

  Widget _buildImage(
    BuildContext context,
    String url,
    double? width,
    double? height,
  ) {
    final name = _imageName(url);
    if (name == null) {
      return const Text('Image unavailable');
    }
    final imageFuture = _images.putIfAbsent(name, () {
      if (_images.length >= _maxCachedImages) {
        _images.remove(_images.keys.first);
      }
      return widget.useCase.fetchKnowledgeDocumentImage(widget.file.id, name);
    });
    return FutureBuilder<Uint8List>(
      future: imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Image unavailable');
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }
        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          cacheWidth: 1600,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text('Image unavailable'),
        );
      },
    );
  }

  static String? _imageName(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.pathSegments.length != 2 ||
        uri.pathSegments.first != 'images') {
      return null;
    }
    final name = uri.pathSegments.last;
    if (name == '.' ||
        name == '..' ||
        !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) {
      return null;
    }
    return name;
  }

  static List<String> _textChunks(String text) {
    const chunkSize = 12000;
    final chunks = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = start + chunkSize;
      if (end >= text.length) {
        end = text.length;
      } else {
        final lineEnd = text.lastIndexOf('\n', end);
        if (lineEnd > start + chunkSize ~/ 2) end = lineEnd + 1;
      }
      chunks.add(text.substring(start, end));
      start = end;
    }
    return chunks;
  }
}

class _DocumentStatus extends StatelessWidget {
  const _DocumentStatus({required this.document});

  final KnowledgeDocument document;

  @override
  Widget build(BuildContext context) {
    final status = document.actionStatus;
    final freshness = document.freshness;
    String? message;
    if (status == 'queued' || status == 'running') {
      message = 'Document processing is $status. Refresh to see the result.';
    } else if (status == 'failed') {
      message = document.actionError.isEmpty
          ? 'The last document action failed.'
          : 'The last document action failed: ${document.actionError}';
    } else if (freshness == 'stale') {
      message =
          'Search may still use older text until this document is re-embedded.';
    } else if (freshness == 'unknown') {
      message = 'The indexed version of this document is unknown.';
    }
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(message),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load this document.'),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
