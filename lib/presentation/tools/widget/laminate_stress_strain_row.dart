import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'calculator_validation_localization.dart';

class LaminateStressStrainRow extends StatefulWidget {
  final MechanicalTensor mechanicalTensor;
  final bool validate;
  final Function(String) callback;

  /// When supplied, the screen owns these controllers and their raw drafts.
  final List<TextEditingController>? controllers;

  const LaminateStressStrainRow(
      {Key? key,
      required this.mechanicalTensor,
      required this.validate,
      required this.callback,
      this.controllers})
      : assert(controllers == null || controllers.length == 6),
        super(key: key);

  @override
  _LaminateStressStrainRowState createState() =>
      _LaminateStressStrainRowState();
}

class _LaminateStressStrainRowState extends State<LaminateStressStrainRow> {
  String get dropValue => widget.mechanicalTensor is LaminateStress
      ? 'Stress Resultants'
      : 'Plate Strains/Curvatures';
  List<TextEditingController>? _ownedControllers;
  List<TextEditingController> get _controllers =>
      widget.controllers ?? _ownedControllers!;
  TextEditingController get textEditingController1 => _controllers[0];
  TextEditingController get textEditingController2 => _controllers[1];
  TextEditingController get textEditingController3 => _controllers[2];
  TextEditingController get textEditingController4 => _controllers[3];
  TextEditingController get textEditingController5 => _controllers[4];
  TextEditingController get textEditingController6 => _controllers[5];

  List<double?> get _values => switch (widget.mechanicalTensor) {
        LaminateStress tensor => [
            tensor.N11,
            tensor.N22,
            tensor.N12,
            tensor.M11,
            tensor.M22,
            tensor.M12
          ],
        LaminateStrain tensor => [
            tensor.epsilon11,
            tensor.epsilon22,
            tensor.epsilon12,
            tensor.kappa11,
            tensor.kappa22,
            tensor.kappa12
          ],
        _ => List.filled(6, null),
      };

  void _syncOwnedControllers() {
    final values = _values;
    _ownedControllers ??= List.generate(6, (_) => TextEditingController());
    for (var index = 0; index < values.length; index++) {
      _ownedControllers![index].text = values[index]?.toString() ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.controllers == null) _syncOwnedControllers();
  }

  @override
  void didUpdateWidget(covariant LaminateStressStrainRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controllers == null &&
        (oldWidget.controllers != null ||
            oldWidget.mechanicalTensor != widget.mechanicalTensor)) {
      _syncOwnedControllers();
    }
  }

  @override
  void dispose() {
    for (final controller in _ownedControllers ?? <TextEditingController>[]) {
      controller.dispose();
    }
    super.dispose();
  }

  validateTensor(double? value) {
    if (value == null || !value.isFinite) {
      return localizeCalculatorValidation(context, 'Enter a finite number');
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Input",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: DropdownButton<String>(
                  value: dropValue,
                  isExpanded: true,
                  itemHeight: null,
                  selectedItemBuilder: (context) => [
                    'Stress Resultants',
                    'Plate Strains/Curvatures'
                  ]
                      .map((value) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(value,
                              maxLines: 1, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
                  underline: Container(
                    height: 2,
                    color: Colors.deepPurpleAccent,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue == null || newValue == dropValue) return;
                    widget.callback(newValue);
                  },
                  items: <String>[
                    "Stress Resultants",
                    "Plate Strains/Curvatures"
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textEditingController1,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants"
                            ? withUnit("N11", units.forceResultant)
                            : "ϵ11",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress)
                                    .N11
                                : (widget.mechanicalTensor as LaminateStrain)
                                    .epsilon11)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).N11 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).epsilon11 =
                            double.tryParse(value);
                      }
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: TextField(
                    controller: textEditingController2,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants"
                            ? withUnit("N22", units.forceResultant)
                            : "ϵ22",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress)
                                    .N22
                                : (widget.mechanicalTensor as LaminateStrain)
                                    .epsilon22)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).N22 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).epsilon22 =
                            double.tryParse(value);
                      }
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textEditingController3,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants"
                            ? withUnit("N12", units.forceResultant)
                            : "ϵ12",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress)
                                    .N12
                                : (widget.mechanicalTensor as LaminateStrain)
                                    .epsilon12)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).N12 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).epsilon12 =
                            double.tryParse(value);
                      }
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: TextField(
                    controller: textEditingController4,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants"
                            ? withUnit("M11", units.momentResultant)
                            : withUnit("𝞳11", units.curvature),
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress)
                                    .M11
                                : (widget.mechanicalTensor as LaminateStrain)
                                    .kappa11)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).M11 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).kappa11 =
                            double.tryParse(value);
                      }
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textEditingController5,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants"
                            ? withUnit("M22", units.momentResultant)
                            : withUnit("𝞳22", units.curvature),
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress)
                                    .M22
                                : (widget.mechanicalTensor as LaminateStrain)
                                    .kappa22)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).M22 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).kappa22 =
                            double.tryParse(value);
                      }
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: TextField(
                    controller: textEditingController6,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants"
                            ? withUnit("M12", units.momentResultant)
                            : withUnit("𝞳12", units.curvature),
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress)
                                    .M12
                                : (widget.mechanicalTensor as LaminateStrain)
                                    .kappa12)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).M12 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).kappa12 =
                            double.tryParse(value);
                      }
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
