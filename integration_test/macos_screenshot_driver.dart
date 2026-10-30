import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:integration_test/integration_test_driver.dart';

// Host-side only. The app sends base64-encoded images through reportData and
// never needs filesystem access outside its sandbox.
Future<void> main() => integrationDriver(
      timeout: const Duration(minutes: 8),
      responseDataCallback: _writeScreenshots,
    );

Future<void> _writeScreenshots(Map<String, dynamic>? report) async {
  final screenshots = report?['screenshots'];
  if (report?['schemaVersion'] != 1 ||
      screenshots is! List ||
      screenshots.length != 9) {
    throw StateError('The Mac screenshot report was incomplete.');
  }
  const languages = {'en', 'zh-Hans', 'zh-Hant'};
  const names = {'01-guest', '02-tools', '03-plate-results'};
  final files = <String, Uint8List>{};
  for (final shot in screenshots) {
    if (shot is! Map ||
        !languages.contains(shot['language']) ||
        !names.contains(shot['name']) ||
        shot['width'] != 1280 ||
        shot['height'] != 800 ||
        shot['pngBase64'] is! String) {
      throw StateError('The Mac screenshot report contained invalid metadata.');
    }
    final encoded = shot['pngBase64'] as String;
    if (encoded.length > 16 * 1024 * 1024) {
      throw StateError('A Mac screenshot payload was unexpectedly large.');
    }
    final png = base64Decode(encoded);
    _validatePng(png);
    final path = '${shot['language']}/${shot['name']}.png';
    if (files.containsKey(path)) {
      throw StateError('The Mac screenshot report contained duplicate images.');
    }
    files[path] = png;
  }
  // Validate the complete report before replacing any generated host files.
  final directory = Directory('build/macos/store-screenshots');
  for (final entry in files.entries) {
    final file = File('${directory.path}/${entry.key}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value, flush: true);
  }
  stdout.writeln('Wrote ${files.length} opaque 1280x800 Mac screenshots to '
      '${directory.path}.');
}

void _validatePng(Uint8List png) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (png.length < 45) throw StateError('A screenshot PNG was incomplete.');
  for (var index = 0; index < signature.length; index++) {
    if (png[index] != signature[index]) {
      throw StateError('A screenshot payload was not PNG.');
    }
  }
  final data = ByteData.sublistView(png);
  if (data.getUint32(8) != 13 ||
      ascii.decode(png.sublist(12, 16)) != 'IHDR' ||
      data.getUint32(16) != 1280 ||
      data.getUint32(20) != 800 ||
      png[24] != 8 ||
      png[25] != 2 ||
      png[26] != 0 ||
      png[27] != 0 ||
      png[28] != 0) {
    throw StateError('A screenshot was not an opaque 1280x800 RGB PNG.');
  }
  final compressed = BytesBuilder(copy: false);
  var offset = 8;
  var ended = false;
  while (offset + 12 <= png.length) {
    final length = data.getUint32(offset);
    final end = offset + 12 + length;
    if (end > png.length) throw StateError('A PNG chunk was truncated.');
    final type = ascii.decode(png.sublist(offset + 4, offset + 8));
    final body = png.sublist(offset + 4, offset + 8 + length);
    if (_crc32(body) != data.getUint32(offset + 8 + length)) {
      throw StateError('A screenshot PNG checksum did not match.');
    }
    if (type == 'IDAT') compressed.add(png.sublist(offset + 8, end - 4));
    if (type == 'IEND') {
      ended = length == 0 && end == png.length;
      break;
    }
    offset = end;
  }
  if (!ended) throw StateError('A screenshot PNG had no final image marker.');
  final pixels = ZLibDecoder().convert(compressed.takeBytes());
  const stride = 1280 * 3 + 1;
  if (pixels.length != stride * 800) {
    throw StateError('A screenshot PNG had an invalid pixel buffer.');
  }
  for (var row = 0; row < 800; row++) {
    if (pixels[row * stride] != 0) {
      throw StateError('A screenshot used an unexpected PNG row encoding.');
    }
  }
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return crc ^ 0xffffffff;
}
