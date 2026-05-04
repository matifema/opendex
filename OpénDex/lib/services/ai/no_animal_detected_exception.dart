class NoAnimalDetectedException implements Exception {
  final String message;
  NoAnimalDetectedException([this.message = 'No animal detected in the photo. Please take a picture of a pet, wildlife, or any creature you\'d like to transform into a Pokemon!']);
  @override
  String toString() => message;
}
