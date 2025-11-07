enum DocumentType {
  script('script'),
  criteria('criteria');

  final String value;
  const DocumentType(this.value);

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.script,
    );
  }
}
