import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/tool_model.dart';
import 'package:swiftcomp/presentation/tools/page/UDFRC_rules_of_mixture_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

import 'lamina_engineering_constants_page.dart';
import 'laminate_3d_properties_page.dart';
import 'laminate_plate_properties_page.dart';
import 'laminate_stress_strain_page.dart';

class ToolPage extends StatefulWidget {
  const ToolPage({Key? key}) : super(key: key);

  @override
  _ToolPageState createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage>
    with AutomaticKeepAliveClientMixin {
  List<Tool> _tools = <Tool>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _tools = <Tool>[
      Tool(
          const AssetImage("images/lamina.png"),
          S.of(context).Lamina_stressstrain,
          DescriptionModels.getDescription(
              DescriptionType.lamina_stress_strain, context),
          (context) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LaminaStressStrainPage()))),
      Tool(
          const AssetImage("images/lamina.png"),
          S.of(context).Lamina_engineering_constants,
          DescriptionModels.getDescription(
              DescriptionType.lamina_engineering_constants, context),
          (context) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const LaminaEngineeringConstantsPage()))),
      Tool(
          const AssetImage("images/laminate.png"),
          S.of(context).Laminar_stressstrain,
          DescriptionModels.getDescription(
              DescriptionType.laminate_stress_strain, context),
          (context) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LaminateStressStrainPage()))),
      Tool(
          const AssetImage("images/laminate.png"),
          S.of(context).Laminate_plate_properties,
          DescriptionModels.getDescription(
              DescriptionType.Laminate_plate_properties, context),
          (context) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LaminatePlatePropertiesPage()))),
      Tool(
          const AssetImage("images/laminate.png"),
          S.of(context).Laminate_3D_properties,
          DescriptionModels.getDescription(
              DescriptionType.laminate_3d_properties, context),
          (context) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const Laminate3DPropertiesPage()))),
      Tool(
          const AssetImage("images/square_pack.png"),
          S.of(context).UDFRC_Properties,
          DescriptionModels.getDescription(
              DescriptionType.UDFRC_rules_of_mixtures, context),
          (context) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const RulesOfMixturePage())))
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(title: const Text("Tools")),
        body: SafeArea(
            child: StaggeredGridView.countBuilder(
                padding: EdgeInsets.fromLTRB(
                    context.horizontalSidePaddingForContentWidth,
                    20,
                    context.horizontalSidePaddingForContentWidth,
                    100),
                crossAxisCount: 8,
                itemCount: _tools.length,
                staggeredTileBuilder: (int index) => StaggeredTile.fit(
                    MediaQuery.of(context).size.width > 600 ? 4 : 8),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemBuilder: (BuildContext context, int index) {
                  var model = _tools[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: InkWell(
                      onTap: () {
                        model.action(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Image(
                              height: 50,
                              width: 50,
                              image: model.image,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Text(
                              model.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          IconButton(
                            onPressed: () {
                              Dialog dialog = Dialog(
                                insetPadding:
                                    EdgeInsets.fromLTRB(20, 20, 20, 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        12.0)), //this right here
                                child: Container(
                                    padding:
                                        EdgeInsets.fromLTRB(12, 20, 12, 20),
                                    child: model.descriptionWidget),
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
                        ]),
                      ),
                    ),
                  );
                })));
  }

  @override
  bool get wantKeepAlive => true;
}
