class EventSubscription {
  final String _id;
  final void Function() _unsubscribe;
  bool _isActive = true;

  EventSubscription(this._id, this._unsubscribe);

  String get id => _id;

  bool get isActive => _isActive;

  void cancel() {
    if (_isActive) {
      _unsubscribe();
      _isActive = false;
    }
  }
}
