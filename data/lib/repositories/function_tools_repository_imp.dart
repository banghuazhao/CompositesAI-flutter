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
        description:
            "Calculates the strains for a lamina. $commonDescription",
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
        description:
            "Calculates the stress for a lamina. $commonDescription",
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
    return [
      calculateLaminaEngineeringConstantsTool,
      calculateLaminaStrainTool,
      calculateLaminaStressTool
    ];
  }
}
