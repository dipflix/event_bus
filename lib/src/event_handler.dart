import 'dart:async';

import 'event.dart';

abstract base class EventHandler<T extends Event> {
  FutureOr<void> handle(T event);
}
