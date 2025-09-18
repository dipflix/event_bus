import 'dart:async';

import 'event.dart';


abstract base class EventMiddleware {
  FutureOr<Event?> process(Event event);
}
