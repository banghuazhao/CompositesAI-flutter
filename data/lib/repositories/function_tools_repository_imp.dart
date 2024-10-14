import 'package:domain/entities/function_tool.dart';
import 'package:domain/repositories_abstract/function_tools_repository.dart';

class FunctionToolsRepositoryImp extends FunctionToolsRepository {
  String get commonDescription =>
      "Initially, display the default input parameters to the user, clearly outlining each parameter's purpose and current value. Allow the user to either proceed with these default values or modify them as needed to better suit their specific requirements. Based on the user’s decision to either retain or change the parameters, continue with the appropriate calculation process, ensuring that all modifications are fully integrated into the calculation to reflect the user’s preferences accurately.";

  @override
  List<FunctionTool> getAllFunctionTools() {
    FunctionTool calculateLaminaEngineeringConstantsTool = FunctionTool(
        name: "calculate_lamina_engineering_constants",
        description:
            "Calculates the engineering constants for a lamina. $commonDescription",
        parameters: {
          "type": "object",
          "required": ["E1", "E2", "G12", "nu12", "layup_angle"],
          "properties": {
            "E1": {"type": "number", "default": 150000, "exclusiveMinimum": 0},
            "E2": {"type": "number", "default": 10000, "exclusiveMinimum": 0},
            "G12": {"type": "number", "default": 5000, "exclusiveMinimum": 0},
            "nu12": {
              "type": "number",
              "default": 0.3,
              "maximum": 0.5,
              "minimum": -1
            },
            "layup_angle": {"type": "number", "default": 45}
          }
        });
    FunctionTool calculateLaminaStrainTool = FunctionTool(
        name: "calculate_lamina_strain",
        description: "Calculates the strains for a lamina. $commonDescription",
        parameters: {
          "type": "object",
          "required": [
            "E1",
            "E2",
            "G12",
            "nu12",
            "layup_angle",
            "sigma11",
            "sigma22",
            "sigma12"
          ],
          "properties": {
            "E1": {"type": "number", "default": 150000, "exclusiveMinimum": 0},
            "E2": {"type": "number", "default": 10000, "exclusiveMinimum": 0},
            "G12": {"type": "number", "default": 5000, "exclusiveMinimum": 0},
            "nu12": {
              "type": "number",
              "default": 0.3,
              "maximum": 0.5,
              "minimum": -1
            },
            "layup_angle": {"type": "number", "default": 45},
            "sigma11": {"type": "number", "default": 0.1},
            "sigma22": {"type": "number", "default": 0},
            "sigma12": {"type": "number", "default": 0}
          }
        });
    FunctionTool calculateLaminaStressTool = FunctionTool(
        name: "calculate_lamina_stress",
        description: "Calculates the stress for a lamina. $commonDescription",
        parameters: {
          "type": "object",
          "required": [
            "E1",
            "E2",
            "G12",
            "nu12",
            "layup_angle",
            "epsilon11",
            "epsilon22",
            "gamma12"
          ],
          "properties": {
            "E1": {"type": "number", "default": 150000, "exclusiveMinimum": 0},
            "E2": {"type": "number", "default": 10000, "exclusiveMinimum": 0},
            "G12": {"type": "number", "default": 5000, "exclusiveMinimum": 0},
            "nu12": {
              "type": "number",
              "default": 0.3,
              "maximum": 0.5,
              "minimum": -1
            },
            "layup_angle": {"type": "number", "default": 45},
            "epsilon11": {"type": "number", "default": 1e-5},
            "epsilon22": {"type": "number", "default": 0},
            "gamma12": {"type": "number", "default": 0}
          }
        });
    FunctionTool calculateLaminatePlatePropertiesTool = FunctionTool(
        name: "calculate_laminate_plate_properties",
        description:
            "Calculates the laminate plate properties. $commonDescription",
        parameters: {
          "type": "object",
          "required": [
            "E1",
            "E2",
            "G12",
            "nu12",
            "layup_sequence",
            "layer_thickness",
          ],
          "properties": {
            "E1": {"type": "number", "default": 150000, "exclusiveMinimum": 0},
            "E2": {"type": "number", "default": 10000, "exclusiveMinimum": 0},
            "G12": {"type": "number", "default": 5000, "exclusiveMinimum": 0},
            "nu12": {
              "type": "number",
              "default": 0.3,
              "maximum": 0.5,
              "minimum": -1
            },
            "layup_sequence": {"type": "string", "default": "[0/90/45/-45]s"},
            "layer_thickness": {
              "type": "number",
              "default": 0.125,
              "exclusiveMinimum": 0
            }
          }
        });
    FunctionTool calculateLaminate3DPropertiesTool = FunctionTool(
        name: "calculate_laminate_3d_properties",
        description:
            "Calculates the laminate plate properties. $commonDescription",
        parameters: {
          "type": "object",
          "required": [
            "E1",
            "E2",
            "G12",
            "nu12",
            "nu23",
            "layup_sequence",
            "layer_thickness",
          ],
          "properties": {
            "E1": {"type": "number", "default": 150000, "exclusiveMinimum": 0},
            "E2": {"type": "number", "default": 10000, "exclusiveMinimum": 0},
            "G12": {"type": "number", "default": 5000, "exclusiveMinimum": 0},
            "nu12": {
              "type": "number",
              "default": 0.3,
              "maximum": 0.5,
              "minimum": -1
            },
            "nu23": {
              "type": "number",
              "default": 0.23,
              "maximum": 0.5,
              "minimum": -1
            },
            "layup_sequence": {"type": "string", "default": "[0/90/45/-45]s"},
            "layer_thickness": {
              "type": "number",
              "default": 0.125,
              "exclusiveMinimum": 0
            }
          }
        });
    FunctionTool calculateLaminarStrainTool = FunctionTool(
        name: "calculate_laminar_strain",
        description:
            "Calculates the strains for a laminar/laminate. $commonDescription",
        parameters: {
          "type": "object",
          "required": [
            "E1",
            "E2",
            "G12",
            "nu12",
            "layupSequence",
            "layerThickness",
            "N11",
            "N22",
            "N12",
            "M11",
            "M22",
            "M12"
          ],
          "properties": {
            "E1": {"type": "number", "default": 150000, "exclusiveMinimum": 0},
            "E2": {"type": "number", "default": 10000, "exclusiveMinimum": 0},
            "G12": {"type": "number", "default": 5000, "exclusiveMinimum": 0},
            "nu12": {
              "type": "number",
              "default": 0.3,
              "maximum": 0.5,
              "minimum": -1
            },
            "layup_sequence": {"type": "string", "default": "[0/90/45/-45]s"},
            "layer_thickness": {
              "type": "number",
              "default": 0.125,
              "exclusiveMinimum": 0
            },
            "N11": {"type": "number", "default": 1},
            "N22": {"type": "number", "default": 0},
            "N12": {"type": "number", "default": 0},
            "M11": {"type": "number", "default": 0},
            "M22": {"type": "number", "default": 0},
            "M12": {"type": "number", "default": 0}
          }
        });
    FunctionTool calculateLaminarStressTool = FunctionTool(
        name: "calculate_laminar_stress",
        description:
            "Calculates the stress for a laminar/laminate. $commonDescription",
        parameters: {
          "type": "object",
          "required": [
            "E1",
            "E2",
            "G12",
            "nu12",
            "layupSequence",
            "layerThickness",
            "epsilon11",
            "epsilon22",
            "epsilon12",
            "kappa11",
            "kappa22",
            "kappa12"
          ],
          "properties": {
            "E1": {"type": "number", "default": 150000, "exclusiveMinimum": 0},
            "E2": {"type": "number", "default": 10000, "exclusiveMinimum": 0},
            "G12": {"type": "number", "default": 5000, "exclusiveMinimum": 0},
            "nu12": {
              "type": "number",
              "default": 0.3,
              "maximum": 0.5,
              "minimum": -1
            },
            "layup_sequence": {"type": "string", "default": "[0/90/45/-45]s"},
            "layer_thickness": {
              "type": "number",
              "default": 0.125,
              "exclusiveMinimum": 0
            },
            "epsilon11": {"type": "number", "default": 1e-5},
            "epsilon22": {"type": "number", "default": 0},
            "epsilon12": {"type": "number", "default": 0},
            "kappa11": {"type": "number", "default": 0},
            "kappa22": {"type": "number", "default": 0},
            "kappa12": {"type": "number", "default": 0}
          }
        });
    FunctionTool calculateUDFRCRulesOfMixtureTool = FunctionTool(
        name: "calculate_UDFRC_rules_of_mixture",
        description:
            "Calculates the UDFRC (Unidirectional fibre-reinforced composites) properties by rules of mixture. $commonDescription",
        parameters: {
          "type": "object",
          "required": [
            "E1_fiber",
            "E2_fiber",
            "G12_fiber",
            "nu12_fiber",
            "nu23_fiber",
            "E_matrix",
            "nu_matrix",
            "fiberVolumeFraction"
          ],
          "properties": {
            "E1_fiber": {
              "type": "number",
              "default": 150000,
              "exclusiveMinimum": 0
            },
            "E2_fiber": {
              "type": "number",
              "default": 10000,
              "exclusiveMinimum": 0
            },
            "G12_fiber": {
              "type": "number",
              "default": 5000,
              "exclusiveMinimum": 0
            },
            "nu12_fiber": {
              "type": "number",
              "default": 0.3,
              "maximum": 0.5,
              "minimum": -1
            },
            "nu23_fiber": {
              "type": "number",
              "default": 0.25,
              "maximum": 0.5,
              "minimum": -1
            },
            "E_matrix": {
              "type": "number",
              "default": 3500,
              "exclusiveMinimum": 0
            },
            "nu_matrix": {
              "type": "number",
              "default": 0.35,
              "maximum": 0.5,
              "minimum": -1
            },
            "fiberVolumeFraction": {
              "type": "number",
              "default": 0.3,
              "maximum": 1,
              "minimum": 0
            },
          }
        });
    return [
      calculateLaminaEngineeringConstantsTool,
      calculateLaminaStrainTool,
      calculateLaminaStressTool,
      calculateLaminatePlatePropertiesTool,
      calculateLaminate3DPropertiesTool,
      calculateLaminarStrainTool,
      calculateLaminarStressTool,
      calculateUDFRCRulesOfMixtureTool
    ];
  }
}
