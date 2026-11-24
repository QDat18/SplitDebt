import 'dart:async';
import 'package:flutter/widgets.dart';

class VisiblePoller {
  VisiblePoller({
    required this.interval,
    required this.onTick,
  });

  final Duration interval;
  final Future<void> Function() onTick;

  Timer? _timer;
  bool _isTicking = false;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      start();
    } else {
      stop();
    }
  }

  Future<void> _tick() async {
    if (_isTicking) return;
    _isTicking = true;
    try {
      await onTick();
    } finally {
      _isTicking = false;
    }
  }
}
