import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/delta_t.dart';

class DeltaTemperatureRow extends StatefulWidget {
  final DeltaTemperature deltaTemperature;
  final bool validate;

  const DeltaTemperatureRow({Key? key, required this.deltaTemperature, required this.validate})
      : super(key: key);

  @override
  _DeltaTemperatureRowState createState() => _DeltaTemperatureRowState();
}

class _DeltaTemperatureRowState extends State<DeltaTemperatureRow> {
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
              "ΔT",
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
                  labelText: "ΔT",
                  errorText:
                      widget.validate ? validateLayupAngle(widget.deltaTemperature.value) : null),
              onChanged: (value) {
                widget.deltaTemperature.value = double.tryParse(value);
              },
            ),
          )
        ],
      ),
    );
  }
}
