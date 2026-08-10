import 'dart:async';

class Debouncer {
  Debouncer({this.milliseconds = 400});

  final int milliseconds;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() => _timer?.cancel();
}
