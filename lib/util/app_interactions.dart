import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
}

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.enabled = true,
    this.haptic = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool enabled;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    final scale = _enabled && _pressed ? 0.96 : 1.0;

    return AnimatedScale(
      scale: reduceMotion ? 1 : scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onHighlightChanged: _setPressed,
          onTap: !_enabled
              ? null
              : () {
                  if (widget.haptic) AppHaptics.light();
                  widget.onTap?.call();
                },
          child: AnimatedOpacity(
            opacity: _enabled && _pressed ? 0.82 : 1,
            duration: const Duration(milliseconds: 120),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
