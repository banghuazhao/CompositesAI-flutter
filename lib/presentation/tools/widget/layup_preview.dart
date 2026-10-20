import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../model/layer_thickness.dart';
import '../model/unit_system.dart';
import 'number_field.dart';

/// A bounded, read-only summary of the already parsed stacking sequence.
class LayupPreview extends StatelessWidget {
  const LayupPreview({super.key, required this.layups, this.layerThickness});

  static const int maxVisibleAngles = 12;

  final List<double>? layups;
  final LayerThickness? layerThickness;

  @override
  Widget build(BuildContext context) {
    final angles = layups;
    if (angles == null || angles.isEmpty) return const SizedBox.shrink();
    final units = context.watch<UnitSettings?>()?.units ?? Units.si;
    final strings = S.maybeOf(context);

    Widget content() {
      final count = strings?.Calculator_ply_count(angles.length) ??
          '${angles.length} ${angles.length == 1 ? 'ply' : 'plies'}';
      final shown = angles
          .take(maxVisibleAngles)
          .map((angle) => '${formatInputNumber(angle)}°')
          .join(' / ');
      final remaining = angles.length - maxVisibleAngles;
      final more = remaining > 0
          ? ' · ${strings?.Calculator_more_plies(remaining) ?? '+$remaining more'}'
          : '';
      final thickness = layerThickness;
      final total = thickness != null && thickness.isValid()
          ? thickness.value! * angles.length
          : null;

      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count, key: const ValueKey('layup-ply-count')),
            if (total != null && total.isFinite && total > 0)
              Text(
                strings?.Calculator_total_thickness(
                        formatInputNumber(total), units.length) ??
                    'Total thickness: ${formatInputNumber(total)} ${units.length}',
                key: const ValueKey('layup-total-thickness'),
              ),
            Text(
              '${strings?.Calculator_expanded_angles(shown) ?? 'Angles: $shown'}$more',
              key: const ValueKey('layup-expanded-angles'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    final thickness = layerThickness;
    return thickness == null
        ? content()
        : ListenableBuilder(
            listenable: thickness, builder: (_, __) => content());
  }
}
