import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/model/layup_sequence_model.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';

class LayupSequenceRow extends StatefulWidget {
  final LayupSequence layupSequence;
  final bool validate;

  const LayupSequenceRow(
      {Key? key, required this.layupSequence, required this.validate})
      : super(key: key);

  @override
  _LayupSequenceRowState createState() => _LayupSequenceRowState();
}

class _LayupSequenceRowState extends State<LayupSequenceRow> {
  validateLayupSequence(List<double>? layups) {
    if (layups == null) {
      return "Wrong layup sequence";
    } else if (layups.length > 1000000) {
      return "Too many layers";
    } else {
      return null;
    }
  }

  var _textEditingController = TextEditingController();

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
                  "Layup Sequence",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () {
                    Dialog dialog = Dialog(
                      insetPadding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      //this right here
                      child: Container(
                          padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
                          child: Explain.getExplain(
                              ExplainType.layup_sequence, context)),
                    );
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => dialog);
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      controller: _textEditingController,
                      decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.all(12),
                          border: const OutlineInputBorder(),
                          labelText: "[xx/xx/xx/xx]msn",
                          errorText: widget.validate
                              ? validateLayupSequence(
                                  widget.layupSequence.layups)
                              : null,
                          suffixIcon: _textEditingController.text.length > 0
                              ? IconButton(
                                  onPressed: () {
                                    _textEditingController.clear();
                                    setState(() {});
                                  },
                                  icon: Icon(Icons.cancel, color: Colors.grey))
                              : null),
                      onChanged: (value) {
                        setState(() {
                          widget.layupSequence.value = value;
                          widget.layupSequence.stringValue = value;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // ElevatedButton(onPressed: onPressed, child: child)
                        ElevatedButton(
                            onPressed: () {
                              final updatedText =
                                  _textEditingController.text + '/';
                              setState(() {
                                _textEditingController.text = updatedText;
                              });
                            },
                            child: Text("/")),
                        const SizedBox(width: 6),
                        ElevatedButton(
                            onPressed: () {
                              final updatedText =
                                  _textEditingController.text + '[';
                              setState(() {
                                _textEditingController.text = updatedText;
                              });
                            },
                            child: Text("[")),
                        const SizedBox(width: 6),
                        ElevatedButton(
                            onPressed: () {
                              final updatedText =
                                  _textEditingController.text + ']';
                              setState(() {
                                _textEditingController.text = updatedText;
                              });
                            },
                            child: Text("]")),
                      ],
                    )
                  ]))
        ],
      ),
    );
  }
}
