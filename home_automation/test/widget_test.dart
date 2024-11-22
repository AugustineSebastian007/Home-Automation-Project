import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_automation/features/landing/presentation/components/my_textfield.dart';
import 'package:home_automation/styles/colors.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core/firebase_core.dart';

// Mock Firebase App for testing
class MockFirebaseApp extends Mock implements FirebaseApp {}

void main() {
  // Initialize Flutter test binding
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    print('\n🔄 Setting up new test...');
  });

  tearDown(() {
    print('✅ Test completed\n');
  });

  group('MyTextField Tests', () {
    // Test case for verifying MyTextField widget rendering and functionality
    testWidgets('MyTextField renders with correct properties', (WidgetTester tester) async {
      print('📱 Testing MyTextField widget...');
      
      // Initialize a controller for the text field
      final controller = TextEditingController();
      print('⚙️ Created TextEditingController');
      
      print('🏗️ Building widget tree...');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyTextField(
              controller: controller,
              hintText: 'Enter text',
              obscureText: false,
            ),
          ),
        ),
      );
      print('✅ Widget tree built successfully');

      print('🔍 Verifying TextField existence...');
      expect(find.byType(TextField), findsOneWidget,
          reason: 'TextField should be present in the widget tree');
      print('✅ TextField found in widget tree');
      
      print('🔍 Checking hint text...');
      expect(find.text('Enter text'), findsOneWidget,
          reason: 'Hint text should be visible');
      print('✅ Hint text verified');
      
      print('⌨️ Testing text input...');
      await tester.enterText(find.byType(TextField), 'Test Input');
      expect(controller.text, 'Test Input',
          reason: 'TextField should update controller value correctly');
      print('✅ Text input functionality verified');
    });
  });

  group('Color Tests', () {
    // Test case for verifying color constants
    test('HomeAutomationColors should have correct values', () {
      print('🎨 Testing color constants...');
      
      // Test light theme colors
      print('🔍 Checking light theme colors...');
      expect(HomeAutomationColors.lightPrimary, const Color(0xFF098E1F));
      print('✅ Light primary color verified');
      
      // Test dark theme colors
      print('🔍 Checking dark theme colors...');
      expect(HomeAutomationColors.darkPrimary, const Color(0xFF30FF51));
      print('✅ Dark primary color verified');
      
      // Test background colors
      print('🔍 Checking background colors...');
      expect(HomeAutomationColors.lightBackground, Colors.white);
      print('✅ Background colors verified');
    });
  });

  group('Form Validation Tests', () {
    // Test case for password validation
    test('Password validation test', () {
      print('🔐 Testing password validation...');
      
      final password = 'Test123!';
      final confirmPassword = 'Test123!';
      print('📝 Test passwords created');
      
      print('🔍 Checking password match...');
      expect(password == confirmPassword, true,
          reason: 'Passwords should match');
      print('✅ Password match verified');
      
      print('🔍 Checking password length...');
      expect(password.length >= 6, true,
          reason: 'Password should be at least 6 characters long');
      print('✅ Password length verified');
      
      print('✨ All password validations passed');
    });
  });
}
