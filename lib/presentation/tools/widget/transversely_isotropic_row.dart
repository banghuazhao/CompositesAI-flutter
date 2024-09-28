import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';
import 'package:swiftcomp/presentation/tools/model/validate.dart';

class TransverselyIsotropicRow extends StatefulWidget {
  final TransverselyIsotropicMaterial material;
  final bool validate;

  const TransverselyIsotropicRow({Key? key, required this.material, required this.validate})
      : super(key: key);

  @override
  _TransverselyIsotropicRowState createState() => _TransverselyIsotropicRowState();
}

class _TransverselyIsotropicRowState extends State<TransverselyIsotropicRow> {
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
                    "Fiber Properties",
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
                                  widget.validate ? validateModulus(widget.material.e1) : null),
                          onChanged: (value) {
                            widget.material.e1 = double.tryParse(value);
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
                              labelText: "E2",
                              errorText:
                                  widget.validate ? validateModulus(widget.material.e2) : null),
                          onChanged: (value) {
                            widget.material.e2 = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              border: const OutlineInputBorder(),
                              labelText: "G12",
                              errorText:
                                  widget.validate ? validateModulus(widget.material.g12) : null),
                          onChanged: (value) {
                            widget.material.g12 = double.tryParse(value);
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
                              labelText: "ν12",
                              errorText: widget.validate
                                  ? validatePoissonRatio(widget.material.nu12)
                                  : null),
                          onChanged: (value) {
                            widget.material.nu12 = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              border: const OutlineInputBorder(),
                              labelText: "ν23",
                              errorText: widget.validate
                                  ? validatePoissonRatio(widget.material.nu23)
                                  : null),
                          onChanged: (value) {
                            widget.material.nu23 = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Container()),
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
