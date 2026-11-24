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
  bool _isCovered = false;
  bool _isForeground = true;

  bool get isRunning => _timer != null;

  void start() {
    if (_isCovered) return;
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void setCovered(bool covered) {
    if (_isCovered == covered) return;
    _isCovered = covered;
    if (_isCovered) {
      stop();
    } else {
      if (_isForeground) {
        start();
        _tick();
      }
    }
  }

  void onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      if (!_isCovered) {
        start();
      }
    } else if (state == AppLifecycleState.inactive) {
      // Inactive (e.g. web lost window focus) does not stop polling
    } else {
      // hidden, paused, detached
      _isForeground = false;
      stop();
    }
  }

  Future<void> _tick() async {
    if (_isTicking) return;
    _isTicking = true;
    try {
      await onTick();
    } catch (e) {
      debugPrint('VisiblePoller: $e');
    } finally {
      _isTicking = false;
    }
  }
}
