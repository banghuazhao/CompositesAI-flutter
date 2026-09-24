import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

/// Fonts used for exported PDFs.
///
/// The bundled DejaVu fonts cover Latin, Greek and the math symbols that show
/// up in composites answers (σ, ε, ν, ≤, ×, …). The built-in PDF fonts do not.
/// When the text contains CJK characters, Noto Sans SC is downloaded once per
/// app session as a fallback; if that fails the export still succeeds, only
/// without those glyphs.
class PdfFonts {
  PdfFonts._(this.base, this.bold, this.mono, this.fallback);

  final pw.Font base;
  final pw.Font bold;
  final pw.Font mono;
  final List<pw.Font> fallback;

  static Future<pw.Font>? _base;
  static Future<pw.Font>? _bold;
  static Future<pw.Font>? _mono;
  static Future<pw.Font?>? _cjk;

  static final RegExp _cjkPattern =
      RegExp(r'[　-〿぀-ヿ㐀-䶿一-鿿＀-￯]');

  static bool containsCjk(String text) => _cjkPattern.hasMatch(text);

  static Future<PdfFonts> load({String sampleText = ''}) async {
    final base = await (_base ??= _asset('assets/fonts/DejaVuSans.ttf'));
    final bold = await (_bold ??= _asset('assets/fonts/DejaVuSans-Bold.ttf'));
    final mono = await (_mono ??= _asset('assets/fonts/DejaVuSansMono.ttf'));
    final fallback = <pw.Font>[];
    if (containsCjk(sampleText)) {
      final cjk = await (_cjk ??= _downloadCjkFont());
      if (cjk != null) {
        fallback.add(cjk);
      } else {
        _cjk = null; // Try again on the next export.
      }
    }
    return PdfFonts._(base, bold, mono, fallback);
  }

  pw.ThemeData get theme => pw.ThemeData.withFont(
        base: base,
        bold: bold,
        italic: base,
        boldItalic: bold,
        fontFallback: fallback,
      );

  static Future<pw.Font> _asset(String path) async {
    final data = await rootBundle.load(path);
    return pw.Font.ttf(data);
  }

  static Future<pw.Font?> _downloadCjkFont() async {
    try {
      // Without a browser user agent Google Fonts serves plain TrueType files,
      // which is the format the pdf package can embed.
      final css = await http
          .get(Uri.parse(
              'https://fonts.googleapis.com/css2?family=Noto+Sans+SC'))
          .timeout(const Duration(seconds: 10));
      if (css.statusCode != 200) return null;
      final match = RegExp(r'url\((https://[^)]+\.ttf)\)').firstMatch(css.body);
      if (match == null) return null;
      final font = await http
          .get(Uri.parse(match.group(1)!))
          .timeout(const Duration(seconds: 30));
      if (font.statusCode != 200) return null;
      return pw.Font.ttf(ByteData.sublistView(font.bodyBytes));
    } catch (error) {
      if (kDebugMode) debugPrint('CJK font download failed: $error');
      return null;
    }
  }
}
