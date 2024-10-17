import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';

class LaminateStressStrainRow extends StatefulWidget {
  final MechanicalTensor mechanicalTensor;
  final bool validate;
  final Function(String) callback;

  const LaminateStressStrainRow(
      {Key? key, required this.mechanicalTensor, required this.validate, required this.callback})
      : super(key: key);

  @override
  _LaminateStressStrainRowState createState() => _LaminateStressStrainRowState();
}

class _LaminateStressStrainRowState extends State<LaminateStressStrainRow> {
  String dropValue = "Stress Resultants";

  TextEditingController textEditingController1 = TextEditingController();
  TextEditingController textEditingController2 = TextEditingController();
  TextEditingController textEditingController3 = TextEditingController();
  TextEditingController textEditingController4 = TextEditingController();
  TextEditingController textEditingController5 = TextEditingController();
  TextEditingController textEditingController6 = TextEditingController();

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
                      textEditingController4.clear();
                      textEditingController5.clear();
                      textEditingController6.clear();
                    });
                  },
                  items: <String>["Stress Resultants", "Plate Strains/Curvatures"]
                      .map<DropdownMenuItem<String>>((String value) {
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
                        labelText: dropValue == "Stress Resultants" ? "N11" : "ϵ11",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress).N11
                                : (widget.mechanicalTensor as LaminateStrain).epsilon11)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).N11 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).epsilon11 =
                            double.tryParse(value);
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
                        labelText: dropValue == "Stress Resultants" ? "N22" : "ϵ22",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress).N22
                                : (widget.mechanicalTensor as LaminateStrain).epsilon22)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).N22 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).epsilon22 =
                            double.tryParse(value);
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                        labelText: dropValue == "Stress Resultants" ? "N12" : "ϵ12",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress).N12
                                : (widget.mechanicalTensor as LaminateStrain).epsilon12)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).N12 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).epsilon12 =
                            double.tryParse(value);
                      }
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: TextField(
                    controller: textEditingController4,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants" ? "M11" : "𝞳11",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress).M11
                                : (widget.mechanicalTensor as LaminateStrain).kappa11)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).M11 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).kappa11 =
                            double.tryParse(value);
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
                    controller: textEditingController5,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants" ? "M22" : "𝞳22",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress).M22
                                : (widget.mechanicalTensor as LaminateStrain).kappa22)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).M22 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).kappa22 =
                            double.tryParse(value);
                      }
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: TextField(
                    controller: textEditingController6,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        border: const OutlineInputBorder(),
                        labelText: dropValue == "Stress Resultants" ? "M12" : "𝞳12",
                        errorText: widget.validate
                            ? validateTensor(dropValue == "Stress Resultants"
                                ? (widget.mechanicalTensor as LaminateStress).M12
                                : (widget.mechanicalTensor as LaminateStrain).kappa12)
                            : null,
                        errorStyle: const TextStyle(fontSize: 10)),
                    onChanged: (value) {
                      if (dropValue == "Stress Resultants") {
                        (widget.mechanicalTensor as LaminateStress).M12 = double.tryParse(value);
                      } else {
                        (widget.mechanicalTensor as LaminateStrain).kappa12 =
                            double.tryParse(value);
                      }
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
