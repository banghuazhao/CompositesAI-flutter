class LayupSequence {
  static const int maxLayers = 1000000;
  // Preserve whitespace around numeric repeats, while rejecting bare suffix
  // whitespace that the downstream calculator parser cannot consume.
  static final RegExp _bracketedSequence = RegExp(
      r'^\s*\[([^\[\]]+)\](?:(\s*\+?\d+\s*)?s(\s*\+?\d+\s*)?|(\s*\+?\d+\s*))?$');

  List<double>? layups;
  String stringValue = '';
  bool _exceedsLayerLimit = false;

  bool get exceedsLayerLimit => _exceedsLayerLimit;

  /// Parses `[xx/xx]msn`: repeat m times, mirror if s is present, then repeat n
  /// times. Unbracketed angle lists are also accepted.
  set value(String value) {
    stringValue = value;
    layups = null;
    _exceedsLayerLimit = false;
    final text = value;
    if (text.trim().isEmpty) return;

    String baseLayup = text;
    int repeatBefore = 1;
    int repeatAfter = 1;
    bool symmetric = false;

    if (text.contains('[') || text.contains(']')) {
      final match = _bracketedSequence.firstMatch(text);
      if (match == null || match.end != text.length) return;
      baseLayup = match.group(1)!;
      symmetric = text.substring(text.indexOf(']') + 1).contains('s');
      final before = _repeatCount(match.group(2) ?? match.group(4));
      final after = _repeatCount(match.group(3));
      if (before == null || after == null) return;
      repeatBefore = before;
      repeatAfter = after;
    }

    // Check the base count before splitting or expanding the input.
    int baseCount = 1;
    for (var i = 0; i < baseLayup.length; i++) {
      if (baseLayup.codeUnitAt(i) == 47) {
        baseCount++;
        if (baseCount > maxLayers) {
          _exceedsLayerLimit = true;
          return;
        }
      }
    }

    int totalCount = baseCount;
    for (final factor in [repeatBefore, if (symmetric) 2, repeatAfter]) {
      // Division avoids overflowing when input contains very large repeats.
      if (factor > maxLayers ~/ totalCount) {
        _exceedsLayerLimit = true;
        return;
      }
      totalCount *= factor;
    }

    final baseAngles = <double>[];
    for (final angleText in baseLayup.split('/')) {
      final angle = double.tryParse(angleText.trim());
      if (angle == null || !angle.isFinite) return;
      baseAngles.add(angle);
    }

    final halfLength = baseCount * repeatBefore;
    final blockLength = symmetric ? halfLength * 2 : halfLength;
    layups = List<double>.generate(totalCount, (index) {
      final blockIndex = index % blockLength;
      // The mirrored half runs backwards through the repeated base sequence.
      final angleIndex = symmetric && blockIndex >= halfLength
          ? blockLength - 1 - blockIndex
          : blockIndex;
      return baseAngles[angleIndex % baseCount];
    });
  }

  int? _repeatCount(String? text) {
    if (text == null) return 1;
    final count = int.tryParse(text);
    if (count == null || count > maxLayers) {
      _exceedsLayerLimit = true;
      return null;
    }
    return count > 0 ? count : null;
  }

  bool isValid() =>
      layups != null && layups!.isNotEmpty && layups!.length <= maxLayers;
}
