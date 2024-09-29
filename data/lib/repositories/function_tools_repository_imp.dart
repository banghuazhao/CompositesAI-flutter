import 'package:domain/entities/function_tool.dart';
import 'package:domain/repositories_abstract/function_tools_repository.dart';

class FunctionToolsRepositoryImp extends FunctionToolsRepository {
  @override
  List<FunctionTool> getAllFunctionTools() {
    FunctionTool calculateLaminaEngineeringConstantsTool = FunctionTool(
        name: "calculate_lamina_engineering_constants",
        description:
        "Calculates the engineering constants for a lamina. Present the users with the default parameters. Users can use default input parameters or customize them based on their specific requirements",
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
    return [calculateLaminaEngineeringConstantsTool];
  }
}