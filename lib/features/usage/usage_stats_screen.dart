import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/midi/midi_service.dart';
import '../../core/providers/providers.dart';
import 'user_picker_screen.dart';

class UsageStatsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const UsageStatsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<UsageStatsScreen> createState() => _UsageStatsScreenState();
}

class _UsageStatsScreenState extends ConsumerState<UsageStatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(usageTrackingServiceProvider);
    final asyncState = ref.watch(usageTrackingStateProvider);
    final state = asyncState.valueOrNull ?? service.state;

    final activeUser = state.activeUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(activeUser != null
            ? '${activeUser.displayName} 的統計'
            : '統計'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6B35),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: '使用時間'),
            Tab(text: 'MIDI 練習'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          activeUser != null
              ? _UsageTimeTab(userId: activeUser.id)
              : const _NoUserPlaceholder(),
          activeUser != null
              ? _MidiPracticeTab(userId: activeUser.id)
              : const _MidiNoUserTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 1: 使用時間 (existing functionality)
// =============================================================================

class _UsageTimeTab extends ConsumerWidget {
  final String userId;
  const _UsageTimeTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(usageRepositoryProvider);

    final totalSeconds = repository.totalSecondsForUser(userId);
    final dailyTotals = repository.dailyTotalsForUser(userId);

    final sortedDays = dailyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (sortedDays.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              '尚無使用紀錄',
              style: TextStyle(fontSize: 18, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        _SummaryCard(
          icon: Icons.timer,
          iconColor: const Color(0xFFFF6B35),
          label: '總使用時間',
          value: _formatDuration(totalSeconds),
        ),
        const SizedBox(height: 16),
        // Export button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('匯出 JSON'),
            onPressed: () => _exportUsageJson(context, repository),
          ),
        ),
        const SizedBox(height: 8),
        // Daily stats header
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '每日統計',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
        ),
        // Daily records
        ...sortedDays.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(entry.key),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatDuration(entry.value),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFB347),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _exportUsageJson(
      BuildContext context, dynamic repository) async {
    try {
      final json = repository.exportJson();
      if (!context.mounted) return;

      await Clipboard.setData(ClipboardData(text: json));
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已複製 JSON 資料到剪貼簿'),
          backgroundColor: const Color(0xFF0F3460),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F3460),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title:
              const Text('匯出失敗', style: TextStyle(color: Colors.white)),
          content: Text(
            '無法匯出資料: $e',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('確定'),
            ),
          ],
        ),
      );
    }
  }
}

// =============================================================================
// Tab 2: MIDI 練習
// =============================================================================

class _MidiPracticeTab extends ConsumerWidget {
  final String userId;
  const _MidiPracticeTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practiceRepo = ref.watch(practiceRepositoryProvider);
    final practiceService = ref.watch(practiceTrackingServiceProvider);
    final asyncState = ref.watch(practiceTrackingStateProvider);
    final state = asyncState.valueOrNull ?? practiceService.state;

    // If MIDI is unsupported, show message
    if (state.connectionState == MidiConnectionState.unsupported) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              '此瀏覽器不支援 Web MIDI',
              style: TextStyle(fontSize: 18, color: Colors.white54),
            ),
            SizedBox(height: 8),
            Text(
              '請使用 Chrome 或 Edge 瀏覽器',
              style: TextStyle(fontSize: 14, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    final totalSeconds = practiceRepo.totalSecondsForUser(userId);
    final dailyTotals = practiceRepo.dailyTotalsForUser(userId);

    final sortedDays = dailyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection status
        _MidiConnectionStatus(state: state),
        const SizedBox(height: 16),
        // Summary card
        _SummaryCard(
          icon: Icons.piano,
          iconColor: const Color(0xFF7C4DFF),
          label: '總練習時間',
          value: _formatDuration(totalSeconds),
        ),
        // Currently playing indicator
        if (state.isPlaying && state.currentSession != null) ...[
          const SizedBox(height: 12),
          _LiveSessionCard(
            startAt: state.currentSession!.startAt,
            totalPreviousSeconds: totalSeconds,
          ),
        ],
        const SizedBox(height: 16),
        // Export button
        if (sortedDays.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('匯出 JSON'),
              onPressed: () =>
                  _exportPracticeJson(context, practiceRepo),
            ),
          ),
        if (sortedDays.isNotEmpty) const SizedBox(height: 8),
        // Daily stats
        if (sortedDays.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '每日練習統計',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
          ),
          ...sortedDays.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(entry.key),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _formatDuration(entry.value),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB388FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ] else if (!state.isPlaying) ...[
          const SizedBox(height: 32),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.piano, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  '尚無練習紀錄',
                  style: TextStyle(fontSize: 18, color: Colors.white54),
                ),
                SizedBox(height: 8),
                Text(
                  '連接 MIDI 鍵盤開始練習',
                  style: TextStyle(fontSize: 14, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _exportPracticeJson(
      BuildContext context, dynamic repository) async {
    try {
      final json = repository.exportJson();
      if (!context.mounted) return;

      await Clipboard.setData(ClipboardData(text: json));
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已複製練習資料 JSON 到剪貼簿'),
          backgroundColor: const Color(0xFF0F3460),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F3460),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title:
              const Text('匯出失敗', style: TextStyle(color: Colors.white)),
          content: Text(
            '無法匯出資料: $e',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('確定'),
            ),
          ],
        ),
      );
    }
  }
}

