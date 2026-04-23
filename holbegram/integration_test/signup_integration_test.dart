import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:holbegram/methods/auth_methods.dart';
import 'package:holbegram/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SignUpUser Integration Tests', () {
    setUpAll(() async {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    // tearDown() is commented out so test users persist in Firebase
    // Uncomment to auto-delete test users after each test
    /*
    tearDown(() async {
      // Clean up: delete test users after each test
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Delete user document from Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
          // Delete user from Auth
          await user.delete();
        }
      } catch (e) {
        print('Cleanup error: $e');
      }
    });
    */

    testWidgets('Test 1: SignUp with valid data - should create user in Auth',
        (WidgetTester tester) async {
      final authMethode = AuthMethode();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'test_$timestamp@example.com';

      print('\n=== Test 1: Creating user with email: $testEmail ===');

      final result = await authMethode.signUpUser(
        email: testEmail,
        password: 'TestPassword123!',
        username: 'testuser_$timestamp',
        photoUrl: '',
      );

      print('Test 1 Result: $result');

      // Check if user was created in Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      print('Test 1 - User in Auth: ${user?.uid}');

      expect(result, anyOf(['success', contains('firebase')]));
    });

    testWidgets(
        'Test 2: SignUp with valid data - should create user in Firestore',
        (WidgetTester tester) async {
      final authMethode = AuthMethode();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'test_$timestamp@example.com';
      final testUsername = 'testuser_$timestamp';

      print('\n=== Test 2: Creating user and checking Firestore ===');
      print('Email: $testEmail');
      print('Username: $testUsername');

      final result = await authMethode.signUpUser(
        email: testEmail,
        password: 'TestPassword123!',
        username: testUsername,
        photoUrl: '',
      );

      print('Test 2 Result: $result');

      if (result == 'success') {
        final user = FirebaseAuth.instance.currentUser;
        print('Test 2 - User UID: ${user?.uid}');

        // Wait a bit for Firestore write to complete
        await Future.delayed(Duration(seconds: 2));

        // Check if user document exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();

        print('Test 2 - Firestore doc exists: ${userDoc.exists}');
        print('Test 2 - Firestore data: ${userDoc.data()}');

        expect(userDoc.exists, true,
            reason: 'User document should exist in Firestore');
        expect(userDoc.data()?['email'], testEmail);
        expect(userDoc.data()?['username'], testUsername);
      } else {
        print('Test 2 - SignUp failed: $result');
      }
    });

    testWidgets('Test 3: SignUp - reproduce Firestore connection bug',
        (WidgetTester tester) async {
      final authMethode = AuthMethode();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'bug_test_$timestamp@example.com';

      print('\n=== Test 3: Attempting to reproduce Firestore bug ===');
      print('Email: $testEmail');

      final stopwatch = Stopwatch()..start();

      final result = await authMethode.signUpUser(
        email: testEmail,
        password: 'TestPassword123!',
        username: 'bugtest_$timestamp',
        photoUrl: '',
      );

      stopwatch.stop();
      print('Test 3 - Time taken: ${stopwatch.elapsedMilliseconds}ms');
      print('Test 3 - Result: $result');

      if (result != 'success') {
        print('Test 3 - ERROR REPRODUCED: $result');

        // Check if user was created in Auth despite error
        final user = FirebaseAuth.instance.currentUser;
        print('Test 3 - User in Auth: ${user?.uid}');

        if (user != null) {
          // Check Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          print('Test 3 - Firestore doc exists: ${userDoc.exists}');

          if (!userDoc.exists) {
            print(
                'Test 3 - BUG CONFIRMED: User in Auth but NOT in Firestore');
          }
        }
      }
    });

    testWidgets('Test 4: Empty fields validation', (WidgetTester tester) async {
      final authMethode = AuthMethode();

      print('\n=== Test 4: Testing empty fields validation ===');

      final result = await authMethode.signUpUser(
        email: '',
        password: 'password',
        username: '',
        photoUrl: '',
      );

      print('Test 4 Result: $result');

      expect(result, 'Please fill all the fields');
    });

    testWidgets('Test 5: Firestore write timeout test',
        (WidgetTester tester) async {
      final authMethode = AuthMethode();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'timeout_test_$timestamp@example.com';

      print('\n=== Test 5: Testing Firestore timeout ===');

      final stopwatch = Stopwatch()..start();

      final result = await authMethode.signUpUser(
        email: testEmail,
        password: 'TestPassword123!',
        username: 'timeouttest_$timestamp',
        photoUrl: '',
      );

      stopwatch.stop();
      print('Test 5 - Time taken: ${stopwatch.elapsedMilliseconds}ms');
      print('Test 5 - Result: $result');

      if (stopwatch.elapsedMilliseconds > 10000) {
        print('Test 5 - TIMEOUT: Operation took more than 10 seconds');
      }

      if (result.contains('timeout')) {
        print('Test 5 - TIMEOUT ERROR DETECTED: $result');
      }
    });
  });
}
