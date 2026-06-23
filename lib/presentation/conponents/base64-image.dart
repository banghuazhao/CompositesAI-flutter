import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:swiftcomp/app/injection_container.dart';

class Base64Image extends StatefulWidget {
  final String data;

  const Base64Image(this.data, {Key? key}) : super(key: key);

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  String? _resolvedUrl;
  Uint8List? _bytes;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolve(widget.data);
  }

  @override
  void didUpdateWidget(Base64Image old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      setState(() {
        _resolvedUrl = null;
        _bytes = null;
        _resolved = false;
      });
      _resolve(widget.data);
    }
  }

  Future<void> _resolve(String data) async {
    final trimmed = data.trim();
    if (trimmed.isEmpty) {
      if (mounted) setState(() => _resolved = true);
      return;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (mounted) setState(() { _resolvedUrl = trimmed; _resolved = true; });
      return;
    }

    if (trimmed.startsWith('/')) {
      final baseUrl = await sl<APIEnvironment>().getBaseUrl();
      if (!mounted) return;
      final uri = Uri.parse(baseUrl);
      final origin = '${uri.scheme}://${uri.authority}';
      setState(() { _resolvedUrl = '$origin$trimmed'; _resolved = true; });
      return;
    }

    // Base64 (with optional data-uri prefix)
    try {
      final b64 = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
      final bytes = base64Decode(base64.normalize(b64));
      if (mounted) setState(() { _bytes = bytes; _resolved = true; });
    } catch (_) {
      if (mounted) setState(() => _resolved = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(_bytes!, fit: BoxFit.cover);
    }
    if (_resolvedUrl != null) {
      return CachedNetworkImage(
        imageUrl: _resolvedUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) =>
            const Icon(Icons.account_circle, color: Colors.grey),
      );
    }
    if (!_resolved) return const SizedBox.shrink();
    return const Icon(Icons.account_circle, color: Colors.grey);
  }
}
