import '../../event_bus.dart';

class EventValidationException implements Exception {
  final String message;
  final Event event;

  EventValidationException(this.message, this.event);

  @override
  String toString() => 'EventValidationException: $message\nEvent: $event';
}
