import 'dart:convert';
import 'package:http/http.dart' as http;

class FhirService {
  static const String _baseUrl = 'https://hapi.fhir.org/baseR4';
  static final http.Client _client = http.Client();

  static Map<String, dynamic> createPatientResource({
    required String id,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required int weeksOfPregnancy,
    required double weight,
  }) {
    return {
      "resourceType": "Patient",
      "identifier": [
        {
          "system": "http://pregnancy-tracker.org/patient-id",
          "value": id,
        }
      ],
      "name": [
        {
          "family": lastName,
          "given": [firstName],
          "use": "official",
        }
      ],
      "telecom": [
        {
          "system": "phone",
          "value": phone,
          "use": "mobile",
        },
        {
          "system": "email", 
          "value": email,
          "use": "work",
        }
      ],
      "extension": [
        {
          "url": "http://pregnancy-tracker.org/weeks-of-pregnancy",
          "valueInteger": weeksOfPregnancy,
        },
        {
          "url": "http://pregnancy-tracker.org/current-weight", 
          "valueQuantity": {
            "value": weight,
            "unit": "kg",
            "system": "http://unitsofmeasure.org",
          },
        }
      ],
    };
  }

  static Map<String, dynamic> createBloodPressureObservation({
    required String patientId,
    required int systolic,
    required int diastolic,
    required DateTime dateTime,
    required int weekOfPregnancy,
  }) {
    return {
      "resourceType": "Observation",
      "status": "final",
      "category": [
        {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/observation-category",
              "code": "vital-signs",
              "display": "Vital Signs",
            }
          ]
        }
      ],
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "85354-9",
            "display": "Blood pressure panel",
          }
        ],
        "text": "Blood Pressure",
      },
      "subject": {
        "reference": "Patient/$patientId", // Use FHIR Patient ID here
      },
      "effectiveDateTime": dateTime.toUtc().toIso8601String(),
      "component": [
        {
          "code": {
            "coding": [
              {
                "system": "http://loinc.org",
                "code": "8480-6", 
                "display": "Systolic blood pressure",
              }
            ]
          },
          "valueQuantity": {
            "value": systolic.toDouble(),
            "unit": "mmHg",
            "system": "http://unitsofmeasure.org",
            "code": "mm[Hg]",
          },
        },
        {
          "code": {
            "coding": [
              {
                "system": "http://loinc.org",
                "code": "8462-4",
                "display": "Diastolic blood pressure",
              }
            ]
          },
          "valueQuantity": {
            "value": diastolic.toDouble(),
            "unit": "mmHg",
            "system": "http://unitsofmeasure.org", 
            "code": "mm[Hg]",
          },
        }
      ],
      "extension": [
        {
          "url": "http://pregnancy-tracker.org/pregnancy-week",
          "valueInteger": weekOfPregnancy,
        }
      ],
    };
  }

  static Map<String, dynamic> createWeightObservation({
    required String patientId,
    required double weight,
    required DateTime dateTime,
    required int weekOfPregnancy,
  }) {
    return {
      "resourceType": "Observation",
      "status": "final",
      "category": [
        {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/observation-category",
              "code": "vital-signs",
              "display": "Vital Signs",
            }
          ]
        }
      ],
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "29463-7",
            "display": "Body weight",
          }
        ],
        "text": "Body Weight",
      },
      "subject": {
        "reference": "Patient/$patientId",
      },
      "effectiveDateTime": dateTime.toUtc().toIso8601String(),
      "valueQuantity": {
        "value": weight,
        "unit": "kg",
        "system": "http://unitsofmeasure.org",
        "code": "kg",
      },
      "extension": [
        {
          "url": "http://pregnancy-tracker.org/pregnancy-week",
          "valueInteger": weekOfPregnancy,
        }
      ],
    };
  }

  static Map<String, dynamic> createBloodSugarObservation({
    required String patientId,
    required double level,
    required String measurementType,
    required DateTime dateTime,
    required int weekOfPregnancy,
  }) {
    return {
      "resourceType": "Observation",
      "status": "final",
      "category": [
        {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/observation-category",
              "code": "laboratory",
              "display": "Laboratory",
            }
          ]
        }
      ],
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "15074-8",
            "display": "Glucose [Mass/volume] in Blood",
          }
        ],
        "text": "Blood Glucose",
      },
      "subject": {
        "reference": "Patient/$patientId",
      },
      "effectiveDateTime": dateTime.toUtc().toIso8601String(),
      "valueQuantity": {
        "value": level,
        "unit": "mg/dL",
        "system": "http://unitsofmeasure.org",
        "code": "mg/dL",
      },
      "extension": [
        {
          "url": "http://pregnancy-tracker.org/pregnancy-week",
          "valueInteger": weekOfPregnancy,
        },
        {
          "url": "http://pregnancy-tracker.org/measurement-type",
          "valueString": measurementType,
        }
      ],
    };
  }

  static Map<String, dynamic> createFetalMovementObservation({
    required String patientId,
    required int movementCount,
    required DateTime dateTime,
    required int weekOfPregnancy,
    required int sessionDuration,
  }) {
    return {
      "resourceType": "Observation",
      "status": "final",
      "category": [
        {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/observation-category",
              "code": "survey",
              "display": "Survey",
            }
          ]
        }
      ],
      "code": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "82810-3",
            "display": "Fetal movement",
          }
        ],
        "text": "Fetal Movement Count",
      },
      "subject": {
        "reference": "Patient/$patientId",
      },
      "effectiveDateTime": dateTime.toUtc().toIso8601String(),
      "valueInteger": movementCount,
      "extension": [
        {
          "url": "http://pregnancy-tracker.org/pregnancy-week",
          "valueInteger": weekOfPregnancy,
        },
        {
          "url": "http://pregnancy-tracker.org/session-duration",
          "valueInteger": sessionDuration,
        }
      ],
    };
  }

  static Future<Map<String, dynamic>?> searchPatientByIdentifier(String identifier) async {
    try {
      final url = '$_baseUrl/Patient?identifier=$identifier';
      
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/fhir+json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final entries = responseData['entry'] as List<dynamic>?;
        
        if (entries != null && entries.isNotEmpty) {
          return entries.first['resource'] as Map<String, dynamic>;
        }
      }
      
      return null;
    } catch (e) {
      print('❌ FHIR Search Patient Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateResource(Map<String, dynamic> resource) async {
    try {
      final resourceType = resource['resourceType'];
      final resourceId = resource['id'];
      
      if (resourceId == null) {
        throw 'Resource ID is required for update';
      }
      
      final url = '$_baseUrl/$resourceType/$resourceId';
      
      print('🔵 FHIR: Updating $resourceType at $url');
      print('🔵 FHIR Resource: ${jsonEncode(resource)}');

      final response = await _client.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/fhir+json',
          'Accept': 'application/fhir+json',
        },
        body: jsonEncode(resource),
      );

      print('🔵 FHIR Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final resourceId = responseData['id'];
        print('✅ FHIR: $resourceType updated successfully with ID: $resourceId');
        return responseData;
      } else {
        print('❌ FHIR: Server returned ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ FHIR Update Error: $e');
      return null;
    }
  }

