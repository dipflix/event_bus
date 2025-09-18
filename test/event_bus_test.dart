import 'package:event_bus/event_bus.dart';
import 'package:test/test.dart';

final class TestEvent extends Event {}

final class AnotherTestEvent extends Event {
  final int value;
  AnotherTestEvent(this.value);
}

void main() {
  group('EventBus', () {
    late EventBus eventBus;

    setUp(() {
      eventBus = EventBus();
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('should deliver an event to a subscriber', () async {
      var eventReceived = false;
      eventBus.on<TestEvent>((event) {
        eventReceived = true;
      });

      await eventBus.emit(TestEvent());

      expect(eventReceived, isTrue, reason: 'Event should be received by the subscriber.');
    });

    test('should not deliver an event after unsubscribing', () async {
      var callCount = 0;
      final subscription = eventBus.on<TestEvent>((event) {
        callCount++;
      });

      await eventBus.emit(TestEvent());
      expect(callCount, 1, reason: 'Listener should be called once before unsubscribing.');

      subscription.cancel();
      await eventBus.emit(TestEvent());
      expect(callCount, 1, reason: 'Listener should not be called after unsubscribing.');
    });

    test('should call listeners in priority order', () async {
      final callOrder = <int>[];
      eventBus.on<TestEvent>((event) {
        callOrder.add(1);
      }, priority: 0);

      eventBus.on<TestEvent>((event) {
        callOrder.add(2);
      }, priority: 10);

      eventBus.on<TestEvent>((event) {
        callOrder.add(3);
      }, priority: 5);

      await eventBus.emit(TestEvent());

      expect(callOrder, equals([2, 3, 1]), reason: 'Listeners should be called in priority order.');
    });

    test('once() should only receive an event once', () async {
      var callCount = 0;
      eventBus.once<TestEvent>((event) {
        callCount++;
      });

      await eventBus.emit(TestEvent());
      await eventBus.emit(TestEvent());

      expect(callCount, 1, reason: 'once() listener should be called only one time.');
    });

    test('should filter events based on the provided filter function', () async {
      var receivedValue = -1;
      eventBus.on<AnotherTestEvent>(
        (event) {
          receivedValue = event.value;
        },
        filter: (event) => event.value > 10,
      );

      await eventBus.emit(AnotherTestEvent(5));
      expect(receivedValue, -1, reason: 'Event with value 5 should be filtered out.');

      await eventBus.emit(AnotherTestEvent(15));
      expect(receivedValue, 15, reason: 'Event with value 15 should be received.');
    });

    test('should not receive events after dispose() is called', () async {
      var eventReceived = false;
      eventBus.on<TestEvent>((event) {
        eventReceived = true;
      });

      eventBus.dispose();

      expect(
        () async => await eventBus.emit(TestEvent()),
        throwsA(isA<StateError>()),
        reason: 'Emitting on a disposed event bus should throw a StateError.',
      );

      expect(eventReceived, isFalse, reason: 'No event should be received after dispose.');
    });

    test('emit() should complete even if there are no listeners', () async {
      await expectLater(eventBus.emit(TestEvent()), completes);
    });

    test('should handle multiple different event types', () async {
      var testEventReceived = false;
      var anotherTestEventReceived = false;

      eventBus.on<TestEvent>((event) {
        testEventReceived = true;
      });
      eventBus.on<AnotherTestEvent>((event) {
        anotherTestEventReceived = true;
      });

      await eventBus.emit(TestEvent());
      await eventBus.emit(AnotherTestEvent(1));

      expect(testEventReceived, isTrue, reason: 'TestEvent should be received.');
      expect(anotherTestEventReceived, isTrue, reason: 'AnotherTestEvent should be received.');
    });
  });
}
