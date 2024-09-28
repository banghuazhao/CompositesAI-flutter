import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';
import 'package:swiftcomp/presentation/tools/model/validate.dart';

class IsotropicMaterialRow extends StatefulWidget {
  final String title;
  final IsotropicMaterial material;
  final bool validate;

  const IsotropicMaterialRow(
      {Key? key, required this.title, required this.material, required this.validate})
      : super(key: key);

  @override
  _IsotropicMaterialRowState createState() => _IsotropicMaterialRowState();
}

class _IsotropicMaterialRowState extends State<IsotropicMaterialRow> {
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
                              labelText: "E1",
                              errorText:
                                  widget.validate ? validateModulus(widget.material.e) : null),
                          onChanged: (value) {
                            widget.material.e = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              border: const OutlineInputBorder(),
                              labelText: "ν",
                              errorText: widget.validate
                                  ? validateIsotropicPoissonRatio(widget.material.nu)
                                  : null),
                          onChanged: (value) {
                            widget.material.nu = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ));
  }
}
