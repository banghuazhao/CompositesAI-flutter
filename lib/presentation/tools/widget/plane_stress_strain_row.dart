import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/unit_system.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'calculator_validation_localization.dart';

class PlaneStressStrainRow extends StatefulWidget {
  final MechanicalTensor mechanicalTensor;
  final bool validate;
  final Function(String) callback;

  /// When supplied, the screen owns these controllers and their raw drafts.
  final List<TextEditingController>? controllers;

  const PlaneStressStrainRow(
      {Key? key,
      required this.mechanicalTensor,
      required this.validate,
      required this.callback,
      this.controllers})
      : assert(controllers == null || controllers.length == 3),
        super(key: key);

  @override
  _PlaneStressStrainRowState createState() => _PlaneStressStrainRowState();
}

class _PlaneStressStrainRowState extends State<PlaneStressStrainRow> {
  String get dropValue =>
      widget.mechanicalTensor is PlaneStress ? 'Stress' : 'Strain';
  List<TextEditingController>? _ownedControllers;
  List<TextEditingController> get _controllers =>
      widget.controllers ?? _ownedControllers!;
  TextEditingController get textEditingController1 => _controllers[0];
  TextEditingController get textEditingController2 => _controllers[1];
  TextEditingController get textEditingController3 => _controllers[2];

  List<double?> get _values => switch (widget.mechanicalTensor) {
        PlaneStress tensor => [tensor.sigma11, tensor.sigma22, tensor.sigma12],
        PlaneStrain tensor => [
            tensor.epsilon11,
            tensor.epsilon22,
            tensor.gamma12
          ],
        _ => List.filled(3, null),
      };

  void _syncOwnedControllers() {
    final values = _values;
    _ownedControllers ??= List.generate(3, (_) => TextEditingController());
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
  void didUpdateWidget(covariant PlaneStressStrainRow oldWidget) {
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
                  selectedItemBuilder: (context) => ['Stress', 'Strain']
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
                  items: <String>["Stress", "Strain"]
                      .map<DropdownMenuItem<String>>((String value) {
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
                        labelText: dropValue == "Stress"
                            ? withUnit("σ11", units.stress)
                            : "ε11",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress"
                                ? (widget.mechanicalTensor as PlaneStress)
                                    .sigma11
                                : (widget.mechanicalTensor as PlaneStrain)
                                    .epsilon11)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress") {
                        (widget.mechanicalTensor as PlaneStress).sigma11 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as PlaneStrain).epsilon11 =
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
                        labelText: dropValue == "Stress"
                            ? withUnit("σ22", units.stress)
                            : "ε22",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress"
                                ? (widget.mechanicalTensor as PlaneStress)
                                    .sigma22
                                : (widget.mechanicalTensor as PlaneStrain)
                                    .epsilon22)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress") {
                        (widget.mechanicalTensor as PlaneStress).sigma22 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as PlaneStrain).epsilon22 =
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
                    controller: textEditingController3,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress"
                            ? withUnit("σ12", units.stress)
                            : "γ12 (2ε12)",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress"
                                ? (widget.mechanicalTensor as PlaneStress)
                                    .sigma12
                                : (widget.mechanicalTensor as PlaneStrain)
                                    .gamma12)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress") {
                        (widget.mechanicalTensor as PlaneStress).sigma12 =
                            double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as PlaneStrain).gamma12 =
                            double.tryParse(value);
                      }
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
