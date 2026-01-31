import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/node_provider.dart';
import '../../src/rust/api.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  bool _isPeersExpanded = false;

  @override
  Widget build(BuildContext context) {
    final nodeAsync = ref.watch(nodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network & Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Optionally force refresh stats
            },
          ),
        ],
      ),
      body: nodeAsync.when(
        data: (state) => _buildContent(context, ref, state),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, NodeState state) {
    final stats = state.stats;
    final isRunning = state.isRunning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node Status Card
          _buildStatusCard(ref, state),
          const SizedBox(height: 24),

          // Statistics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatItem(
                'Peers',
                stats?.peersCount.toString() ?? '0',
                Icons.people_outline,
              ),
              _buildStatItem(
                'Height',
                stats?.blocks.toString() ?? '...',
                Icons.layers_outlined,
              ),
              _buildStatItem(
                'Uptime',
                _formatUptime(stats?.uptimeSecs.toInt() ?? 0),
                Icons.timer_outlined,
              ),
              _buildStatItem(
                'Headers',
                stats?.headers.toString() ?? '...',
                Icons.hub_outlined,
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            'Node Version',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stats?.userAgent ?? (isRunning ? 'Fetching...' : 'Not Running'),
            style: const TextStyle(
              color: Colors.white54,
              fontFamily: 'Berkeley Mono',
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              setState(() {
                _isPeersExpanded = !_isPeersExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.transparent,
              child: Row(
                children: [
                  const Text(
                    'Connected Peers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (stats?.peersCount != null &&
                      stats!.peersCount > BigInt.zero)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        stats.peersCount.toString(),
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isPeersExpanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Peer List with Animation
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildPeerList(isRunning ? stats?.peers : null),
            crossFadeState: _isPeersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    if (seconds == 0) return '0s';
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${seconds % 60}s';
  }

  Widget _buildStatusCard(WidgetRef ref, NodeState state) {
    final isRunning = state.isRunning;
    final inIbd = state.stats?.inIbd ?? false;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isRunning ? AppTheme.primaryGreen : Colors.red)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRunning ? Icons.check_circle_outline : Icons.error_outline,
              color: isRunning ? AppTheme.primaryGreen : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRunning ? 'Node Running' : 'Node Stopped',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                isRunning
                    ? (inIbd ? 'Initial Block Download...' : 'Synced')
                    : 'Turn on to start sync',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          Switch(
            value: isRunning,
            onChanged: (val) {
              if (val) {
                ref.read(nodeProvider.notifier).start();
              } else {
                ref.read(nodeProvider.notifier).stop();
              }
            },
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.secondaryGreen, size: 24),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerList(List<PeerDetailedInfo>? peers) {
    if (peers == null || peers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.people_outline, color: Colors.white24, size: 48),
            SizedBox(height: 16),
            Text('No peers connected', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: peers.length,
      itemBuilder: (context, index) {
        final peer = peers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.dns_outlined, color: Colors.white54, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.address,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Berkeley Mono',
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      peer.userAgent,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: peer.isInbound
                                ? Colors.blueAccent
                                : AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${peer.isInbound ? 'Inbound' : 'Outbound'} • Height: ${peer.height}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryGreen,
                size: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}
