enum AnalysisType {
  elastic,
  thermalElastic;

  // Method to convert enum to JSON-friendly string
  String toJson() {
    switch (this) {
      case AnalysisType.elastic:
        return 'elastic';
      case AnalysisType.thermalElastic:
        return 'thermalElastic';
    }
  }
}
