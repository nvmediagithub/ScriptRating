import 'package:json_annotation/json_annotation.dart';

part 'severity.g.dart';

@JsonEnum(alwaysCreate: true)
enum Severity {
  @JsonValue('none') none('none'),
  @JsonValue('mild') mild('mild'),
  @JsonValue('moderate') moderate('moderate'),
  @JsonValue('severe') severe('severe');

  const Severity(this.value);
  final String value;
}
