enum AgeRating {
  zeroPlus('0+'),
  sixPlus('6+'),
  twelvePlus('12+'),
  sixteenPlus('16+'),
  eighteenPlus('18+');

  const AgeRating(this.value);
  final String value;
}