static Map<String, dynamic> createMedicationObservation({
  required String patientId,
  required String medicationName,
  required String dosage,
  required bool taken,
  required String notes,
  required DateTime dateTime,
  required int weekOfPregnancy,
}) {
  return {
    "resourceType": "Observation",
    "status": "final",
    "category": [
      {
        "coding": [
          {
            "system": "http://terminology.hl7.org/CodeSystem/observation-category",
            "code": "procedure",
            "display": "Procedure",
          }
        ]
      }
    ],
    "code": {
      "coding": [
        {
          "system": "http://loinc.org",
          "code": "73643-5",
          "display": "Medication administered",
        }
      ],
      "text": "Medication Administration",
    },
    "subject": {
      "reference": "Patient/$patientId",
    },
    "effectiveDateTime": dateTime.toUtc().toIso8601String(),
    "valueString": "$medicationName - $dosage",
    "component": [
      {
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "73643-5",
              "display": "Medication administered",
            }
          ]
        },
        "valueString": taken ? "Taken" : "Missed",
      },
      {
        "code": {
          "coding": [
            {
              "system": "http://loinc.org", 
              "code": "34084-6",
              "display": "Medication notes",
            }
          ]
        },
        "valueString": notes,
      }
    ],
    "extension": [
      {
        "url": "http://pregnancy-tracker.org/pregnancy-week",
        "valueInteger": weekOfPregnancy,
      }
    ],
  };
}

static Map<String, dynamic> createMoodObservation({
  required String patientId,
  required String mood,
  required String notes,
  required DateTime dateTime,
  required int weekOfPregnancy,
}) {
  return {
    "resourceType": "Observation",
    "status": "final",
    "category": [
      {
        "coding": [
          {
            "system": "http://terminology.hl7.org/CodeSystem/observation-category",
            "code": "survey",
            "display": "Survey",
          }
        ]
      }
    ],
    "code": {
      "coding": [
        {
          "system": "http://loinc.org",
          "code": "75313-5",
          "display": "Mood",
        }
      ],
      "text": "Mood Assessment",
    },
    "subject": {
      "reference": "Patient/$patientId",
    },
    "effectiveDateTime": dateTime.toUtc().toIso8601String(),
    "valueString": mood,
    "component": [
      {
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "75313-5", 
              "display": "Mood notes",
            }
          ]
        },
        "valueString": notes,
      }
    ],
    "extension": [
      {
        "url": "http://pregnancy-tracker.org/pregnancy-week",
        "valueInteger": weekOfPregnancy,
      }
    ],
  };
}

