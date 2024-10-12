import 'package:flutter/material.dart';

class AnalysisTypeRow extends StatefulWidget {
  final Function(String) callback;

  const AnalysisTypeRow({Key? key, required this.callback}) : super(key: key);

  @override
  State<AnalysisTypeRow> createState() => _AnalysisTypeRowState();
}

class _AnalysisTypeRowState extends State<AnalysisTypeRow> {
  String analysisType = "Elastic";

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Analysis Type",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    DropdownButton<String>(
                      value: analysisType,
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
                          if (newValue != null) {
                            analysisType = newValue;
                            widget.callback(newValue);
                          }
                        });
                      },
                      items: <String>["Elastic", "Thermal Elastic"]
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ]))
        ]));
  }
}
