import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../src/rust/api.dart';

class NodeState {
  final NodeStats? stats;
  final bool isRunning;
  final String? error;

  NodeState({this.stats, this.isRunning = false, this.error});

  NodeState copyWith({NodeStats? stats, bool? isRunning, String? error}) {
    return NodeState(
      stats: stats ?? this.stats,
      isRunning: isRunning ?? this.isRunning,
      error: error,
    );
  }
}

class NodeNotifier extends AsyncNotifier<NodeState> {
  Timer? _statsTimer;

  @override
  Future<NodeState> build() async {
    // Check if node is already running in the background (Rust side)
    final running = await isNodeRunning();
    if (running) {
      _startStatsPolling();
      // Fetch initial stats immediately if possible
      final stats = await getNodeStats();
      return NodeState(isRunning: true, stats: stats);
    }
    return NodeState(isRunning: false);
  }

  Future<void> start() async {
    state = const AsyncValue.loading();
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dataPath = '${directory.path}/bitcoin';

      // Ensure directory exists
      final dir = Directory(dataPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await startNodeService(
        dataDir: dataPath,
        network: 'signet', // Defaulting to signet for safety
      );

      state = AsyncValue.data(NodeState(isRunning: true));
      _startStatsPolling();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> stop() async {
    _statsTimer?.cancel();
    try {
      await stopNodeService();
      state = AsyncValue.data(NodeState(isRunning: false));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _startStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final stats = await getNodeStats();
        if (stats != null) {
          state = AsyncValue.data(
            state.value?.copyWith(stats: stats) ??
                NodeState(stats: stats, isRunning: true),
          );
        }
      } catch (e) {
        // Silently fail or use a proper logger in the future
      }
    });
  }
}

final nodeProvider = AsyncNotifierProvider<NodeNotifier, NodeState>(() {
  return NodeNotifier();
});
