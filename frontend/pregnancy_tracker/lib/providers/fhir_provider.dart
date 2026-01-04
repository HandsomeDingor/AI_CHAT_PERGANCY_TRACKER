import 'package:flutter/foundation.dart';
import '../services/fhir_service.dart';

class FhirProvider with ChangeNotifier {
  bool _isConnected = false;
  bool _syncEnabled = true;
  String _lastError = '';
  bool _isLoading = false;

  bool get isConnected => _isConnected;
  bool get syncEnabled => _syncEnabled;
  String get lastError => _lastError;
  bool get isLoading => _isLoading;

  Future<void> testConnection() async {
    _setLoading(true);
    try {
      _isConnected = await FhirService.testConnection();
      _lastError = _isConnected ? '' : 'Failed to connect to FHIR server';
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void toggleSync(bool enabled) {
    _syncEnabled = enabled;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> syncPatientData({
    required String id,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required int weeksOfPregnancy,
    required double weight,
  }) async {
    if (!_syncEnabled) {
      print('🔵 FHIR: Sync disabled, skipping patient sync');
      return null;
    }

    _setLoading(true);
    try {
      final patientResource = FhirService.createPatientResource(
        id: id,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        weeksOfPregnancy: weeksOfPregnancy,
        weight: weight,
      );

      final result = await FhirService.saveResource(patientResource);
      _lastError = result != null ? '' : 'Failed to sync patient data';
      notifyListeners();
      return result;
    } catch (e) {
      _lastError = 'Failed to sync patient: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> syncBloodPressure({
    required String fhirPatientId,
    required int systolic,
    required int diastolic,
    required DateTime dateTime,
    required int weekOfPregnancy,
  }) async {
    if (!_syncEnabled) {
      print('🔵 FHIR: Sync disabled, skipping blood pressure sync');
      return null;
    }

    _setLoading(true);
    try {
      final observation = FhirService.createBloodPressureObservation(
        patientId: fhirPatientId,
        systolic: systolic,
        diastolic: diastolic,
        dateTime: dateTime,
        weekOfPregnancy: weekOfPregnancy,
      );

      final result = await FhirService.saveResource(observation);
      _lastError = result != null ? '' : 'Failed to sync blood pressure';
      notifyListeners();
      return result;
    } catch (e) {
      _lastError = 'Failed to sync blood pressure: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> syncWeight({
    required String patientId,
    required double weight,
    required DateTime dateTime,
    required int weekOfPregnancy,
  }) async {
    if (!_syncEnabled) {
      print('🔵 FHIR: Sync disabled, skipping weight sync');
      return null;
    }

    _setLoading(true);
    try {
      final observation = FhirService.createWeightObservation(
        patientId: patientId,
        weight: weight,
        dateTime: dateTime,
        weekOfPregnancy: weekOfPregnancy,
      );

      final result = await FhirService.saveResource(observation);
      _lastError = result != null ? '' : 'Failed to sync weight';
      notifyListeners();
      return result;
    } catch (e) {
      _lastError = 'Failed to sync weight: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> syncBloodSugar({
    required String patientId,
    required double level,
    required String measurementType,
    required DateTime dateTime,
    required int weekOfPregnancy,
  }) async {
    if (!_syncEnabled) {
      print('🔵 FHIR: Sync disabled, skipping blood sugar sync');
      return null;
    }

    _setLoading(true);
    try {
      final observation = FhirService.createBloodSugarObservation(
        patientId: patientId,
        level: level,
        measurementType: measurementType,
        dateTime: dateTime,
        weekOfPregnancy: weekOfPregnancy,
      );

      final result = await FhirService.saveResource(observation);
      _lastError = result != null ? '' : 'Failed to sync blood sugar';
      notifyListeners();
      return result;
    } catch (e) {
      _lastError = 'Failed to sync blood sugar: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> syncFetalMovement({
    required String patientId,
    required int movementCount,
    required DateTime dateTime,
    required int weekOfPregnancy,
    required int sessionDuration,
  }) async {
    if (!_syncEnabled) {
      print('🔵 FHIR: Sync disabled, skipping fetal movement sync');
      return null;
    }

    _setLoading(true);
    try {
      final observation = FhirService.createFetalMovementObservation(
        patientId: patientId,
        movementCount: movementCount,
        dateTime: dateTime,
        weekOfPregnancy: weekOfPregnancy,
        sessionDuration: sessionDuration,
      );

      final result = await FhirService.saveResource(observation);
      _lastError = result != null ? '' : 'Failed to sync fetal movement';
      notifyListeners();
      return result;
    } catch (e) {
      _lastError = 'Failed to sync fetal movement: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

Future<Map<String, dynamic>?> syncMedication({
  required String patientId,
  required String medicationName,
  required String dosage,
  required bool taken,
  required String notes,
  required DateTime dateTime,
  required int weekOfPregnancy,
}) async {
  if (!_syncEnabled) {
    print('🔵 FHIR: Sync disabled, skipping medication sync');
    return null;
  }

  _setLoading(true);
  try {
    final observation = FhirService.createMedicationObservation(
      patientId: patientId,
      medicationName: medicationName,
      dosage: dosage,
      taken: taken,
      notes: notes,
      dateTime: dateTime,
      weekOfPregnancy: weekOfPregnancy,
    );

    final result = await FhirService.saveResource(observation);
    _lastError = result != null ? '' : 'Failed to sync medication';
    notifyListeners();
    return result;
  } catch (e) {
    _lastError = 'Failed to sync medication: $e';
    notifyListeners();
    return null;
  } finally {
    _setLoading(false);
  }
}

Future<Map<String, dynamic>?> syncMood({
  required String patientId,
  required String mood,
  required String notes,
  required DateTime dateTime,
  required int weekOfPregnancy,
}) async {
  if (!_syncEnabled) {
    print('🔵 FHIR: Sync disabled, skipping mood sync');
    return null;
  }

  _setLoading(true);
  try {
    final observation = FhirService.createMoodObservation(
      patientId: patientId,
      mood: mood,
      notes: notes,
      dateTime: dateTime,
      weekOfPregnancy: weekOfPregnancy,
    );

    final result = await FhirService.saveResource(observation);
    _lastError = result != null ? '' : 'Failed to sync mood';
    notifyListeners();
    return result;
  } catch (e) {
    _lastError = 'Failed to sync mood: $e';
    notifyListeners();
    return null;
  } finally {
    _setLoading(false);
  }
}

Future<Map<String, dynamic>?> syncFood({
  required String patientId,
  required String food,
  required String mealType,
  required int rating,
  required bool hasCravings,
  required String notes,
  required DateTime dateTime,
  required int weekOfPregnancy,
}) async {
  if (!_syncEnabled) {
    print('🔵 FHIR: Sync disabled, skipping food sync');
    return null;
  }

  _setLoading(true);
  try {
    final observation = FhirService.createFoodObservation(
      patientId: patientId,
      food: food,
      mealType: mealType,
      rating: rating,
      hasCravings: hasCravings,
      notes: notes,
      dateTime: dateTime,
      weekOfPregnancy: weekOfPregnancy,
    );

    final result = await FhirService.saveResource(observation);
    _lastError = result != null ? '' : 'Failed to sync food';
    notifyListeners();
    return result;
  } catch (e) {
    _lastError = 'Failed to sync food: $e';
    notifyListeners();
    return null;
  } finally {
    _setLoading(false);
  }
}

  Future<List<dynamic>> getPatientObservations(String patientId) async {
    _setLoading(true);
    try {
      final observations = await FhirService.getPatientObservations(patientId);
      _lastError = '';
      notifyListeners();
      return observations;
    } catch (e) {
      _lastError = 'Failed to fetch observations: $e';
      notifyListeners();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createTestData(String patientId) async {
    _setLoading(true);
    try {
      await FhirService.createTestData(patientId);
      _lastError = '';
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to create test data: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _lastError = '';
    notifyListeners();
  }
}
