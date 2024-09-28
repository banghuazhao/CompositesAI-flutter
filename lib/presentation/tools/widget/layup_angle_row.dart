import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/angle_model.dart';

class LayupAngleRow extends StatefulWidget {
  final LayupAngle layupAngle;
  final bool validate;

  const LayupAngleRow({Key? key, required this.layupAngle, required this.validate})
      : super(key: key);

  @override
  _LayupAngleRowState createState() => _LayupAngleRowState();
}

class _LayupAngleRowState extends State<LayupAngleRow> {
  validateLayupAngle(double? value) {
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
        children: [
          ListTile(
            title: Text(
              "Layup Angle",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(),
                  labelText: "(-90 <= Angle <= 90)",
                  errorText: widget.validate ? validateLayupAngle(widget.layupAngle.value) : null),
              onChanged: (value) {
                widget.layupAngle.value = double.tryParse(value);
              },
            ),
          )
        ],
      ),
    );
  }
}
