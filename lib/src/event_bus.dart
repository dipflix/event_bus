import 'dart:async';

import 'event.dart';
import 'event_bus_types.dart';
import 'event_middleware.dart';
import 'event_subscription.dart';
import 'exceptions/event_process_exception.dart';

class _EventListenerWrapper<T extends Event> {
  final String id;
  final EventListener<T> listener;
  final EventFilter<T>? filter;
  final int priority;
  final bool once;

  bool _hasExecuted = false;

  _EventListenerWrapper({
    required this.id,
    required this.listener,
    this.filter,
    this.priority = 0,
    this.once = false,
  });

  bool get shouldRemove => once && _hasExecuted;

  bool canHandle(T event) {
    if (shouldRemove) {
      return false;
    }
    return filter?.call(event) ?? true;
  }

  Future<void> handle(T event) async {
    if (!canHandle(event)) {
      return;
    }

    try {
      await listener(event);
      _hasExecuted = true;
    } catch (e) {
      rethrow;
    }
  }
}

base class EventBus {
  final Map<Type, List<_EventListenerWrapper>> _listeners = {};
  final StreamController<Event> _eventStream = StreamController.broadcast();
  final List<EventMiddleware> _middlewares = [];

  bool _isDisposed = false;
  int _listenerIdCounter = 0;

  Stream<Event> get eventStream => _eventStream.stream;

  EventSubscription on<T extends Event>(
    EventListener<T> listener, {
    EventFilter<T>? filter,
    int priority = 0,
  }) {
    _checkDisposed();

    final id = 'listener_${++_listenerIdCounter}';
    final wrapper = _EventListenerWrapper<T>(
      id: id,
      listener: listener,
      filter: filter,
      priority: priority,
    );

    _listeners.putIfAbsent(T, () => []).add(wrapper);
    _sortListenersByPriority(T);

    return EventSubscription(id, () => _removeListener<T>(id));
  }

  EventSubscription once<T extends Event>(
    EventListener<T> listener, {
    EventFilter<T>? filter,
    int priority = 0,
  }) {
    _checkDisposed();

    final id = 'listener_${++_listenerIdCounter}';
    final wrapper = _EventListenerWrapper<T>(
      id: id,
      listener: listener,
      filter: filter,
      priority: priority,
      once: true,
    );

    _listeners.putIfAbsent(T, () => []).add(wrapper);
    _sortListenersByPriority(T);

    return EventSubscription(id, () => _removeListener<T>(id));
  }

  Future<void> emit<T extends Event>(T event) async {
    _checkDisposed();

    dynamic processedEvent = event;
    for (final middleware in _middlewares) {
      processedEvent = await middleware.process(processedEvent);
      if (processedEvent == null) {
        return;
      }
    }

    _eventStream.add(processedEvent);

    await _processListeners<T>(processedEvent);

    if (T != Event) {
      await _processListeners<Event>(processedEvent);
    }
  }

  void emitSync<T extends Event>(T event) {
    emit(event);
  }

  Future<void> emitBatch(List<Event> events) async {
    for (final event in events) {
      await emit(event);
    }
  }

  void removeAllListeners<T extends Event>() {
    _listeners.remove(T);
  }

  void addMiddleware(EventMiddleware middleware) {
    _middlewares.add(middleware);
  }

  void removeMiddleware(EventMiddleware middleware) {
    _middlewares.remove(middleware);
  }

  bool hasListeners<T extends Event>() {
    return _listeners[T]?.isNotEmpty ?? false;
  }

  int getListenerCount<T extends Event>() {
    return _listeners[T]?.length ?? 0;
  }

  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};

    _listeners.forEach((type, listeners) {
      stats[type.toString()] = {
        'count': listeners.length,
        'active': listeners.where((l) => !l.shouldRemove).length,
      };
    });

    return {
      'listeners': stats,
      'middlewares': _middlewares.length,
      'isDisposed': _isDisposed,
    };
  }

  void clear() {
    _listeners.clear();
    _middlewares.clear();
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }

    clear();
    _eventStream.close();
    _isDisposed = true;
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError('EventBus has been disposed');
    }
  }

  Future<void> _processListeners<T extends Event>(T event) async {
    final listeners = _listeners[T];
    if (listeners == null || listeners.isEmpty) {
      return;
    }

    final errors = <Object>[];
    final toRemove = <_EventListenerWrapper>[];

    for (final listener in List.from(listeners)) {
      try {
        await listener.handle(event);

        if (listener.shouldRemove) {
          toRemove.add(listener);
        }
      } catch (e) {
        errors.add(e);
      }
    }

    for (final listener in toRemove) {
      listeners.remove(listener);
    }

    if (errors.isNotEmpty) {
      throw EventProcessingException(
        'Errors occurred while processing event $event',
        errors,
      );
    }
  }

  void _removeListener<T extends Event>(String id) {
    final listeners = _listeners[T];
    if (listeners != null) {
      listeners.removeWhere((l) => l.id == id);
      if (listeners.isEmpty) {
        _listeners.remove(T);
      }
    }
  }

  void _sortListenersByPriority(Type eventType) {
    final listeners = _listeners[eventType];
    if (listeners != null) {
      listeners.sort((a, b) => b.priority.compareTo(a.priority));
    }
  }
}
