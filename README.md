# Event Bus

A simple, flexible, and powerful event bus implementation for Dart, designed for decoupling different parts of an application in a clean, type-safe way.

## Features

- **Type-Safe:** Events are dispatched to listeners based on their specific type.
- **Asynchronous:** Core methods (`emit`, `on`, `once`) are asynchronous, ensuring non-blocking operations.
- **Prioritized Listeners:** Assign priorities to listeners to control their execution order. Listeners with higher priority are executed first.
- **Event Filtering:** Attach boolean filters to listeners to process only the events that meet specific criteria.
- **Subscription Management:** Easily manage listener lifecycles. The `on()` method returns a subscription object with a `cancel()` method, similar to Dart's `StreamSubscription`.
- **Lightweight and Simple:** No external dependencies and a minimal, easy-to-understand API.

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  git:
    url: https://github.com/dipflix/event_bus.git
```

Then, run `dart pub get` in your terminal.

## Usage

Here is a complete example demonstrating the main features of the package.

### 1. Define Your Events

Create classes that extend the base `Event` class.

```dart
import 'package:event_bus/event_bus.dart';

// An event for when a user logs in
final class UserLoggedInEvent extends Event {
  final String username;
  UserLoggedInEvent(this.username);
}

// An event for when an order is placed
final class OrderPlacedEvent extends Event {
  final String orderId;
  final double amount;
  OrderPlacedEvent(this.orderId, this.amount);
}
```

### 2. Initialize the EventBus

Create a single instance of `EventBus` and share it across your application.

```dart
final eventBus = EventBus();
```

### 3. Subscribe to and Emit Events

Use `on()` to subscribe to an event type and `emit()` to dispatch an event.

```dart
void main() async {
  // Subscribe to UserLoggedInEvent
  final subscription = eventBus.on<UserLoggedInEvent>((event) {
    print('Listener 1: User ${event.username} has logged in.');
  });

  // Emit an event
  await eventBus.emit(UserLoggedInEvent('Alice')); // "Listener 1: User Alice has logged in."

  // Cancel the subscription
  subscription.cancel();
  print('Listener 1 has unsubscribed.');

  // This event will not be caught by Listener 1
  await eventBus.emit(UserLoggedInEvent('Bob')); 
}
```

### 4. Advanced Usage: Priorities and Filters

Control the flow of events with priorities and filters.

```dart
// Priority: Higher numbers execute first
eventBus.on<UserLoggedInEvent>((event) {
  print('High priority listener (10)');
}, priority: 10);

eventBus.on<UserLoggedInEvent>((event) {
  print('Low priority listener (0)');
}, priority: 0);

await eventBus.emit(UserLoggedInEvent('Charlie'));
// Output:
// High priority listener (10)
// Low priority listener (0)


// Filter: Only listen to events that match the condition
eventBus.on<OrderPlacedEvent>(
  (event) {
    print('Received a large order: ${event.orderId}');
  },
  // Only process orders with an amount greater than 100
  filter: (event) => event.amount > 100,
);

await eventBus.emit(OrderPlacedEvent('order-1', 50.0));  // This is ignored
await eventBus.emit(OrderPlacedEvent('order-2', 150.0)); // This is processed
```

### 5. Clean Up

When the `EventBus` is no longer needed, call `dispose()` to release all resources and prevent memory leaks.

```dart
eventBus.dispose();
```

## Additional Information

- For more detailed examples, see the `example/` directory.
- To see how the package is tested, check the `test/` directory.
- Contributions are welcome! Please feel free to file an issue or submit a pull request.
