import 'package:flutter/cupertino.dart';

class Tool {
  final AssetImage image;
  final String title;
  final Widget descriptionWidget;
  final Function(BuildContext) action;

  Tool(this.image, this.title, this.descriptionWidget, this.action);
}
