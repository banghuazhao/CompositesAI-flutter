import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Shares generated files (Markdown, CSV, PDF) through the platform share
/// sheet. On the web this falls back to a download when sharing files is not
/// supported by the browser.
class FileShare {
  const FileShare._();

  static Future<void> shareText(
    BuildContext context, {
    required String text,
    required String fileName,
    required String mimeType,
    String? subject,
  }) {
    return shareBytes(
      context,
      bytes: Uint8List.fromList(utf8.encode(text)),
      fileName: fileName,
      mimeType: mimeType,
      subject: subject,
    );
  }

  static Future<void> shareBytes(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    final origin = _shareOrigin(context);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
        fileNameOverrides: [fileName],
        subject: subject,
        sharePositionOrigin: origin,
        downloadFallbackEnabled: true,
      ),
    );
  }

  /// Turns free text (a chat title, a calculator name) into a safe file name.
  static String safeFileName(String name, String extension) {
    final cleaned = name
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final base = cleaned.isEmpty
        ? 'CompositesAI'
        : cleaned.substring(0, cleaned.length.clamp(0, 80));
    return '$base.$extension';
  }

  /// iPad requires an anchor rectangle for the share popover.
  static Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.maybeSizeOf(context);
    if (size == null) return null;
    return Rect.fromLTWH(0, 0, size.width, size.height / 2);
  }
}
