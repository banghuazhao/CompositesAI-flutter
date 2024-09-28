import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/volume_fraction_model.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';

class VolumeFractionRow extends StatefulWidget {
  final VolumeFraction volumeFraction;
  final bool validate;

  const VolumeFractionRow({Key? key, required this.volumeFraction, required this.validate})
      : super(key: key);

  @override
  _VolumeFractionRowState createState() => _VolumeFractionRowState();
}

class _VolumeFractionRowState extends State<VolumeFractionRow> {
  validateLayupAngle(double? value) {
    if (value == null) {
      return "Not a number";
    } else if (value < 0 || value > 1) {
      return "Not in [0.0, 1.0]";
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
        children: [
          ListTile(
            title: Row(
              children: [
                Text(
                  "Fiber Volume Fraction",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () {
                    Dialog dialog = Dialog(
                      insetPadding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)), //this right here
                      child: Container(
                          padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
                          child: Explain.getExplain(ExplainType.fiber_volumn_fraction, context)),
                    );
                    showDialog(context: context, builder: (BuildContext context) => dialog);
                  },
                  icon: Icon(
                    Icons.help_outline_rounded,
                    color: Colors.grey,
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(),
                  labelText: "Volume Fraction (0.0 ~ 1.0)",
                  errorText:
                      widget.validate ? validateLayupAngle(widget.volumeFraction.value) : null),
              onChanged: (value) {
                widget.volumeFraction.value = double.tryParse(value);
              },
            ),
          )
        ],
      ),
    );
  }
}
