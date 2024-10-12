import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';

class AnalysisTypeRow extends StatefulWidget {
  AnalysisType analysisType;
  final ValueChanged<AnalysisType> onChanged; // Callback to notify parent

  AnalysisTypeRow(
      {Key? key, required this.analysisType, required this.onChanged})
      : super(key: key);

  @override
  State<AnalysisTypeRow> createState() => _AnalysisTypeRowState();
}

class _AnalysisTypeRowState extends State<AnalysisTypeRow> {
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
                    DropdownButton<AnalysisType>(
                      value: widget.analysisType,
                      icon: const Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (AnalysisType? newValue) {
                        if (newValue != null) {
                          widget.onChanged(newValue); // Notify parent of change
                        }
                      },
                      items: AnalysisType.values.map((AnalysisType value) {
                        return DropdownMenuItem<AnalysisType>(
                          value: value,
                          child: Text(value.name),
                        );
                      }).toList(),
                    ),
                  ]))
        ]));
  }
}
