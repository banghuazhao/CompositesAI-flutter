import 'package:flutter/material.dart';

class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration period;

  const BlinkingText({
    Key? key,
    required this.text,
    this.style,
    this.period = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  _BlinkingTextState createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Set up the AnimationController to repeat the animation back and forth.
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat(reverse: true);

    // Tween from 0 (invisible) to 1 (fully visible).
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose of the controller!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Text(widget.text, style: widget.style),
    );
  }
}
