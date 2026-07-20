import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'
    as staggered;

class StaggeredTile {
  const StaggeredTile.fit(this.crossAxisCellCount);

  final int crossAxisCellCount;
}

class StaggeredGridView {
  const StaggeredGridView._();

  static Widget countBuilder({
    Key? key,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    required int crossAxisCount,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required StaggeredTile Function(int index) staggeredTileBuilder,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
  }) {
    final grid = staggered.StaggeredGrid.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      children: List<Widget>.generate(itemCount, (index) {
        final tile = staggeredTileBuilder(index);
        final crossAxisCellCount = math.max(
          1,
          math.min(tile.crossAxisCellCount, crossAxisCount),
        );

        return staggered.StaggeredGridTile.fit(
          crossAxisCellCount: crossAxisCellCount,
          child: Builder(
            builder: (context) => itemBuilder(context, index),
          ),
        );
      }),
    );

    final content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: grid,
    );

    if (shrinkWrap || physics is NeverScrollableScrollPhysics) {
      return KeyedSubtree(
        key: key,
        child: content,
      );
    }

    return SingleChildScrollView(
      key: key,
      physics: physics,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: content,
    );
  }
}
