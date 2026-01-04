## Flutter + FastAPI + Firebase (FHIR-integrated prototype)

This project is a Pregnancy Tracker app designed to help pregnant users record health data such as blood pressure, blood sugar, and weight, while allowing doctors to view patient reports, analyze trends, and leave notes.
It includes a Flutter frontend, a FastAPI backend, and Firebase integration for data storage.

### Features:
1. *Patient Side*
> * Record health data: blood pressure, blood sugar, weight, and fetal movements, etc.
> * Store and sync data to Firebase
> * Integrated AI Assistant
> * Message to my doctor
2. *Doctor Side*
> * View patient list and pregnancy records
> * Display trend charts (e.g., blood pressure over time)
> * Add notes or reminders for patients
> * Message to my patients
3. *FHIR Server (HAPI FHIR R4)*
> * Stores PHI using FHIR-compliant resources, including:
> * Patient
> * Observation
4. *Firebase (Non-PHI)*
> * Authentication (UID)
> * Patient profiles (non-PHI)
> * Caching
> * Logs & UI metadata
> * Message chat (non-PHI)

### Installation Guide:
**Please follow the steps in order!**
1. Clone the Repository
2. Setup the Backend (FastAPI + Firebase):
   > * Go to backend folder: cd ..\pregnancy-tracker\backend
   > * Create and activate a virtual environment: python -m venv venv
   > > * Activate (Windows):venv\Scripts\activate
   > > > Mac/Linux: source venv/bin/activate
   > * Install dependencies: pip install fastapi uvicorn firebase-admin
   > * Add Firebase key: to get Firebase Admin SDK key (firebase-key.json), and place it inside the /backend directory.(it already in /backend folder, please check if it exists first)
   > * Run the server: uvicorn main:app --reload
   > > Server will start on: http://127.0.0.1:8000
3. Setup the Frontend (Flutter):
   > * download flutter first: https://docs.flutter.dev/install/archive
   > > unzip it to the src flolder:  C:\src\flutter
   > > > then search for "environment variables" in windows, and add C:\src\flutter to the path (see the pic)
   > > > ![image](https://github.gatech.edu/user-attachments/assets/d5e808b3-3544-4888-a6d1-3d2ca39c8144)
   > * Go to frontend folder in vs code terminal or powerShell: cd ..\pregnancy-tracker\frontend\pregnancy_tracker
   > * then code this: flutter run -d chrome
   > > then the web page will pop out: If you see a blue Flutter demo page or your Pregnancy Tracker home page, the frontend is running successfully

### Firebase
> download : npm install -g firebase-tools
> download : dart pub global activate flutterfire_cli
> put it in local path of Environment Variables: for example: C:\Users\panda\AppData\Local\Pub\Cache\bin
> https://console.firebase.google.com/u/0/project/pregnancy-tracker-53f5f/firestore/databases/-default-/data/~2Frecords~2FTJ1Sm4m3ybasrovQt6rB


## How to see front pages
> 1. VS Code terminal go to cd ..\pregnancy-tracker\frontend\pregnancy_tracker:
> 2. Terminal input: firebase login
> 3. Run FlutterFire CLI: flutterfire configure
> 4. Run Flutter: flutter run -d chrome


## Folder Structure
```text
/lib
  /pages
     baby_kicks_page.dart
     blood_pressure_history_page.dart
     blood_pressure_page.dart
     blood_pressure_record_page.dart
     blood_sugar_page.dart
     chat_page.dart
     doctor_information_page.dart
     doctor_main_page.dart
     doctor_message_list_page.dart
     doctor_message_list_page.dart
     food_tracking_page.dart
     medications_page.dart
     message_chat_page.dart
     mood_page.dart
     patient_detail_page.dart
     patient_information_page.dart
     patient_list_page.dart
     patient_main_page.dart
     patient_message_list_page.dart
     patient_report_page.dart
     pregnancy_weeks_page.dart
     records_home_page.dart
     weight_page.dart
  /providers
     fhir_provider.dart
  /services
     fhir_service.dart
  auth_wrapper.dart
  firebase_options.dart
  login_page.dart
  main.dart
