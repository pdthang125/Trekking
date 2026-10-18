import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:trekguard_ai/features/first_aid/domain/entities/first_aid_entities.dart';
import 'package:trekguard_ai/features/first_aid/domain/repositories/first_aid_repository.dart';
import 'package:trekguard_ai/features/first_aid/domain/usecases/first_aid_usecases.dart';
import 'package:trekguard_ai/core/error/failures.dart';
import 'package:trekguard_ai/core/usecases/usecase.dart';

class MockFirstAidRepository extends Mock implements FirstAidRepository {}

void main() {
  late PredictFirstAidUseCase predictUseCase;
  late GetAllFirstAidGuidesUseCase getAllUseCase;
  late MockFirstAidRepository mockRepository;

  setUp(() {
    mockRepository = MockFirstAidRepository();
    predictUseCase = PredictFirstAidUseCase(mockRepository);
    getAllUseCase = GetAllFirstAidGuidesUseCase(mockRepository);
  });

  // ── Test data ────────────────────────────────────────────────
  const tGuide = FirstAidGuide(
    id: 'snake-bite-001',
    conditionName: 'Snake Bite',
    conditionNameVi: 'Rắn Cắn',
    severity: SeverityLevel.danger,
    description: 'Venomous snake bite requires immediate medical attention.',
    descriptionVi: 'Rắn độc cắn cần sơ cứu ngay lập tức.',
    steps: [
      FirstAidStep(
        stepNumber: 1,
        instruction: 'Keep the victim calm and still.',
        instructionVi: 'Giữ nạn nhân bình tĩnh, không cử động.',
      ),
    ],
    doNots: ['Do not suck out venom', 'Do not apply tourniquet'],
    doNotsVi: ['Không hút nọc độc', 'Không ga-rô'],
    tags: ['snake', 'bite', 'venom', 'rắn', 'cắn'],
    confidenceScore: 0.92,
  );

  // ── PredictFirstAidUseCase tests ─────────────────────────────
  group('PredictFirstAidUseCase', () {
    test('should return list of guides when prediction succeeds', () async {
      // arrange
      when(() => mockRepository.predictFromSymptoms(
        symptomText: any(named: 'symptomText'),
        useOnDevice: any(named: 'useOnDevice'),
      )).thenAnswer((_) async => const Right([tGuide]));

      // act
      final result = await predictUseCase(const PredictParams(
        symptomText: 'rắn cắn vào chân, sưng đỏ',
      ));

      // assert
      expect(result, const Right([tGuide]));
      verify(() => mockRepository.predictFromSymptoms(
        symptomText: 'rắn cắn vào chân, sưng đỏ',
        useOnDevice: true,
      )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return AIInferenceFailure when model fails', () async {
      // arrange
      when(() => mockRepository.predictFromSymptoms(
        symptomText: any(named: 'symptomText'),
        useOnDevice: any(named: 'useOnDevice'),
      )).thenAnswer((_) async => const Left(AIInferenceFailure()));

      // act
      final result = await predictUseCase(const PredictParams(
        symptomText: 'unknown symptom',
      ));

      // assert
      expect(result, const Left(AIInferenceFailure()));
    });

    test('should default to on-device mode', () async {
      // arrange
      when(() => mockRepository.predictFromSymptoms(
        symptomText: any(named: 'symptomText'),
        useOnDevice: any(named: 'useOnDevice'),
      )).thenAnswer((_) async => const Right([tGuide]));

      // act
      await predictUseCase(const PredictParams(
        symptomText: 'test',
      ));

      // assert — useOnDevice defaults to true
      verify(() => mockRepository.predictFromSymptoms(
        symptomText: 'test',
        useOnDevice: true,
      )).called(1);
    });
  });

  // ── GetAllFirstAidGuidesUseCase tests ─────────────────────────
  group('GetAllFirstAidGuidesUseCase', () {
    test('should return all guides from repository', () async {
      // arrange
      when(() => mockRepository.getAllGuides())
          .thenAnswer((_) async => const Right([tGuide]));

      // act
      final result = await getAllUseCase(NoParams());

      // assert
      expect(result, const Right([tGuide]));
      verify(() => mockRepository.getAllGuides()).called(1);
    });

    test('should return CacheFailure when local DB fails', () async {
      // arrange
      when(() => mockRepository.getAllGuides())
          .thenAnswer((_) async => const Left(CacheFailure()));

      // act
      final result = await getAllUseCase(NoParams());

      // assert
      expect(result, const Left(CacheFailure()));
    });
  });
}
