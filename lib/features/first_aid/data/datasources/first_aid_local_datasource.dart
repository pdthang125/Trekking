import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/first_aid_entities.dart';
import '../models/first_aid_model.dart';
import 'package:drift/drift.dart';

abstract class FirstAidLocalDatasource {
  Future<List<FirstAidGuide>> getAllGuides();
  Future<List<FirstAidGuide>> searchGuides(String query);
  Future<List<FirstAidGuide>> searchBySymptoms(String symptomText);
  Future<FirstAidGuide?> getGuideById(String id);
  Future<List<Symptom>> getAllSymptoms();
  Future<bool> isDataReady();
  Future<void> seedFromAssets();
}

@Injectable(as: FirstAidLocalDatasource)
class FirstAidLocalDatasourceImpl implements FirstAidLocalDatasource {
  final AppDatabase db;

  FirstAidLocalDatasourceImpl(this.db);

  @override
  Future<List<FirstAidGuide>> getAllGuides() async {
    final rows = await db.select(db.firstAidGuides).get();
    return rows.map(_rowToGuide).toList();
  }

  @override
  Future<List<FirstAidGuide>> searchGuides(String query) async {
    final lowerQuery = query.toLowerCase();
    final rows = await (db.select(db.firstAidGuides)
      ..where((t) =>
        t.conditionNameVi.lower().contains(lowerQuery) |
        t.description.lower().contains(lowerQuery) |
        t.tagsJson.lower().contains(lowerQuery)))
      .get();
    return rows.map(_rowToGuide).toList();
  }

  @override
  Future<List<FirstAidGuide>> searchBySymptoms(String symptomText) async {
    // Simple keyword matching — Member 2 will replace with TFLite inference
    final keywords = symptomText.toLowerCase()
        .split(RegExp(r'[\s,]+'))
        .where((w) => w.length > 2)
        .toList();

    if (keywords.isEmpty) return [];

    final allGuides = await getAllGuides();
    final scored = <(FirstAidGuide, int)>[];

    for (final guide in allGuides) {
      int score = 0;
      final searchable = '${guide.conditionNameVi} ${guide.descriptionVi} ${guide.tags.join(' ')}'.toLowerCase();
      for (final kw in keywords) {
        if (searchable.contains(kw)) score++;
      }
      if (score > 0) scored.add((guide, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }

  @override
  Future<FirstAidGuide?> getGuideById(String id) async {
    final row = await (db.select(db.firstAidGuides)
      ..where((t) => t.id.equals(id)))
      .getSingleOrNull();
    return row != null ? _rowToGuide(row) : null;
  }

  @override
  Future<List<Symptom>> getAllSymptoms() async {
    final guides = await getAllGuides();
    final symptoms = <Symptom>{};
    for (final guide in guides) {
      for (int i = 0; i < guide.tags.length; i++) {
        symptoms.add(Symptom(
          id: '${guide.id}_tag_$i',
          name: guide.tags[i],
          nameVi: guide.tags[i],
          category: guide.conditionName,
        ));
      }
    }
    return symptoms.toList();
  }

  @override
  Future<bool> isDataReady() async {
    final count = await db.firstAidGuides.count().getSingle();
    return count > 0;
  }

  @override
  Future<void> seedFromAssets() async {
    final jsonStr = await rootBundle.loadString('assets/data/first_aid_guides.json');
    final List<dynamic> data = json.decode(jsonStr);

    await db.batch((batch) {
      for (final item in data) {
        batch.insertOnConflictUpdate(db.firstAidGuides, FirstAidGuidesCompanion(
          id: Value(item['id'] as String),
          conditionName: Value(item['conditionName'] as String),
          conditionNameVi: Value(item['conditionNameVi'] as String),
          severity: Value(item['severity'] as String),
          description: Value(item['description'] as String),
          descriptionVi: Value(item['descriptionVi'] as String),
          stepsJson: Value(json.encode(item['steps'])),
          doNotsJson: Value(json.encode(item['doNots'])),
          tagsJson: Value(json.encode(item['tags'])),
          whenToEvacuate: Value(item['whenToEvacuate'] as String?),
          whenToEvacuateVi: Value(item['whenToEvacuateVi'] as String?),
        ));
      }
    });
  }

  // ─── Private helpers ─────────────────────────────────────────
  FirstAidGuide _rowToGuide(FirstAidGuide$row row) {
    final stepsData = json.decode(row.stepsJson) as List;
    final doNots = (json.decode(row.doNotsJson) as List).cast<String>();
    final tags = (json.decode(row.tagsJson) as List).cast<String>();

    return FirstAidGuide(
      id: row.id,
      conditionName: row.conditionName,
      conditionNameVi: row.conditionNameVi,
      severity: _parseSeverity(row.severity),
      description: row.description,
      descriptionVi: row.descriptionVi,
      steps: stepsData.map((s) => FirstAidStep(
        stepNumber: s['stepNumber'] as int,
        instruction: s['instruction'] as String,
        instructionVi: s['instructionVi'] as String,
        isWarning: (s['isWarning'] as bool?) ?? false,
      )).toList(),
      doNots: doNots,
      doNotsVi: doNots, // TODO: add doNotsVi to JSON
      tags: tags,
      whenToEvacuate: row.whenToEvacuate,
      whenToEvacuateVi: row.whenToEvacuateVi,
    );
  }

  SeverityLevel _parseSeverity(String s) => switch (s) {
    'danger' => SeverityLevel.danger,
    'warning' => SeverityLevel.warning,
    _ => SeverityLevel.safe,
  };
}

// Drift type alias for table row
typedef FirstAidGuide$row = FirstAidGuidesData;
