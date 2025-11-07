class NormativeReference {
  final String title;
  final int page;
  final String paragraph;
  final String excerpt;

  const NormativeReference({
    required this.title,
    required this.page,
    required this.paragraph,
    required this.excerpt,
  });

  factory NormativeReference.fromJson(Map<String, dynamic> json) {
    return NormativeReference(
      title: json['title'] as String,
      page: json['page'] as int,
      paragraph: json['paragraph'] as String,
      excerpt: json['excerpt'] as String,
    );
  }
}
