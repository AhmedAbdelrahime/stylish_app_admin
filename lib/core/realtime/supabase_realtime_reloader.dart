import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

typedef SupabaseRealtimeReload = Future<void> Function();

class SupabaseRealtimeReloader {
  SupabaseRealtimeReloader({
    required SupabaseClient supabase,
    required String channelName,
    required Iterable<String> tables,
    required SupabaseRealtimeReload onReload,
    this.debounce = const Duration(milliseconds: 450),
  }) : _supabase = supabase,
       _onReload = onReload,
       _channel = supabase.channel(channelName) {
    for (final table in tables.toSet()) {
      _channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _scheduleReload(),
      );
    }

    _channel.subscribe((status, [_]) {
      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        _scheduleReload();
      }
    });
  }

  final SupabaseClient _supabase;
  final SupabaseRealtimeReload _onReload;
  final Duration debounce;
  final RealtimeChannel _channel;

  Timer? _debounceTimer;
  bool _isReloading = false;
  bool _hasQueuedReload = false;
  bool _isDisposed = false;

  void triggerReload() => _scheduleReload();

  void _scheduleReload() {
    if (_isDisposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _runReload);
  }

  void _runReload() {
    if (_isDisposed) return;

    if (_isReloading) {
      _hasQueuedReload = true;
      return;
    }

    _isReloading = true;
    Future<void>(() async {
      try {
        await _onReload();
      } finally {
        _isReloading = false;
        if (_hasQueuedReload && !_isDisposed) {
          _hasQueuedReload = false;
          _scheduleReload();
        }
      }
    });
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _hasQueuedReload = false;
    _isReloading = false;
    Future<void>(() async {
      await _supabase.removeChannel(_channel);
    });
  }
}
