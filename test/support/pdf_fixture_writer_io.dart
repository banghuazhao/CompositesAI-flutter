import 'dart:io';
import 'dart:typed_data';

Future<void> writePdfFixture(String name, Uint8List bytes) async {
  final directory = Directory('/private/tmp/compositesai-precision-pdf-qa');
  await directory.create(recursive: true);
  await File('${directory.path}/$name.pdf').writeAsBytes(bytes, flush: true);
}
