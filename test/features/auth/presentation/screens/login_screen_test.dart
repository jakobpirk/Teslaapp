import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:tessie_app/features/auth/presentation/screens/login_screen.dart';
import 'package:tessie_app/features/auth/presentation/providers/auth_provider.dart';

@GenerateMocks([AuthProvider])
import 'login_screen_test.mocks.dart';

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    when(mockAuthProvider.isLoading).thenReturn(false);
    when(mockAuthProvider.error).thenReturn(null);
  });

  Widget createLoginScreen() {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all required fields', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('validates email field when empty', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('validates email format', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'invalid-email');

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('validates password field when empty', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('calls login when form is valid', (WidgetTester tester) async {
      when(mockAuthProvider.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createLoginScreen());

      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(signInButton);
      await tester.pump();

      verify(mockAuthProvider.login(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    testWidgets('shows loading indicator when logging in', (WidgetTester tester) async {
      when(mockAuthProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createLoginScreen());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      final textField = tester.widget<TextFormField>(passwordField);

      expect(textField.obscureText, true);

      final visibilityToggle = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityToggle);
      await tester.pump();

      final updatedPasswordField = find.widgetWithText(TextFormField, 'Password');
      final updatedTextField = tester.widget<TextFormField>(updatedPasswordField);

      expect(updatedTextField.obscureText, false);
    });
  });
}
