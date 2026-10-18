/// Represents a medical entity (symptom tag)
class Symptom extends Object {
  final String id;
  final String name;
  final String nameVi; // Vietnamese name
  final String category;

  const Symptom({
    required this.id,
    required this.name,
    required this.nameVi,
    required this.category,
  });

  @override
  List<Object?> get props => [id, name];
}

/// Severity levels for first-aid situations
enum SeverityLevel {
  safe,    // Xanh — có thể tự xử lý
  warning, // Vàng — cần chú ý
  danger,  // Đỏ — nguy hiểm, cần sơ cứu khẩn cấp
}

/// A single step in first-aid procedure
class FirstAidStep {
  final int stepNumber;
  final String instruction;
  final String instructionVi;
  final String? imageAsset;
  final bool isWarning;

  const FirstAidStep({
    required this.stepNumber,
    required this.instruction,
    required this.instructionVi,
    this.imageAsset,
    this.isWarning = false,
  });
}

/// Complete first-aid guide entity
class FirstAidGuide {
  final String id;
  final String conditionName;      // e.g. "Snake Bite"
  final String conditionNameVi;    // e.g. "Rắn cắn"
  final SeverityLevel severity;
  final String description;
  final String descriptionVi;
  final List<FirstAidStep> steps;
  final List<String> doNots;       // Things to NOT do
  final List<String> doNotsVi;
  final String? whenToEvacuate;
  final String? whenToEvacuateVi;
  final List<String> tags;         // symptom tags for matching
  final double confidenceScore;    // AI model confidence

  const FirstAidGuide({
    required this.id,
    required this.conditionName,
    required this.conditionNameVi,
    required this.severity,
    required this.description,
    required this.descriptionVi,
    required this.steps,
    required this.doNots,
    required this.doNotsVi,
    this.whenToEvacuate,
    this.whenToEvacuateVi,
    required this.tags,
    this.confidenceScore = 0.0,
  });

  List<Object?> get props => [id, conditionName, severity];
}
