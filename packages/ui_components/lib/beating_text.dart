import 'package:flutter/material.dart';

class BeatingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration period;
  final double minScale;
  final double maxScale;

  const BeatingText({
    Key? key,
    required this.text,
    this.style,
    this.period = const Duration(milliseconds: 800),
    this.minScale = 1.0,
    this.maxScale = 1.2,
  }) : super(key: key);

  @override
  _BeatingTextState createState() => _BeatingTextState();
}

class _BeatingTextState extends State<BeatingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Create an AnimationController that repeats the animation back and forth.
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat(reverse: true);

    // Tween for scaling from minScale to maxScale with an easing curve.
    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when the widget is removed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Text(widget.text, style: widget.style),
    );
  }
}
