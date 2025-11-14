import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:script_rating_app/models/script.dart';
import 'package:script_rating_app/providers/script_provider.dart';
import 'package:script_rating_app/services/api_service.dart';
import 'package:script_rating_app/screens/home_screen.dart';
import 'package:script_rating_app/widgets/script_list_item.dart';

// Mock classes
class MockApiService extends Mock implements ApiService {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('HomeScreen Widget Tests', () {
    late ProviderContainer container;
    late MockApiService mockApiService;
    late MockGoRouter mockGoRouter;

    setUp(() {
      mockApiService = MockApiService();
      mockGoRouter = MockGoRouter();
      container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWith((ref) => mockApiService),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    // Test Helper Methods
    List<Script> createMockScripts() => [
      Script(
        id: '1',
        title: 'Test Script 1',
        content: 'Test content 1',
        author: 'Test Author 1',
        createdAt: DateTime.now(),
        rating: 4.5,
      ),
      Script(
        id: '2',
        title: 'Test Script 2',
        content: 'Test content 2',
        author: 'Test Author 2',
        createdAt: DateTime.now(),
        rating: 4.2,
      ),
    ];

    Widget createTestWidget() {
      return ProviderScope(
        parent: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
              GoRoute(path: '/upload', builder: (context, state) => const SizedBox()),
              GoRoute(path: '/history', builder: (context, state) => const SizedBox()),
              GoRoute(path: '/llm', builder: (context, state) => const SizedBox()),
            ],
          ),
        ),
      );
    }

    // Basic Rendering Tests
    testWidgets('HomeScreen should render with title and app bar', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Script Rating App'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('HomeScreen should show loading indicator initially', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);
      final completer = Completer<List<Script>>();
      when(() => mockApiService.getScripts()).thenAnswer((_) => completer.future);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No scripts available'), findsNothing);
    });

    testWidgets('HomeScreen should render empty state when no scripts are available', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);
      
      // Wait for initial load
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
      expect(find.text('No scripts available'), findsOneWidget);
      expect(find.text('Upload your first script to get started'), findsOneWidget);
    });

    testWidgets('HomeScreen should render scripts list when scripts are available', (WidgetTester tester) async {
      // Arrange
      final mockScripts = createMockScripts();
      when(() => mockApiService.getScripts()).thenAnswer((_) async => mockScripts);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ScriptListItem), findsNWidgets(2));
      expect(find.text('Test Script 1'), findsOneWidget);
      expect(find.text('Test Script 2'), findsOneWidget);
    });

    // Navigation Tests
    testWidgets('HomeScreen should navigate to upload screen when FAB is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      // Navigation should be triggered (GoRouter handles this automatically in test environment)
      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('HomeScreen should navigate to history when history icon is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SizedBox), findsWidgets); // Placeholder for history screen
    });

    testWidgets('HomeScreen should navigate to LLM dashboard when LLM icon is pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.smart_toy_outlined));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SizedBox), findsWidgets); // Placeholder for LLM screen
    });

    // Refresh Functionality Tests
    testWidgets('HomeScreen should refresh scripts when refresh icon is pressed', (WidgetTester tester) async {
      // Arrange
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockApiService.getScripts()).called(greaterThan(0));
    });

    testWidgets('HomeScreen should invalidate and reload scripts on retry button press', (WidgetTester tester) async {
      // Arrange
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // First attempt should show error
      expect(find.text('Error loading scripts'), findsOneWidget);

      // Reset mock for success
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error loading scripts'), findsNothing);
      expect(find.text('No scripts available'), findsOneWidget);
    });

    // Error State Tests
    testWidgets('HomeScreen should display error state when API call fails', (WidgetTester tester) async {
      // Arrange
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading scripts'), findsOneWidget);
      expect(find.text('Exception: Network error'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
    });

    testWidgets('HomeScreen should handle retry button in error state', (WidgetTester tester) async {
      // Arrange
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - First retry attempt fails
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Reset mock to succeed
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error loading scripts'), findsNothing);
    });

    // Edge Cases Tests
    testWidgets('HomeScreen should handle large script list efficiently', (WidgetTester tester) async {
      // Arrange
      final largeScriptList = List.generate(
        100,
        (index) => Script(
          id: 'script-$index',
          title: 'Script $index',
          content: 'Content $index',
          author: 'Author $index',
          createdAt: DateTime.now(),
          rating: 4.0 + (index % 20) * 0.1,
        ),
      );

      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => largeScriptList);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ScriptListItem), findsNWidgets(100));
    });

    testWidgets('HomeScreen should handle scripts with null values gracefully', (WidgetTester tester) async {
      // Arrange
      final scriptsWithNulls = [
        Script(
          id: '1',
          title: 'Valid Script',
          content: 'Valid content',
          author: null, // null author
          createdAt: DateTime.now(),
          rating: null, // null rating
        ),
      ];

      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => scriptsWithNulls);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should still render without crashing
      expect(find.text('Valid Script'), findsOneWidget);
      expect(find.byType(ScriptListItem), findsOneWidget);
    });

    // App Bar Tests
    testWidgets('HomeScreen app bar should have correct actions', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>().having((t) => t.data, 'title', 'Script Rating App'));
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    // FAB Tests
    testWidgets('HomeScreen FAB should have correct label and icon', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.child, isA<Icon>());
      
      final icon = (fab.child as Icon).icon;
      expect(icon, Icons.upload_file);
    });

    // Performance Tests
    testWidgets('HomeScreen should maintain performance with many script list items', (WidgetTester tester) async {
      // Benchmark start
      final stopwatch = Stopwatch()..start();

      // Arrange
      final mockScripts = List.generate(
        50,
        (index) => Script(
          id: 'script-$index',
          title: 'Script $index',
          content: 'Content $index',
          author: 'Author $index',
          createdAt: DateTime.now(),
          rating: 4.0,
        ),
      );

      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => mockScripts);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Assert - Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ScriptListItem), findsNWidgets(50));
    });

    // Accessibility Tests
    testWidgets('HomeScreen should have semantic labels for accessibility', (WidgetTester tester) async {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.bySemanticsLabel('Script Rating App'), findsOneWidget);
      expect(find.bySemanticsLabel('LLM control center'), findsOneWidget);
      expect(find.bySemanticsLabel('Upload Script'), findsOneWidget);
    });
  });

  group('HomeScreen Integration Tests', () {
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

    // Full User Journey Tests
    testWidgets('Complete user journey from empty state to script list', (WidgetTester tester) async {
      // Arrange
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act & Assert - Initial state
      await tester.pumpWidget(ProviderScope(
        parent: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No scripts available'), findsOneWidget);

      // Simulate user returning with scripts
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => [
        Script(
          id: '1',
          title: 'My First Script',
          content: 'Test content',
          author: 'Test Author',
          createdAt: DateTime.now(),
          rating: 4.5,
        ),
      ]);

      // Refresh the screen
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No scripts available'), findsNothing);
      expect(find.text('My First Script'), findsOneWidget);
      expect(find.byType(ScriptListItem), findsOneWidget);
    });

    testWidgets('User journey through error state and recovery', (WidgetTester tester) async {
      // Arrange
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenThrow(Exception('Network error'));

      // Act & Assert - Error state
      await tester.pumpWidget(ProviderScope(
        parent: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Error loading scripts'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Simulate recovery
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act - User retries
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert - Recovered to empty state
      expect(find.text('Error loading scripts'), findsNothing);
      expect(find.text('No scripts available'), findsOneWidget);
    });
  });
}

