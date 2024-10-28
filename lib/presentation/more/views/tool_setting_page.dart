import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

class ToolSettingPage extends StatefulWidget {
  const ToolSettingPage({Key? key}) : super(key: key);

  @override
  _ToolSettingPageState createState() => _ToolSettingPageState();
}

class _ToolSettingPageState extends State<ToolSettingPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Settings),
      ),
      body: Consumer<NumberPrecisionHelper>(
          builder: (context, value, child) => SafeArea(
                child: Stack(alignment: AlignmentDirectional.bottomCenter, children: [
                  ListView(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      ListTile(
                        title: Text(S.of(context).Result_Precision),
                        subtitle: Text(123456789.toStringAsExponential(value.precision)),
                        trailing: SizedBox(
                          width: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () => setState(() {
                                  if (value.precision > 1) {
                                    value.set(value.precision - 1);
                                  }
                                }),
                              ),
                              Container(
                                  width: 40,
                                  child: Text(
                                    value.precision.toString(),
                                    textAlign: TextAlign.center,
                                  )),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () => setState(() {
                                  if (value.precision < 9) {
                                    value.set(value.precision + 1);
                                  }
                                }),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // if (_anchoredAdaptiveAd != null && _isLoaded)
                  //   Container(
                  //     color: Colors.green,
                  //     width: _anchoredAdaptiveAd!.size.width.toDouble(),
                  //     height: _anchoredAdaptiveAd!.size.height.toDouble(),
                  //     child: AdWidget(ad: _anchoredAdaptiveAd!),
                  //   )
                ]),
              )),
    );
  }
}
