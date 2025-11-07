/// LLM Provider enum matching FastAPI LLMProvider
enum LLMProvider {
  local('local'),
  openrouter('openrouter');

  const LLMProvider(this.value);
  final String value;

  static LLMProvider fromString(String value) {
    return LLMProvider.values.firstWhere(
      (provider) => provider.value == value,
      orElse: () => throw ArgumentError('Invalid LLMProvider: $value'),
    );
  }
}
