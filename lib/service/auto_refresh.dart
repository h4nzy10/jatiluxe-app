import 'dart:async';

import 'package:flutter/widgets.dart';

/// Polls a screen's data source while the page is active and the app is in the
/// foreground. The backend has no push channel, so this keeps lists close to
/// live database changes without showing a loading spinner on every tick.
mixin AutoRefresh<T extends StatefulWidget> on State<T> {
  Duration get autoRefreshInterval => const Duration(seconds: 15);

  /// Override in pages hosted by an IndexedStack so only the visible tab polls.
  bool get autoRefreshEnabled => true;

  Timer? _autoRefreshTimer;

  void startAutoRefresh(VoidCallback onRefresh) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (_) {
      if (!mounted || !autoRefreshEnabled) return;
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      onRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
