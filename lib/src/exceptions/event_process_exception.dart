class EventProcessingException implements Exception {
  final String message;
  final List<Object> errors;

  EventProcessingException(this.message, this.errors);

  @override
  String toString() => 'EventProcessingException: $message\nErrors: $errors';
}