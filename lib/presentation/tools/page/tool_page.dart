import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/tool_model.dart';
import 'package:swiftcomp/presentation/tools/page/UDFRC_rules_of_mixture_page.dart';
import 'package:swiftcomp/presentation/tools/page/lamina_stress_strain_page.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/util/app_interactions.dart';
import 'package:swiftcomp/util/app_theme.dart';
import 'package:swiftcomp/util/context_extension_screen_width.dart';

import 'lamina_engineering_constants_page.dart';
import 'laminate_3d_properties_page.dart';
import 'laminate_plate_properties_page.dart';
import 'laminate_stress_strain_page.dart';

class ToolPage extends StatefulWidget {
  const ToolPage({super.key});

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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Tools"),
          foregroundColor: scheme.onSurface,
          iconTheme: IconThemeData(color: scheme.onSurface),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalSidePaddingForContentWidth,
                  AppSpacing.md,
                  context.horizontalSidePaddingForContentWidth,
                  AppSpacing.xl,
                ),
                itemCount: _tools.length,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: wide ? 520 : constraints.maxWidth,
                  mainAxisExtent: 96,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final model = _tools[index];
                  return Pressable(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    haptic: true,
                    onTap: () => model.action(context),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(children: [
                          Hero(
                            tag: 'tool-${model.title}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              child: Image(
                                height: 56,
                                width: 56,
                                image: model.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              model.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          IconButton(
                            tooltip: 'About ${model.title}',
                            onPressed: () {
                              AppHaptics.light();
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    AppSpacing.lg,
                                    AppSpacing.md,
                                    AppSpacing.md,
                                  ),
                                  content: SingleChildScrollView(
                                    child: model.descriptionWidget,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.help_outline_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          )
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
