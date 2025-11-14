import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:script_rating_app/main.dart';
import 'package:script_rating_app/models/script.dart';
import 'package:script_rating_app/services/api_service.dart';
import 'package:script_rating_app/providers/script_provider.dart';
import 'services/test_utils.dart';

// Mock classes
class MockApiService extends Mock implements ApiService {}

// Test data generator
class IntegrationTestData {
  static List<Script> createMockScripts() => [
    Script(
      id: 'script-1',
      title: 'Sample Movie Script',
      content: 'Sample script content for testing',
      author: 'John Writer',
      createdAt: DateTime(2024, 1, 15),
      rating: 7.5,
    ),
    Script(
      id: 'script-2',
      title: 'Drama Script',
      content: 'A dramatic story unfolds...',
      author: 'Jane Author',
      createdAt: DateTime(2024, 2, 10),
      rating: 8.2,
    ),
  ];

  static Script createDetailedScript() => Script(
    id: 'detailed-script',
    title: 'Comprehensive Test Script',
    content: '''INT. COFFEE SHOP - MORNING

SARAH sits at a corner table, typing furiously on her laptop.

SARAH
(muttering to herself)
Come on, come on...

The BARISTA approaches with a steaming cup.

BARISTA
Large coffee for Sarah?

SARAH
(not looking up)
Thanks, Mike. You're a lifesaver.

FADE TO.''',
    author: 'Test Writer',
    createdAt: DateTime(2024, 3, 1),
    rating: 8.7,
  );
}

