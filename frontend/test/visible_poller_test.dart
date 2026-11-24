import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/utils/visible_poller.dart';

void main() {
  group('VisiblePoller', () {
    testWidgets('ticks every interval while resumed', (tester) async {
      var tickCount = 0;
      final poller = VisiblePoller(
        interval: const Duration(seconds: 20),
        onTick: () async {
          tickCount++;
        },
      );

      poller.start();
      await tester.pump(const Duration(seconds: 61));

      expect(tickCount, 3);
      poller.stop();
    });

    testWidgets('stops when paused and resumes', (tester) async {
      var tickCount = 0;
      final poller = VisiblePoller(
        interval: const Duration(seconds: 20),
        onTick: () async {
          tickCount++;
        },
      );

      poller.start();
      poller.onLifecycle(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 60));
      expect(tickCount, 0);

      poller.onLifecycle(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 21));
      expect(tickCount, 1);

      poller.stop();
    });

    testWidgets('skips overlapping ticks', (tester) async {
      var tickCount = 0;
      final completer = Completer<void>();
      final poller = VisiblePoller(
        interval: const Duration(seconds: 20),
        onTick: () {
          tickCount++;
          return completer.future;
        },
      );

      poller.start();
      await tester.pump(const Duration(seconds: 60));

      expect(tickCount, 1);
      poller.stop();
    });
  });
}
