import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';

import '../../../util/NumberPrecisionHelper.dart';
import '../../../util/result_precision.dart';
import '../model/material_library.dart';
import '../model/unit_system.dart';

/// Previews a library record without changing inputs or saved materials.
/// Only an explicit Apply returns true; dismissal returns false or null.
Future<bool?> showMaterialDetails(
    BuildContext context, LibraryMaterial material) async {
  final units = context.read<UnitSettings?>();
  final precision = context.read<NumberPrecisionHelper?>();
  var answered = false;
  try {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        void finish(bool apply) {
          if (answered || !dialogContext.mounted) return;
          // A dismissed route can stay mounted during its closing animation.
          if (ModalRoute.of(dialogContext)?.isCurrent != true) return;
          answered = true;
          Navigator.of(dialogContext).pop(apply);
        }

        Widget dialog = _MaterialDetailsDialog(
          material: material,
          onApply: () => finish(true),
          onCancel: () => finish(false),
        );
        // A caller may provide settings below the Navigator. Forward those
        // existing notifiers without taking ownership of their lifecycle.
        if (precision != null) {
          dialog =
              ChangeNotifierProvider.value(value: precision, child: dialog);
        }
        if (units != null) {
          dialog = ChangeNotifierProvider.value(value: units, child: dialog);
        }
        return dialog;
      },
    );
  } finally {
    answered = true;
  }
}

class _MaterialDetailsDialog extends StatelessWidget {
  const _MaterialDetailsDialog({
    required this.material,
    required this.onApply,
    required this.onCancel,
  });

  final LibraryMaterial material;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings?>()?.units ?? Units.si;
    final precision = ResultPrecision.normalize(
        context.watch<NumberPrecisionHelper?>()?.precision ??
            ResultPrecision.defaultValue);
    final strings = S.maybeOf(context);
    final missing = strings?.Calculator_material_not_provided ?? 'Not provided';
    final matrix = material.kind == MaterialKind.matrix;

    String value(double? number, [String unit = '']) {
      if (number == null || !number.isFinite) return missing;
      final formatted =
          number == 0 ? '0' : number.toStringAsExponential(precision);
      return unit.isEmpty ? formatted : '$formatted $unit';
    }

    double? convert(double? number, double Function(double) conversion) =>
        number == null ? null : conversion(number);

    Widget property(String id, String label, double? number,
        [String unit = '']) {
      return _DetailValueRow(
        key: ValueKey('material-details-$id'),
        label: label,
        value: value(number, unit),
      );
    }

    final kind = switch (material.kind) {
      MaterialKind.lamina =>
        strings?.Calculator_material_kind_lamina ?? 'Unidirectional lamina',
      MaterialKind.fiber => strings?.Calculator_material_kind_fiber ?? 'Fiber',
      MaterialKind.matrix =>
        strings?.Calculator_material_kind_matrix ?? 'Matrix',
    };
    return AlertDialog(
      key: const Key('material-details-dialog'),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(strings?.Calculator_material_details ?? 'Material details'),
      content: SizedBox(
        width: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(material.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(units.summary),
            _DetailValueRow(
              label: strings?.Calculator_material_type ?? 'Material type',
              value: kind,
            ),
            _DetailValueRow(
              key: const Key('material-details-source'),
              label: strings?.Calculator_material_source ?? 'Source',
              value: material.source.trim().isEmpty ? missing : material.source,
            ),
            _note(
                context,
                strings?.Calculator_material_missing_note ??
                    'Missing elastic values keep the current inputs. Missing '
                        'thermal or strength groups also keep the current inputs.'),
            _heading(
                context,
                strings?.Calculator_material_elastic_properties ??
                    'Elastic properties'),
            property('e1', matrix ? 'E' : 'E1',
                units.modulusFromGPa(material.e1), units.modulus),
            property('e2', 'E2', convert(material.e2, units.modulusFromGPa),
                units.modulus),
            property('g12', 'G12', convert(material.g12, units.modulusFromGPa),
                units.modulus),
            property('nu12', matrix ? 'ν' : 'ν12', material.nu12),
            property('nu23', 'ν23', material.nu23),
            _heading(
                context,
                strings?.Calculator_material_thermal_properties ??
                    'Thermal expansion'),
            property('alpha11', matrix ? 'α' : 'α11',
                convert(material.alpha11, units.cteFromPerC), units.cte),
            property('alpha22', 'α22',
                convert(material.alpha22, units.cteFromPerC), units.cte),
            _note(
                context,
                strings?.Calculator_material_thermal_note ??
                    'Thermal values need α11 (α for isotropic materials). For '
                        'laminae and fibers, missing α22 uses α11 and shear CTE '
                        'is set to zero.'),
            _heading(context,
                strings?.Calculator_material_strengths ?? 'Lamina strengths'),
            property('xt', 'Xt', convert(material.xt, units.stressFromMPa),
                units.stress),
            property('xc', 'Xc', convert(material.xc, units.stressFromMPa),
                units.stress),
            property('yt', 'Yt', convert(material.yt, units.stressFromMPa),
                units.stress),
            property('yc', 'Yc', convert(material.yc, units.stressFromMPa),
                units.stress),
            property('s12', 'S12', convert(material.s12, units.stressFromMPa),
                units.stress),
            _note(
                context,
                strings?.Calculator_material_strengths_note ??
                    'Strengths are applied only when all five values are provided.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('material-details-cancel'),
          onPressed: onCancel,
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('material-details-apply'),
          onPressed: onApply,
          child: Text(strings?.Calculator_apply_material ?? 'Apply material'),
        ),
      ],
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _note(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

class _DetailValueRow extends StatelessWidget {
  const _DetailValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
