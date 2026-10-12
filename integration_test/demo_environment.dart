import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

/// Explicitly opt in before any Firebase SDK initialization. No live defaults.
class DemoEnvironment {
  static const project = 'demo-efteqad-rules';
  static const host = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  static Future<void> initialize() async {
    if (!const bool.fromEnvironment('DEMO_EMULATORS') ||
        const String.fromEnvironment('FIREBASE_PROJECT_ID') != project ||
        !{'127.0.0.1', 'localhost', '10.0.2.2'}.contains(host)) {
      throw StateError(
        'Integration requires DEMO_EMULATORS=true, FIREBASE_PROJECT_ID=demo-efteqad-rules and a local emulator host.',
      );
    }
    if (Firebase.apps.any((app) => app.options.projectId != project)) {
      throw StateError('Refusing existing non-demo Firebase app.');
    }
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-key',
        appId: '1:1234567890:web:demo',
        messagingSenderId: '1234567890',
        projectId: project,
      ),
    );
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  }

  /// Emulator-only fixture bootstrap; owner bypass never reaches any live host.
  static Future<void> seedStageAdmin(String uid) async {
    if (Firebase.app().options.projectId != project) {
      throw StateError('Demo fixture guard');
    }
    final response = await http.patch(
      Uri.parse(
        'http://$host:8080/v1/projects/$project/databases/(default)/documents/khodam/$uid',
      ),
      headers: {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': {
          'role': {'stringValue': 'stageAdmin'},
          'status': {'stringValue': 'active'},
          'name': {'stringValue': 'Demo administrator'},
        },
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Demo fixture bootstrap failed ${response.statusCode}');
    }
  }
}
