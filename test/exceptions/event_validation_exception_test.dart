import 'package:event_bus/event_bus.dart';
import 'package:event_bus/src/exceptions/event_validation_exception.dart';
import 'package:test/test.dart';

final class TestEvent extends Event {}

void main() {
  group('EventValidationException', () {
    final testEvent = TestEvent();
    const testMessage = 'Invalid event data';

    test('should correctly assign message and event properties', () {
      final exception = EventValidationException(testMessage, testEvent);

      expect(exception.message, equals(testMessage));
      expect(exception.event, equals(testEvent));
    });

    test('toString() should return a correctly formatted string', () {
      final exception = EventValidationException(testMessage, testEvent);

      final expectedString =
          'EventValidationException: $testMessage\nEvent: $testEvent';

      expect(exception.toString(), equals(expectedString));
    });
  });
}
