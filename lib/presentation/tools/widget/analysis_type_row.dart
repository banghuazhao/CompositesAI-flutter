import 'package:flutter/material.dart';

class AnalysisType extends StatefulWidget {
  final Function(String) callback;

  const AnalysisType({Key? key, required this.callback}) : super(key: key);

  @override
  State<AnalysisType> createState() => _AnalysisTypeState();
}

class _AnalysisTypeState extends State<AnalysisType> {
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
