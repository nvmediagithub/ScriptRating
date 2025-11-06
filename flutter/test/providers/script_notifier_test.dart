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
  group('ScriptNotifier', () {
    late ProviderContainer container;
    late MockApiService mockApiService;

    const String testScriptId = 'test-script-id';

    setUp(() {
      mockApiService = MockApiService();
      container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWith((ref) => mockApiService),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('ScriptNotifier should start with loading state for given scriptId', () {
      // Arrange
      final mockScript = TestDataGenerator.createValidScript(id: testScriptId);
      when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) async => mockScript);

      // Act
      final scriptProviderContainer = ProviderScope(
        parent: container,
        child: Consumer(
          builder: (context, ref, child) {
            return Container();
          },
        ),
      );
      
      // Create the family provider with scriptId
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );

      // Assert
      expect(scriptNotifier.debugState, isA<AsyncValue<Script?>>());
      expect(scriptNotifier.debugState, isA<AsyncLoading<Script?>>());
    });

    test('ScriptNotifier should load single script successfully', () async {
      // Arrange
      final mockScript = TestDataGenerator.createValidScript(id: testScriptId);
      when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) async => mockScript);

      // Act
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );
      await scriptNotifier.loadScript();

      // Assert
      final state = container.read(scriptProvider(testScriptId));
      expect(state, isA<AsyncData<Script?>>());
      expect(state.value, equals(mockScript));
      expect(state.value?.id, equals(testScriptId));
      
      verify(() => mockApiService.getScript(testScriptId)).called(1);
    });

    test('ScriptNotifier should handle script not found error', () async {
      // Arrange
      final notFoundException = Exception('Script not found');
      when(() => mockApiService.getScript(testScriptId)).thenThrow(notFoundException);

      // Act
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );

      // Assert
      expect(
        () => scriptNotifier.loadScript(),
        throwsA(isA<Exception>()),
      );
      
      final state = container.read(scriptProvider(testScriptId));
      expect(state, isA<AsyncError<Script?>>());
      
      verify(() => mockApiService.getScript(testScriptId)).called(1);
    });

    test('ScriptNotifier should return null for empty script response', () async {
      // Arrange
      when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) async => null);

      // Act
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );
      await scriptNotifier.loadScript();

      // Assert
      final state = container.read(scriptProvider(testScriptId));
      expect(state, isA<AsyncData<Script?>>());
      expect(state.value, isNull);
      
      verify(() => mockApiService.getScript(testScriptId)).called(1);
    });

    test('ScriptNotifier should handle refresh functionality', () async {
      // Arrange
      final initialScript = TestDataGenerator.createValidScript(id: testScriptId);
      when(() => mockApiService.getScript(testScriptId))
          .thenAnswer((_) async => initialScript);

      // Act - First load
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );
      await scriptNotifier.loadScript();
      
      // Update mock for refresh
      final updatedScript = TestDataGenerator.createValidScript(
        id: testScriptId,
        title: 'Updated Script',
        updatedAt: DateTime.now(),
      );
      when(() => mockApiService.getScript(testScriptId))
          .thenAnswer((_) async => updatedScript);
      
      await scriptNotifier.refresh();

      // Assert
      final state = container.read(scriptProvider(testScriptId));
      expect(state, isA<AsyncData<Script?>>());
      expect(state.value?.title, equals('Updated Script'));
      expect(state.value?.updatedAt, isNotNull);
      
      verify(() => mockApiService.getScript(testScriptId)).called(2);
    });

    test('ScriptNotifier should handle concurrent requests for different scripts', () async {
      // Arrange
      const scriptId1 = 'script-1';
      const scriptId2 = 'script-2';
      
      final script1 = TestDataGenerator.createValidScript(id: scriptId1);
      final script2 = TestDataGenerator.createValidScript(id: scriptId2);
      
      when(() => mockApiService.getScript(scriptId1)).thenAnswer((_) async => script1);
      when(() => mockApiService.getScript(scriptId2)).thenAnswer((_) async => script2);

      // Act - Load both scripts concurrently
      final scriptNotifier1 = container.read(
        scriptProvider(scriptId1).notifier,
      );
      final scriptNotifier2 = container.read(
        scriptProvider(scriptId2).notifier,
      );
      
      final load1 = scriptNotifier1.loadScript();
      final load2 = scriptNotifier2.loadScript();

      // Both should complete without error
      await expectLater(load1, completes);
      await expectLater(load2, completes);

      // Assert
      final state1 = container.read(scriptProvider(scriptId1));
      final state2 = container.read(scriptProvider(scriptId2));
      
      expect(state1.value?.id, equals(scriptId1));
      expect(state2.value?.id, equals(scriptId2));
      expect(state1.value, equals(script1));
      expect(state2.value, equals(script2));
    });

    test('ScriptNotifier should handle network timeout', () async {
      // Arrange
      final timeoutException = Exception('Request timeout');
      when(() => mockApiService.getScript(testScriptId)).thenThrow(timeoutException);

      // Act
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );

      // Assert
      expect(
        () => scriptNotifier.loadScript(),
        throwsA(isA<Exception>()),
      );
      
      final state = container.read(scriptProvider(testScriptId));
      expect(state, isA<AsyncError<Script?>>());
    });

    test('ScriptNotifier should maintain scriptId consistency', () async {
      // Arrange
      final mockScript = TestDataGenerator.createValidScript(id: testScriptId);
      when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) async => mockScript);

      // Act
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );
      await scriptNotifier.loadScript();

      // Assert - Verify that the correct scriptId was used
      verify(() => mockApiService.getScript(testScriptId)).called(1);
      
      final state = container.read(scriptProvider(testScriptId));
      expect(state.value?.id, equals(testScriptId));
    });

    test('ScriptNotifier should handle different scriptId values independently', () async {
      // Arrange
      const scriptId1 = 'script-1';
      const scriptId2 = 'script-2';
      const scriptId3 = 'script-3';
      
      final script1 = TestDataGenerator.createValidScript(id: scriptId1);
      final script2 = TestDataGenerator.createValidScript(id: scriptId2);
      final script3 = TestDataGenerator.createValidScript(id: scriptId3);
      
      when(() => mockApiService.getScript(scriptId1)).thenAnswer((_) async => script1);
      when(() => mockApiService.getScript(scriptId2)).thenAnswer((_) async => script2);
      when(() => mockApiService.getScript(scriptId3)).thenAnswer((_) async => script3);

      // Act - Load all three scripts
      final notifier1 = container.read(scriptProvider(scriptId1).notifier);
      final notifier2 = container.read(scriptProvider(scriptId2).notifier);
      final notifier3 = container.read(scriptProvider(scriptId3).notifier);
      
      await Future.wait([
        notifier1.loadScript(),
        notifier2.loadScript(),
        notifier3.loadScript(),
      ]);

      // Assert - Each should be independent
      expect(container.read(scriptProvider(scriptId1)).value?.id, equals(scriptId1));
      expect(container.read(scriptProvider(scriptId2)).value?.id, equals(scriptId2));
      expect(container.read(scriptProvider(scriptId3)).value?.id, equals(scriptId3));
      
      verify(() => mockApiService.getScript(scriptId1)).called(1);
      verify(() => mockApiService.getScript(scriptId2)).called(1);
      verify(() => mockApiService.getScript(scriptId3)).called(1);
    });

    test('ScriptNotifier should handle error recovery correctly', () async {
      // Arrange
      final mockScript = TestDataGenerator.createValidScript(id: testScriptId);
      when(() => mockApiService.getScript(testScriptId))
          .thenThrow(Exception('Network error'))
          .thenAnswer((_) async => mockScript);

      // Act
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );
      
      // First call - should fail
      try {
        await scriptNotifier.loadScript();
      } catch (e) {
        // Expected
      }
      
      // Second call - should succeed
      await scriptNotifier.refresh();

      // Assert
      final state = container.read(scriptProvider(testScriptId));
      expect(state, isA<AsyncData<Script?>>());
      expect(state.value, equals(mockScript));
      
      verify(() => mockApiService.getScript(testScriptId)).called(2);
    });

    test('ScriptNotifier should handle partial script data', () async {
      // Arrange
      final partialScript = TestDataGenerator.createValidScript(
        id: testScriptId,
        title: 'Partial Script',
        content: 'Content only',
        author: null,
        rating: null,
      );
      when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) async => partialScript);

      // Act
      final scriptNotifier = container.read(
        scriptProvider(testScriptId).notifier,
      );
      await scriptNotifier.loadScript();

      // Assert
      final state = container.read(scriptProvider(testScriptId));
      expect(state, isA<AsyncData<Script?>>());
      expect(state.value?.id, equals(testScriptId));
      expect(state.value?.title, equals('Partial Script'));
      expect(state.value?.author, isNull);
      expect(state.value?.rating, isNull);
    });

    group('Family Provider Tests', () {
      test('scriptProvider.family should create different instances for different scriptIds', () {
        // Arrange
        const scriptId1 = 'script-1';
        const scriptId2 = 'script-2';

        // Act - Create providers with different scriptIds
        final provider1 = scriptProvider(scriptId1);
        final provider2 = scriptProvider(scriptId2);

        // Assert - Should be different providers
        expect(provider1, isNot(equals(provider2)));
        expect(provider1.runtimeType, equals(provider2.runtimeType));
      });

      test('scriptProvider.family should maintain scriptId correctly', () {
        // Arrange & Act
        final scriptNotifier = container.read(
          scriptProvider(testScriptId).notifier,
        );

        // Assert - Notifier should be aware of scriptId
        expect(scriptNotifier, isA<ScriptNotifier>());
      });

      test('Multiple family instances should be independent', () async {
        // Arrange
        const scriptId1 = 'script-1';
        const scriptId2 = 'script-2';
        
        final script1 = TestDataGenerator.createValidScript(id: scriptId1);
        final script2 = TestDataGenerator.createValidScript(id: scriptId2);
        
        when(() => mockApiService.getScript(scriptId1)).thenAnswer((_) async => script1);
        when(() => mockApiService.getScript(scriptId2)).thenAnswer((_) async => script2);

        // Act - Load both scripts
        await container.read(scriptProvider(scriptId1).notifier).loadScript();
        await container.read(scriptProvider(scriptId2).notifier).loadScript();

        // Assert - States should be independent
        final state1 = container.read(scriptProvider(scriptId1));
        final state2 = container.read(scriptProvider(scriptId2));
        
        expect(state1.value, equals(script1));
        expect(state2.value, equals(script2));
        expect(state1, isNot(equals(state2)));
      });
    });

    group('Initial State Tests', () {
      test('ScriptNotifier should initialize with loading state and auto-load script', () async {
        // Arrange
        final mockScript = TestDataGenerator.createValidScript(id: testScriptId);
        when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) async => mockScript);

        // Act & Assert - Initial read should trigger loading
        final state = container.read(scriptProvider(testScriptId));
        expect(state, isA<AsyncLoading<Script?>>());
        
        // Wait for auto-load to complete
        await Future.delayed(const Duration(milliseconds: 100));
        
        verify(() => mockApiService.getScript(testScriptId)).called(1);
      });

      test('ScriptNotifier should automatically call loadScript in constructor', () async {
        // Arrange
        final mockScript = TestDataGenerator.createValidScript(id: testScriptId);
        when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) async => mockScript);

        // Act - Creating the provider should automatically load script
        final scriptProvider = container.read(this.scriptProvider(testScriptId));
        
        // Assert - Should have been called during initialization
        verify(() => mockApiService.getScript(testScriptId)).called(1);
      });
    });

    group('State Transition Tests', () {
      test('ScriptNotifier should transition from loading to data state', () async {
        // Arrange
        final mockScript = TestDataGenerator.createValidScript(id: testScriptId);
        when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) async => mockScript);

        // Act
        final scriptNotifier = container.read(
          scriptProvider(testScriptId).notifier,
        );
        await scriptNotifier.loadScript();

        // Assert
        final finalState = container.read(scriptProvider(testScriptId));
        expect(finalState, isA<AsyncData<Script?>>());
        expect(finalState.value, equals(mockScript));
      });

      test('ScriptNotifier should handle loading state during async operations', () async {
        // Arrange
        final completer = Completer<Script>();
        when(() => mockApiService.getScript(testScriptId)).thenAnswer((_) => completer.future);

        // Act
        final scriptNotifier = container.read(
          scriptProvider(testScriptId).notifier,
        );
        final future = scriptNotifier.loadScript();

        // Assert - State should be loading
        final loadingState = container.read(scriptProvider(testScriptId));
        expect(loadingState, isA<AsyncLoading<Script?>>());

        // Complete the future
        completer.complete(TestDataGenerator.createValidScript(id: testScriptId));
        await future;
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

