import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';
import 'package:swiftcomp/util/result_precision.dart';

class ResultPrecisionPage extends StatefulWidget {
  const ResultPrecisionPage({super.key});

  @override
  State<ResultPrecisionPage> createState() => _ResultPrecisionPageState();
}

class _ResultPrecisionPageState extends State<ResultPrecisionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Result_Precision),
      ),
      body: Consumer<NumberPrecisionHelper>(
        builder: (context, precision, _) => SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalSidePaddingForContentWidth,
            ),
            children: [
              const SizedBox(height: 10),
              ListTile(
                title: Text(S.of(context).Result_Precision),
                subtitle:
                    Text(123456789.toStringAsExponential(precision.precision)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        tooltip: '${S.of(context).Result_Precision} −',
                        onPressed: precision.precision > ResultPrecision.minimum
                            ? () => precision.set(precision.precision - 1)
                            : null,
                      ),
                      Flexible(
                        child: Text(
                          precision.precision.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: '${S.of(context).Result_Precision} +',
                        onPressed: precision.precision < ResultPrecision.maximum
                            ? () => precision.set(precision.precision + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
