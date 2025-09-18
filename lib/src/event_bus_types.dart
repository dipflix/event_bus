import 'dart:async';

import 'event.dart';

typedef EventListener<T extends Event> = FutureOr<void> Function(T event);
typedef EventFilter<T extends Event> = bool Function(T event);
