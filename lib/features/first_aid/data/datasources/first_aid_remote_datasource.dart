import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/first_aid_entities.dart';

abstract class FirstAidRemoteDatasource {
  Future<List<FirstAidGuide>> getAllGuides();
  Future<List<FirstAidGuide>> predictFromSymptoms(String symptomText);
}

@Injectable(as: FirstAidRemoteDatasource)
class FirstAidRemoteDatasourceImpl implements FirstAidRemoteDatasource {
  final SupabaseClient client;

  FirstAidRemoteDatasourceImpl(this.client);

  @override
  Future<List<FirstAidGuide>> getAllGuides() async {
    final response = await client
        .from('first_aid_guides')
        .select()
        .order('condition_name_vi');

    return (response as List).map(_mapToGuide).toList();
  }

  @override
  Future<List<FirstAidGuide>> predictFromSymptoms(String symptomText) async {
    // Full-text search on Vietnamese text via Supabase
    final keywords = symptomText.toLowerCase()
        .split(RegExp(r'[\s,]+'))
        .where((w) => w.length > 2)
        .join(' | ');

    final response = await client
        .from('first_aid_guides')
        .select()
        .textSearch('condition_name_vi', keywords, config: 'simple')
        .limit(5);

    return (response as List).map(_mapToGuide).toList();
  }

  FirstAidGuide _mapToGuide(dynamic row) {
    final map = row as Map<String, dynamic>;
    final steps = (map['steps_json'] as List? ?? []).map((s) => FirstAidStep(
      stepNumber: s['stepNumber'] as int,
      instruction: s['instruction'] as String,
      instructionVi: s['instructionVi'] as String,
      isWarning: (s['isWarning'] as bool?) ?? false,
    )).toList();

    return FirstAidGuide(
      id: map['id'] as String,
      conditionName: map['condition_name'] as String,
      conditionNameVi: map['condition_name_vi'] as String,
      severity: _parseSeverity(map['severity'] as String),
      description: map['description'] as String,
      descriptionVi: map['description_vi'] as String,
      steps: steps,
      doNots: List<String>.from(map['do_nots_json'] as List? ?? []),
      doNotsVi: List<String>.from(map['do_nots_json'] as List? ?? []),
      tags: List<String>.from(map['tags'] as List? ?? []),
      whenToEvacuate: map['when_to_evacuate'] as String?,
      whenToEvacuateVi: map['when_to_evacuate'] as String?,
    );
  }

  SeverityLevel _parseSeverity(String s) => switch (s) {
    'danger' => SeverityLevel.danger,
    'warning' => SeverityLevel.warning,
    _ => SeverityLevel.safe,
  };
}
