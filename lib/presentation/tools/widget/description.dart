import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

class DescriptionItem extends StatelessWidget {
  final Widget content;

  const DescriptionItem({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                S.of(context).Description,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: content,
            )
          ],
        ));
  }
}
