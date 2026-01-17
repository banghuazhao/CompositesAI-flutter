import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

Widget Base64Image(String dataUri) {
  // Remove data URI prefix if present
  final base64String = dataUri.split(',').last;

  Uint8List bytes = base64Decode(base64String);

  return Image.memory(
    bytes,
    fit: BoxFit.cover,
  );
}
