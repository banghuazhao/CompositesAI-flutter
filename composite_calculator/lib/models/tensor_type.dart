enum TensorType {
  stress,
  strain;

  // Method to convert enum to JSON-friendly string
  String toJson() {
    switch (this) {
      case TensorType.stress:
        return 'stress';
      case TensorType.strain:
        return 'strain';
    }
  }
}
