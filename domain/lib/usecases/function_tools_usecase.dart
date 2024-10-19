import 'dart:convert';
import '../domain.dart';
import 'package:composite_calculator/composite_calculator.dart';

class FunctionToolsUseCase {

  FunctionToolsUseCase();

  Message handleToolCall(ToolCalls tool) {
    final functionName = tool.function?.name;
    final functionArguments = tool.function?.arguments ?? "";
    final argumentsJson = jsonDecode(functionArguments);
    String outputString = "";
    if (functionName == "calculate_lamina_engineering_constants") {
      LaminaEngineeringConstantsInput input =
      LaminaEngineeringConstantsInput.fromJson(argumentsJson);
      LaminaEngineeringConstantsOutput output =
      LaminaEngineeringConstantsCalculator.calculate(input);
      outputString = output.toJson().toString();
    } else if (functionName == "calculate_lamina_strain") {
      LaminaStressStrainInput input =
      LaminaStressStrainInput.fromJson(argumentsJson);
      LaminaStressStrainOutput output =
      LaminaStressStrainCalculator.calculate(input);
      outputString = output.toJson().toString();
    } else if (functionName == "calculate_lamina_stress") {
      LaminaStressStrainInput input =
      LaminaStressStrainInput.fromJson(argumentsJson);
      input.tensorType = TensorType.strain;
      LaminaStressStrainOutput output =
      LaminaStressStrainCalculator.calculate(input);
      outputString = output.toJson().toString();
    } else if (functionName == "calculate_laminate_plate_properties") {
      LaminatePlatePropertiesInput input =
      LaminatePlatePropertiesInput.fromJson(argumentsJson);
      LaminatePlatePropertiesOutput output =
      LaminatePlatePropertiesCalculator.calculate(input);
      outputString = output.toJson().toString();
    } else if (functionName == "calculate_laminate_3d_properties") {
      Laminate3DPropertiesInput input =
      Laminate3DPropertiesInput.fromJson(argumentsJson);
      Laminate3DPropertiesOutput output =
      Laminate3DPropertiesCalculator.calculate(input);
      outputString = output.toJson().toString();
    } else if (functionName == "calculate_laminar_strain") {
      LaminarStressStrainInput input =
      LaminarStressStrainInput.fromJson(argumentsJson);
      LaminarStressStrainOutput output =
      LaminarStressStrainCalculator.calculate(input);
      outputString = output.toJson().toString();
    } else if (functionName == "calculate_laminar_stress") {
      LaminarStressStrainInput input =
      LaminarStressStrainInput.fromJson(argumentsJson);
      input.tensorType = TensorType.strain;
      LaminarStressStrainOutput output =
      LaminarStressStrainCalculator.calculate(input);
      outputString = output.toJson().toString();
    } else if (functionName == "calculate_UDFRC_rules_of_mixture") {
      UDFRCRulesOfMixtureInput input =
      UDFRCRulesOfMixtureInput.fromJson(argumentsJson);
      UDFRCRulesOfMixtureOutput output =
      UDFRCRulesOfMixtureCalculator.calculate(input);
      outputString = output.toJson().toString();
    }
    return Message(role: "tool", content: outputString, tool_call_id: tool.id);
  }

}