static Map<String, dynamic> createFoodObservation({
  required String patientId,
  required String food,
  required String mealType,
  required int rating,
  required bool hasCravings,
  required String notes,
  required DateTime dateTime,
  required int weekOfPregnancy,
}) {
  return {
    "resourceType": "Observation",
    "status": "final",
    "category": [
      {
        "coding": [
          {
            "system": "http://terminology.hl7.org/CodeSystem/observation-category",
            "code": "dietary",
            "display": "Dietary",
          }
        ]
      }
    ],
    "code": {
      "coding": [
        {
          "system": "http://loinc.org",
          "code": "75344-0",
          "display": "Dietary intake",
        }
      ],
      "text": "Food Intake",
    },
    "subject": {
      "reference": "Patient/$patientId",
    },
    "effectiveDateTime": dateTime.toUtc().toIso8601String(),
    "valueString": "$mealType: $food",
    "component": [
      {
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "75344-0",
              "display": "Food rating",
            }
          ]
        },
        "valueInteger": rating,
      },
      {
        "code": {
          "coding": [
            {
              "system": "http://pregnancy-tracker.org/cravings",
              "code": "cravings",
              "display": "Food cravings",
            }
          ]
        },
        "valueBoolean": hasCravings,
      },
      {
        "code": {
          "coding": [
            {
              "system": "http://loinc.org",
              "code": "75344-0",
              "display": "Food notes",
            }
          ]
        },
        "valueString": notes,
      }
    ],
    "extension": [
      {
        "url": "http://pregnancy-tracker.org/pregnancy-week",
        "valueInteger": weekOfPregnancy,
      }
    ],
  };
}

  static Future<Map<String, dynamic>?> saveResource(Map<String, dynamic> resource) async {
    try {
      final resourceType = resource['resourceType'];
      final url = '$_baseUrl/$resourceType';
      
      print('🔵 FHIR: Sending $resourceType to $url');
      print('🔵 FHIR Resource: ${jsonEncode(resource)}');

      final response = await _client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/fhir+json',
          'Accept': 'application/fhir+json',
        },
        body: jsonEncode(resource),
      );

      print('🔵 FHIR Response Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final resourceId = responseData['id'];
        print('✅ FHIR: $resourceType saved successfully with ID: $resourceId');
        return responseData;
      } else {
        print('❌ FHIR: Server returned ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ FHIR Error: $e');
      return null;
    }
  }

  static Future<List<dynamic>> searchPatient(String identifier) async {
    try {
      final url = '$_baseUrl/Patient?identifier=$identifier';
      
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/fhir+json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final entries = responseData['entry'] as List<dynamic>?;
        
        return entries ?? [];
      }
      
      return [];
    } catch (e) {
      print('❌ FHIR Search Patient Error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getPatientObservations(String patientId) async {
    try {
      final url = '$_baseUrl/Observation?patient=$patientId&_sort=-date';
      
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/fhir+json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final entries = responseData['entry'] as List<dynamic>?;
        
        return entries ?? [];
      }
      
      return [];
    } catch (e) {
      print('❌ FHIR Get Observations Error: $e');
      return [];
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/metadata'),
        headers: {
          'Accept': 'application/fhir+json',
        },
      );
      
      final isConnected = response.statusCode == 200;
      print('🔵 FHIR Connection Test: ${isConnected ? "✅ Connected" : "❌ Failed"}');
      return isConnected;
    } catch (e) {
      print('❌ FHIR Connection Test Failed: $e');
      return false;
    }
  }

  static Future<void> createTestData(String patientId) async {
    try {
      print('🔵 FHIR: Creating test data for patient $patientId');
      
      final testBpData = [
        {'systolic': 115, 'diastolic': 75, 'week': 12},
        {'systolic': 118, 'diastolic': 78, 'week': 16},
        {'systolic': 120, 'diastolic': 80, 'week': 20},
        {'systolic': 122, 'diastolic': 82, 'week': 24},
        {'systolic': 125, 'diastolic': 85, 'week': 28},
      ];

      for (var data in testBpData) {
        final observation = createBloodPressureObservation(
          patientId: patientId,
          systolic: data['systolic']!,
          diastolic: data['diastolic']!,
          dateTime: DateTime.now().subtract(Duration(days: (40 - data['week']!) * 7)),
          weekOfPregnancy: data['week']!,
        );
        await saveResource(observation);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('✅ FHIR: Test data created successfully');
    } catch (e) {
      print('❌ FHIR Test Data Creation Failed: $e');
    }
  }
}
