import 'package:d_event_bus/event_bus.dart';

final class UserLoggedInEvent extends Event {
  final String username;

  UserLoggedInEvent(this.username);

  @override
  String toString() {
    return 'UserLoggedInEvent(username: $username)';
  }
}

final class UserLoggedOutEvent extends Event {
  final String username;

  UserLoggedOutEvent(this.username);

  @override
  String toString() {
    return 'UserLoggedOutEvent(username: $username)';
  }
}

final class OrderPlacedEvent extends Event {
  final String orderId;
  final double amount;

  OrderPlacedEvent(this.orderId, this.amount);

  @override
  String toString() {
    return 'OrderPlacedEvent(orderId: $orderId, amount: $amount)';
  }
}

void main() async {
  final eventBus = EventBus();

  final subscription = eventBus.on<UserLoggedInEvent>((event) {
    print('Listener 1: User ${event.username} has logged in.');
  });

  await eventBus.emit(UserLoggedInEvent('Alice'));

  subscription.cancel();
  print('Listener 1 has unsubscribed.');

  await eventBus.emit(UserLoggedInEvent('Bob'));

  eventBus.on<UserLoggedInEvent>((event) {
    print('Listener with low priority (0): ${event.username}');
  }, priority: 0);

  eventBus.on<UserLoggedInEvent>((event) {
    print('Listener with high priority (10): ${event.username}');
  }, priority: 10);

  await eventBus.emit(UserLoggedInEvent('Charlie'));

  print('\n--- One-time subscription (once) ---');

  eventBus.once<UserLoggedOutEvent>((event) {
    print('One-time listener: ${event.username} has logged out.');
  });

  await eventBus.emit(UserLoggedOutEvent('Alice'));
  await eventBus.emit(UserLoggedOutEvent('Alice'));

  eventBus.on<OrderPlacedEvent>((event) {
    print('Received a large order: ${event.orderId} for the amount of ${event.amount}');
  }, filter: (event) => event.amount > 50);

  await eventBus.emit(OrderPlacedEvent('order-1', 30.0));
  await eventBus.emit(OrderPlacedEvent('order-2', 120.0));

  eventBus.dispose();

  try {
    await eventBus.emit(UserLoggedInEvent('Eve'));
  } catch (e) {
    print('Error emitting event: $e');
  }

  print('\nExample finished.');
}
