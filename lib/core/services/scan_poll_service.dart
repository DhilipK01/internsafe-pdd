import 'dart:async';

typedef PollFetch<T> = Future<T> Function();

/// Polls until [isDone] returns true or [timeout] elapses.
Future<T> pollUntilDone<T>({
  required PollFetch<T> fetch,
  required bool Function(T value) isDone,
  Duration interval = const Duration(seconds: 3),
  Duration timeout = const Duration(minutes: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final value = await fetch();
    if (isDone(value)) return value;
    await Future<void>.delayed(interval);
  }
  return fetch();
}
