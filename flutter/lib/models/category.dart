enum Category {
  violence('violence'),
  sexualContent('sexual_content'),
  language('language'),
  alcoholDrugs('alcohol_drugs'),
  disturbingScenes('disturbing_scenes');

  const Category(this.value);
  final String value;
}