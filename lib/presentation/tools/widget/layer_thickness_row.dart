import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import '../model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/model/layer_thickness.dart';

class LayerThicknessPage extends StatefulWidget {
  final LayerThickness layerThickness;
  final bool validate;

  LayerThicknessPage(
      {Key? key, required this.layerThickness, required this.validate})
      : super(key: key);

  @override
  _LayerThicknessPageState createState() => _LayerThicknessPageState();
}

class _LayerThicknessPageState extends State<LayerThicknessPage> {
  late final TextEditingController _controller;
  bool _changingFromField = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.layerThickness.value?.toString() ?? '',
    );
    widget.layerThickness.addListener(_syncFromModel);
  }

  @override
  void didUpdateWidget(covariant LayerThicknessPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layerThickness != widget.layerThickness) {
      oldWidget.layerThickness.removeListener(_syncFromModel);
      widget.layerThickness.addListener(_syncFromModel);
      _syncFromModel();
    }
  }

  void _syncFromModel() {
    if (_changingFromField) return;
    final text = widget.layerThickness.value?.toString() ?? '';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _updateModel(String text) {
    _changingFromField = true;
    try {
      widget.layerThickness.value = double.tryParse(text.trim());
    } finally {
      _changingFromField = false;
    }
  }

  String? _validationError(S? strings) {
    if (!widget.validate) return null;
    final value = widget.layerThickness.value;
    if (value == null || !value.isFinite) {
      return strings?.Calculator_finite_thickness ?? 'Enter a finite number';
    }
    if (value <= 0) {
      return strings?.Calculator_positive_thickness ??
          'Thickness must be greater than zero';
    }
    return null;
  }

  @override
  void dispose() {
    widget.layerThickness.removeListener(_syncFromModel);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    final strings = S.maybeOf(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              strings?.Layer_Thickness ?? 'Layer Thickness',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: ListenableBuilder(
              listenable: widget.layerThickness,
              builder: (context, child) => TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: const OutlineInputBorder(),
                  labelText: withUnit(
                      strings?.Calculator_thickness ?? 'Thickness',
                      units.length),
                  errorText: _validationError(strings),
                  errorMaxLines: 2,
                ),
                onChanged: _updateModel,
              ),
            ),
          )
        ],
      ),
    );
  }
}
