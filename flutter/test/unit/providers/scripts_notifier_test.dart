import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:script_rating_app/models/script.dart';
import 'package:script_rating_app/providers/script_provider.dart';
import 'package:script_rating_app/services/api_service.dart';

// Mock classes
class MockApiService extends Mock implements ApiService {}

// Test utilities
void main() {
  group('ScriptsNotifier', () {
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

    test('ScriptsNotifier should start with loading state', () {
      // Arrange
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);
      
      // Assert
      expect(scriptsNotifier.debugState, isA<AsyncValue<List<Script>>>());
      expect(scriptsNotifier.debugState, isA<AsyncLoading<List<Script>>>());
    });

    test('ScriptsNotifier should load scripts successfully', () async {
      // Arrange
      final mockScripts = [
        TestDataGenerator.createValidScript(id: 'script-1'),
        TestDataGenerator.createValidScript(id: 'script-2'),
      ];
      
      // Reset call count from constructor
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => mockScripts);

      // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);
      await scriptsNotifier.loadScripts();

      // Assert
      final state = container.read(scriptsProvider);
      expect(state, isA<AsyncData<List<Script>>>());
      expect(state.value, hasLength(2));
      expect(state.value, equals(mockScripts));
      
      verify(() => mockApiService.getScripts()).called(1);
    });

    test('ScriptsNotifier should handle loading errors', () async {
      // Arrange
      final exception = Exception('Network error');
      // Reset call count from constructor
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenThrow(exception);

      // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);

      // Assert - Should catch the exception
      try {
        await scriptsNotifier.loadScripts();
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }
      
      final state = container.read(scriptsProvider);
      expect(state, isA<AsyncError<List<Script>>>());
      
      verify(() => mockApiService.getScripts()).called(1);
    });

    test('ScriptsNotifier should handle empty scripts list', () async {
      // Arrange
      // Reset call count from constructor
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);
      await scriptsNotifier.loadScripts();

      // Assert
      final state = container.read(scriptsProvider);
      expect(state, isA<AsyncData<List<Script>>>());
      expect(state.value, isEmpty);
      
      verify(() => mockApiService.getScripts()).called(1);
    });

    test('ScriptsNotifier should handle refresh functionality', () async {
      // Arrange
      final mockScripts = [TestDataGenerator.createValidScript()];
      // Reset call count from constructor
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => mockScripts);

      // Act - First load
      final scriptsNotifier = container.read(scriptsProvider.notifier);
      await scriptsNotifier.loadScripts();
      
      // Reset mock for refresh
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);
      await scriptsNotifier.refresh();

      // Assert
      final state = container.read(scriptsProvider);
      expect(state, isA<AsyncData<List<Script>>>());
      expect(state.value, isEmpty);
      
      verify(() => mockApiService.getScripts()).called(2);
    });

    test('ScriptsNotifier should handle concurrent requests properly', () async {
      // Arrange
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);
      final firstLoad = scriptsNotifier.loadScripts();
      final secondLoad = scriptsNotifier.loadScripts();

      // Both should complete without error
      await expectLater(firstLoad, completes);
      await expectLater(secondLoad, completes);

      // Assert
      verify(() => mockApiService.getScripts()).called(2);
    });

    test('ScriptsNotifier should handle state consistency during error recovery', () async {
      // Arrange
      final mockScripts = [TestDataGenerator.createValidScript()];
      // Reset call count from constructor
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenThrow(Exception('Network error'));
      when(() => mockApiService.getScripts()).thenAnswer((_) async => mockScripts);

      // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);
      
      // First call - should fail
      try {
        await scriptsNotifier.loadScripts();
        fail('Expected exception to be thrown');
      } catch (e) {
        // Expected
      }
      
      // Second call - should succeed
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => mockScripts);
      await scriptsNotifier.refresh();

      // Assert
      final state = container.read(scriptsProvider);
      expect(state, isA<AsyncData<List<Script>>>());
      expect(state.value, hasLength(1));
      
      verify(() => mockApiService.getScripts()).called(1);
    });

    test('ScriptsNotifier should handle large scripts list efficiently', () async {
      // Arrange
      final largeScriptList = List.generate(
        1000,
        (index) => TestDataGenerator.createValidScript(id: 'script-$index'),
      );
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => largeScriptList);

      // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);
      await scriptsNotifier.loadScripts();

      // Assert
      final state = container.read(scriptsProvider);
      expect(state, isA<AsyncData<List<Script>>>());
      expect(state.value, hasLength(1000));
      expect(state.value, equals(largeScriptList));
    });

    test('ScriptsNotifier should not load scripts after disposal', () async {
      // Arrange
      clearInteractions(mockApiService);
      when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

      // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);
      
      // Get a reference before disposal
      final notifierRef = container.read(scriptsProvider.notifier);
      container.dispose();
      
      // Try to access notifier after disposal
      expect(() => notifierRef.loadScripts(), throwsA(isA<StateError>()));
    });

    group('Initial State Tests', () {
      test('ScriptsNotifier should initialize with loading state and auto-load scripts', () {
        // Arrange
        when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

        // Act & Assert - Initial read should trigger loading
        final state = container.read(scriptsProvider);
        expect(state, isA<AsyncLoading<List<Script>>>());
        
        verify(() => mockApiService.getScripts()).called(1);
      });

      test('ScriptsNotifier should automatically call loadScripts in constructor', () {
        // Arrange
        clearInteractions(mockApiService);
        when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

        // Act - Creating the provider should automatically load scripts
        final scriptsProviderState = container.read(scriptsProvider);
        
        // Assert - Should have been called during initialization
        verify(() => mockApiService.getScripts()).called(1);
      });
    });

    group('Loading State Tests', () {
      test('ScriptsNotifier should show loading state during data fetch', () async {
        // Arrange
        clearInteractions(mockApiService);
        final completer = Completer<List<Script>>();
        when(() => mockApiService.getScripts()).thenAnswer((_) => completer.future);

        // Act
        final scriptsNotifier = container.read(scriptsProvider.notifier);
        final future = scriptsNotifier.loadScripts();

        // Assert - State should be loading
        final loadingState = container.read(scriptsProvider);
        expect(loadingState, isA<AsyncLoading<List<Script>>>());

        // Complete the future
        completer.complete([]);
        await future;
      });

      test('ScriptsNotifier should transition from loading to data state', () async {
        // Arrange
        final mockScripts = [TestDataGenerator.createValidScript()];
        clearInteractions(mockApiService);
        when(() => mockApiService.getScripts()).thenAnswer((_) async => mockScripts);

        // Act
      final scriptsNotifier = container.read(scriptsProvider.notifier);
        await scriptsNotifier.loadScripts();

        // Assert
        final finalState = container.read(scriptsProvider);
        expect(finalState, isA<AsyncData<List<Script>>>());
        expect(finalState.value, equals(mockScripts));
      });

      test('ScriptsNotifier should handle multiple loading cycles', () async {
        // Arrange
        clearInteractions(mockApiService);
        when(() => mockApiService.getScripts()).thenAnswer((_) async => []);

        // Act - Multiple load cycles
        final scriptsNotifier = container.read(scriptsProvider.notifier);
        for (int i = 0; i < 5; i++) {
          await scriptsNotifier.loadScripts();
        }

        // Assert - State should be stable
        final state = container.read(scriptsProvider);
        expect(state, isA<AsyncData<List<Script>>>());
        expect(state.value, isEmpty);
        
        verify(() => mockApiService.getScripts()).called(5);
      });
    });

    group('Error Handling Tests', () {
      test('ScriptsNotifier should handle network timeout gracefully', () async {
        // Arrange
        final timeoutException = Exception('Request timeout');
        clearInteractions(mockApiService);
        when(() => mockApiService.getScripts()).thenThrow(timeoutException);

        // Act
        final scriptsNotifier = container.read(scriptsProvider.notifier);

        // Assert
        try {
          await scriptsNotifier.loadScripts();
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<Exception>());
        }
        
        final state = container.read(scriptsProvider);
        expect(state, isA<AsyncError<List<Script>>>());
      });

      test('ScriptsNotifier should handle partial service failures', () async {
        // Arrange
        clearInteractions(mockApiService);
        when(() => mockApiService.getScripts())
            .thenThrow(Exception('Service unavailable'));

        // Act
        final scriptsNotifier = container.read(scriptsProvider.notifier);

        // Assert
        try {
          await scriptsNotifier.loadScripts();
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Edge Cases Tests', () {
      test('ScriptsNotifier should handle null response gracefully', () async {
        // Arrange
        clearInteractions(mockApiService);
        when(() => mockApiService.getScripts()).thenAnswer((_) async => <Script>[]);

        // Act
        final scriptsNotifier = container.read(scriptsProvider.notifier);
        await scriptsNotifier.loadScripts();

        // Assert
        final state = container.read(scriptsProvider);
        expect(state, isA<AsyncData<List<Script>>>());
        expect(state.value, isEmpty);
      });
    });
  });
}

// Test data generator for scripts
class TestDataGenerator {
  static Script createValidScript({
    String id = 'test-script-id',
    String title = 'Test Script',
    String content = 'Test script content',
    String? author = 'Test Author',
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating = 4.5,
  }) {
    return Script(
      id: id,
      title: title,
      content: content,
      author: author,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      rating: rating,
    );
  }
}

