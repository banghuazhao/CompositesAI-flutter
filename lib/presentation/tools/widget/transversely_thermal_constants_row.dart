import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';
import 'package:swiftcomp/presentation/tools/model/validate.dart';

import '../../tools/model/thermal_model.dart';

class TransverselyThermalConstantsRow extends StatefulWidget {
  final TransverselyIsotropicCTE material;
  final String title;
  final bool shouldConsider12;
  final bool validate;

  const TransverselyThermalConstantsRow({Key? key, required this.material, this.title = "CTEs", this.shouldConsider12 = true, required this.validate})
      : super(key: key);

  @override
  _TransverselyThermalConstantsRowState createState() => _TransverselyThermalConstantsRowState();
}

class _TransverselyThermalConstantsRowState extends State<TransverselyThermalConstantsRow> {
  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Row(
                children: [
                  Text(
                    widget.title,
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
                            child: Explain.getExplain(ExplainType.material, context)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              border: const OutlineInputBorder(),
                              labelText: "ɑ11",
                              errorText: widget.validate
                                  ? validateCTEs(widget.material.alpha11)
                                  : null),
                          onChanged: (value) {
                            widget.material.alpha11 = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              border: const OutlineInputBorder(),
                              labelText: "ɑ22",
                              errorText: widget.validate
                                  ? validateCTEs(widget.material.alpha22)
                                  : null),
                          onChanged: (value) {
                            widget.material.alpha22 = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.shouldConsider12)
                    Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              border: const OutlineInputBorder(),
                              labelText: "ɑ12",
                              errorText: widget.validate
                                  ? validateCTEs(widget.material.alpha12)
                                  : null),
                          onChanged: (value) {
                            widget.material.alpha12 = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Container()),
                    ],
                  ),
                  if (widget.shouldConsider12)
                    const SizedBox(height: 12)
                ],
              ),
            ),
          ],
        ));
  }
}