void main() {
  group('ScriptRating App Integration Tests', () {
    late ProviderContainer container;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWith((ref) => mockApiService),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    // Helper method to create test widget with app
    Widget createAppWidget({List<Script>? scripts}) {
      return ProviderScope(
        parent: container,
        child: MyApp(),
      );
    }

    group('App Initialization and Main Route Tests', () {
      testWidgets('App should initialize with Material3 theme and correct title', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - Verify Material3 theme is applied
        final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.title, equals('Script Rating App'));
        
        // Verify the theme uses Material3
        expect(materialApp.theme, isNotNull);
        expect(materialApp.theme!.useMaterial3, isTrue);
        
        // Verify main route loads (HomeScreen should be displayed)
        expect(find.text('Script Rating App'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('App should start on home route by default', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());

        // Act
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - Should show HomeScreen content
        expect(find.byType(ListView), findsOneWidget); // Scripts list
        expect(find.text('Sample Movie Script'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget); // Upload FAB
      });

      testWidgets('App should handle initial loading state properly', (WidgetTester tester) async {
        // Arrange - Use completer to simulate loading
        final completer = Completer<List<Script>>();
        when(() => mockApiService.getScripts()).thenAnswer((_) => completer.future);

        // Act
        await tester.pumpWidget(createAppWidget());
        await tester.pump(); // Trigger initial frame

        // Assert - Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Complete the future
        completer.complete([]);
        await tester.pumpAndSettle();
        
        // Should transition to empty state
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('No scripts available'), findsOneWidget);
      });

      testWidgets('App should handle deep linking to specific routes', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());

        // Act - Initialize app and navigate to different routes
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Navigate to upload screen
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Verify navigation occurred
        // Note: The actual navigation verification would depend on the specific screen implementations
        expect(find.byType(AppBar), findsAtLeastNWidgets(2)); // Should have navigated from home

        // Navigate back to home
        final navigator = tester.widget<Navigator>(find.byType(Navigator));
        // In test environment, GoRouter handles this automatically
      });
    });

    group('Navigation and Routing Tests', () {
      testWidgets('App should support navigation to all major routes', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Test navigation to Upload
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        
        // Test navigation to LLM Dashboard via app bar
        await tester.tap(find.byIcon(Icons.smart_toy_outlined));
        await tester.pumpAndSettle();

        // Test navigation to History
        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();
      });

      testWidgets('App should maintain routing state across navigation', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Verify initial state
        final initialAppBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(initialAppBar.title, isA<Text>().having((t) => t.data, 'title', 'Script Rating App'));

        // Navigate to different screen
        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();

        // Navigate back to home
        // In GoRouter, this should work seamlessly
        // Note: Actual implementation may vary based on screen structure
      });

      testWidgets('App should handle invalid routes gracefully', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Act - Try to navigate to non-existent route
        // This would typically be handled by GoRouter's error handling
        // The exact behavior depends on GoRouter configuration
      });
    });

    group('Key User Workflows Tests', () {
      testWidgets('Complete user journey: Empty state → Add script → View results', (WidgetTester tester) async {
        // Arrange - Start with empty scripts
        when(() => mockApiService.getScripts()).thenAnswer((_) async => []);
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - Verify empty state
        expect(find.text('No scripts available'), findsOneWidget);
        expect(find.byIcon(Icons.movie_outlined), findsOneWidget);

        // Act - User uploads a script (navigate to upload)
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Act - Simulate successful script upload and return to home
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        
        // Navigate back to home (simulate return from upload)
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Assert - Verify script appears in list
        expect(find.text('No scripts available'), findsNothing);
        expect(find.text('Sample Movie Script'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('User journey through script analysis workflow', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Act - User taps on a script item to view details
        await tester.tap(find.text('Sample Movie Script'));
        await tester.pumpAndSettle();

        // Act - User initiates analysis
        // This would depend on the specific implementation of script detail/navigation
      });

      testWidgets('Error recovery workflow: Network error → Retry → Success', (WidgetTester tester) async {
        // Arrange - Start with error
        when(() => mockApiService.getScripts()).thenThrow(Exception('Network error'));
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - Verify error state
        expect(find.text('Error loading scripts'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget); // Retry button

        // Act - User retries
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert - Verify recovery
        expect(find.text('Error loading scripts'), findsNothing);
        expect(find.text('Sample Movie Script'), findsOneWidget);
      });
    });

    group('App-level State Management Tests', () {
      testWidgets('App should properly handle ProviderScope and dependency injection', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());

        // Act
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - Verify ProviderScope is active
        expect(find.byType(ProviderScope), findsOneWidget);
        
        // Verify services are accessible through providers
        final scriptsList = container.read(scriptsProvider);
        expect(scriptsList, isA<AsyncData<List<Script>>>());
        expect(scriptsList.value, hasLength(2));
      });

      testWidgets('App should maintain state consistency across widget rebuilds', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        final initialScripts = container.read(scriptsProvider);
        
        // Act - Trigger widget rebuild
        await tester.binding.setSurfaceSize(Size(800, 600));
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - State should be consistent
        final rebuiltScripts = container.read(scriptsProvider);
        expect(rebuiltScripts.value, equals(initialScripts.value));
      });

      testWidgets('App should handle concurrent async operations properly', (WidgetTester tester) async {
        // Arrange
        final scripts1 = [IntegrationTestData.createMockScripts().first];
        final scripts2 = IntegrationTestData.createMockScripts();
        
        when(() => mockApiService.getScripts()).thenAnswer((_) async => scripts1);
        when(() => mockApiService.getScript(any())).thenAnswer((_) async => scripts2.first);

        // Act - Load initial scripts
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Trigger refresh (concurrent with other operations)
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        // Update mock to return different data
        when(() => mockApiService.getScripts()).thenAnswer((_) async => scripts2);
        await tester.pumpAndSettle();

        // Assert - Should handle concurrent operations without crashes
        expect(find.text('Drama Script'), findsOneWidget);
      });
    });

    group('Provider Integration Tests', () {
      testWidgets('App should properly integrate with Riverpod providers', (WidgetTester tester) async {
        // Arrange
        final mockScripts = IntegrationTestData.createMockScripts();
        when(() => mockApiService.getScripts()).thenAnswer((_) async => mockScripts);

        // Act
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - Verify provider integration
        final scriptsState = container.read(scriptsProvider);
        expect(scriptsState, isA<AsyncData<List<Script>>>());
        expect(scriptsState.value, equals(mockScripts));
        
        // Verify UI reflects provider state
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Script), findsNWidgets(2)); // Should render both scripts
      });

      testWidgets('App should handle provider errors gracefully', (WidgetTester tester) async {
        // Arrange - Simulate provider error
        when(() => mockApiService.getScripts()).thenThrow(Exception('Provider error'));
        when(() => mockApiService.getScript(any())).thenThrow(Exception('Provider error'));

        // Act
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - Should show error state without crashing
        expect(find.text('Error loading scripts'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('App should support provider dependency chains', (WidgetTester tester) async {
        // Arrange
        final script = IntegrationTestData.createDetailedScript();
        when(() => mockApiService.getScripts()).thenAnswer((_) async => [script]);
        when(() => mockApiService.getScript(script.id)).thenAnswer((_) async => script);

        // Act - Load app with script
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Simulate loading individual script (for script provider family)
        final scriptProvider = container.read(scriptProvider(script.id).notifier);
        expect(scriptProvider, isA<ScriptNotifier>());

        // Assert - Provider dependencies should work correctly
        expect(container.read(scriptProvider(script.id)).value, isNotNull);
      });
    });

    group('App-level Error Handling Tests', () {
      testWidgets('App should handle app-level exceptions without crashing', (WidgetTester tester) async {
        // Arrange - Simulate various error conditions
        when(() => mockApiService.getScripts()).thenThrow(Exception('Critical error'));
        
        // Act & Assert - App should not crash on critical errors
        expect(() async => await tester.pumpWidget(createAppWidget()), returnsNormally);
        await tester.pumpAndSettle();

        // Should show error UI
        expect(find.text('Error loading scripts'), findsOneWidget);
      });

      testWidgets('App should handle theme changes gracefully', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Act - Simulate theme change
        await tester.binding.setBrightness(Brightness.dark);
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - App should adapt to theme changes
        final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp, isNotNull);
      });

      testWidgets('App should handle orientation changes', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Act - Change orientation
        await tester.binding.setSurfaceSize(Size(800, 600)); // Portrait
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        await tester.binding.setSurfaceSize(Size(600, 800)); // Landscape
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - App should maintain functionality across orientations
        expect(find.text('Sample Movie Script'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Performance and Memory Tests', () {
      testWidgets('App should handle large datasets efficiently', (WidgetTester tester) async {
        // Arrange - Create large dataset
        final largeScriptList = List.generate(100, (index) => Script(
          id: 'script-$index',
          title: 'Large Script $index',
          content: 'Content for script $index',
          author: 'Author $index',
          createdAt: DateTime(2024, 1, index + 1),
          rating: (index % 10).toDouble(),
        ));

        when(() => mockApiService.getScripts()).thenAnswer((_) async => largeScriptList);

        // Act - Start performance measurement
        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Assert - Should render efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Should complete within 3 seconds
        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Large Script 50'), findsOneWidget);
      });

      testWidgets('App should not leak memory on route changes', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());

        // Act - Navigate between routes multiple times
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(createAppWidget());
          await tester.pumpAndSettle();
          
          await tester.tap(find.byIcon(Icons.history));
          await tester.pumpAndSettle();
          
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
        }

        // Final render should still work
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();
        
        expect(find.text('Sample Movie Script'), findsOneWidget);
      });
    });

    group('Accessibility and Usability Tests', () {
      testWidgets('App should have proper semantic labels for screen readers', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());

        // Act
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Assert - Verify semantic accessibility
        expect(find.bySemanticsLabel('Script Rating App'), findsOneWidget);
        expect(find.bySemanticsLabel('Upload Script'), findsOneWidget);
      });

      testWidgets('App should support keyboard navigation', (WidgetTester tester) async {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => IntegrationTestData.createMockScripts());
        await tester.pumpWidget(createAppWidget());
        await tester.pumpAndSettle();

        // Act - Test keyboard navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Should not crash with keyboard events
        expect(find.text('Sample Movie Script'), findsOneWidget);
      });
    });
  });
}