// =============================================================================
// No-user placeholders
// =============================================================================

class _NoUserPlaceholder extends StatelessWidget {
  const _NoUserPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            '請先選擇使用者',
            style: TextStyle(fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('選擇使用者'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserPickerScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MidiNoUserTab extends ConsumerWidget {
  const _MidiNoUserTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practiceService = ref.watch(practiceTrackingServiceProvider);
    final asyncState = ref.watch(practiceTrackingStateProvider);
    final state = asyncState.valueOrNull ?? practiceService.state;

    if (state.connectionState == MidiConnectionState.unsupported) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              '此瀏覽器不支援 Web MIDI',
              style: TextStyle(fontSize: 18, color: Colors.white54),
            ),
            SizedBox(height: 8),
            Text(
              '請使用 Chrome 或 Edge 瀏覽器',
              style: TextStyle(fontSize: 14, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MidiConnectionStatus(state: state),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              const Text(
                '請先選擇使用者以開始記錄練習',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('選擇使用者'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserPickerScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

class _LiveSessionCard extends StatefulWidget {
  final DateTime startAt;
  final int totalPreviousSeconds;
  const _LiveSessionCard({
    required this.startAt,
    required this.totalPreviousSeconds,
  });

  @override
  State<_LiveSessionCard> createState() => _LiveSessionCardState();
}

class _LiveSessionCardState extends State<_LiveSessionCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTotal() {
    final currentSessionSec = DateTime.now().difference(widget.startAt).inSeconds;
    final total = widget.totalPreviousSeconds + currentSessionSec;
    return _formatDuration(total);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF7C4DFF),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF7C4DFF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '練習中 — 總計 ${_formatTotal()}',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MidiConnectionStatus extends StatelessWidget {
  final dynamic state;
  const _MidiConnectionStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final connectionState =
        state.connectionState as MidiConnectionState;
    final devices = state.connectedDevices as List<String>;

    Color dotColor;
    String label;

    switch (connectionState) {
      case MidiConnectionState.connected:
        dotColor = const Color(0xFF66BB6A);
        label = devices.isNotEmpty
            ? '已連接: ${devices.join(', ')}'
            : '已連接';
        break;
      case MidiConnectionState.disconnected:
        dotColor = Colors.white38;
        label = '未偵測到 MIDI 裝置';
        break;
      case MidiConnectionState.permissionDenied:
        dotColor = const Color(0xFFEF5350);
        label = 'MIDI 權限被拒絕';
        break;
      case MidiConnectionState.unsupported:
        dotColor = Colors.white24;
        label = '不支援 Web MIDI';
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

/// Formats a date string (yyyy-MM-dd) into display format (yyyy/MM/dd).
String _formatDate(String isoDate) {
  return isoDate.replaceAll('-', '/');
}

/// Formats a duration given in total seconds into a human-readable
/// Traditional Chinese string.
String _formatDuration(int totalSeconds) {
  if (totalSeconds < 60) {
    return '$totalSeconds 秒';
  }

  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;

  if (hours > 0) {
    return '$hours 小時 $minutes 分鐘';
  }
  return '$minutes 分鐘';
}
