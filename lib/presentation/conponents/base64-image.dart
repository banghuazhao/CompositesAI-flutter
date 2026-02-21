import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:infrastructure/api_environment.dart';
import 'package:swiftcomp/app/injection_container.dart';

Widget Base64Image(String data) {
  final trimmed = data.trim();
  if (trimmed.isEmpty) {
    return const Icon(Icons.account_circle);
  }

  // Absolute URL
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.account_circle);
      },
    );
  }

  // Relative URL from backend (e.g. "/user.png")
  if (trimmed.startsWith('/')) {
    return FutureBuilder<String>(
      future: sl<APIEnvironment>().getBaseUrl(),
      builder: (context, snapshot) {
        final baseUrl = snapshot.data;
        if (baseUrl == null || baseUrl.isEmpty) {
          return const Icon(Icons.account_circle);
        }
        final baseUri = Uri.parse(baseUrl);
        // baseUrl is API base (often includes /api/v1). Static files typically live on origin.
        final origin = '${baseUri.scheme}://${baseUri.authority}';
        final fullUrl = '$origin$trimmed';
        return Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.account_circle);
          },
        );
      },
    );
  }

  // Base64 (optionally data-uri)
  final base64String = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
  try {
    final normalized = base64.normalize(base64String);
    final Uint8List bytes = base64Decode(normalized);
    return Image.memory(bytes, fit: BoxFit.cover);
  } catch (_) {
    // Unknown/invalid format: avoid crashing UI.
    return const Icon(Icons.account_circle);
  }
}
