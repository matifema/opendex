class HumanDetectedException implements Exception {
  final String message;
  HumanDetectedException([this.message = 'Human detected! Only pets are allowed.']);
  @override
  String toString() => message;
}
