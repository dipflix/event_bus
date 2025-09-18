abstract base class Event {
  final DateTime timestamp;
  final String eventId;

  Event({String? eventId})
    : timestamp = DateTime.now(),
      eventId = eventId ?? _generateEventId();

  static String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
  }

  static int _counter = 0;

  @override
  String toString() {
    return '$runtimeType(id: $eventId, timestamp: $timestamp)';
  }
}
