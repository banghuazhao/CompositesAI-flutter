import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';

class PlaneStressStrainRow extends StatefulWidget {
  final MechanicalTensor mechanicalTensor;
  final bool validate;
  final Function(String) callback;

  const PlaneStressStrainRow(
      {Key? key, required this.mechanicalTensor, required this.validate, required this.callback})
      : super(key: key);

  @override
  _PlaneStressStrainRowState createState() => _PlaneStressStrainRowState();
}

class _PlaneStressStrainRowState extends State<PlaneStressStrainRow> {
  String dropValue = "Stress";

  TextEditingController textEditingController1 = TextEditingController();
  TextEditingController textEditingController2 = TextEditingController();
  TextEditingController textEditingController3 = TextEditingController();

  validateTensor(double? value) {
    if (value == null) {
      return "Not a number";
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                DropdownButton<String>(
                  value: dropValue,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
                  underline: Container(
                    height: 2,
                    color: Colors.deepPurpleAccent,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      dropValue = newValue!;
                      widget.callback(dropValue);
                      textEditingController1.clear();
                      textEditingController2.clear();
                      textEditingController3.clear();
                    });
                  },
                  items: <String>["Stress", "Strain"].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress" ? "σ11" : "ε11",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress"
                                ? (widget.mechanicalTensor as PlaneStress).sigma11
                                : (widget.mechanicalTensor as PlaneStrain).epsilon11)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress") {
                        (widget.mechanicalTensor as PlaneStress).sigma11 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as PlaneStrain).epsilon11 = double.tryParse(value);
                      }
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: TextField(
                    controller: textEditingController2,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress" ? "σ22" : "ε22",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress"
                                ? (widget.mechanicalTensor as PlaneStress).sigma22
                                : (widget.mechanicalTensor as PlaneStrain).epsilon22)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress") {
                        (widget.mechanicalTensor as PlaneStress).sigma22 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as PlaneStrain).epsilon22 = double.tryParse(value);
                      }
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress" ? "σ12" : "γ12 (2ε12)",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress"
                                ? (widget.mechanicalTensor as PlaneStress).sigma12
                                : (widget.mechanicalTensor as PlaneStrain).gamma12)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress") {
                        (widget.mechanicalTensor as PlaneStress).sigma12 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as PlaneStrain).gamma12 = double.tryParse(value);
                      }
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
