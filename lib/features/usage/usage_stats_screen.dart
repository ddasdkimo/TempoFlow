import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';

class UsageStatsScreen extends ConsumerStatefulWidget {
  const UsageStatsScreen({super.key});

  @override
  ConsumerState<UsageStatsScreen> createState() => _UsageStatsScreenState();
}

class _UsageStatsScreenState extends ConsumerState<UsageStatsScreen> {
  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(usageRepositoryProvider);
    final asyncState = ref.watch(usageTrackingStateProvider);

    return asyncState.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('使用統計'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          title: const Text('使用統計'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text('載入失敗: $err', style: const TextStyle(color: Colors.white70)),
        ),
      ),
      data: (state) {
        final activeUser = state.activeUser;
        if (activeUser == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('使用統計'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: const Center(
              child: Text(
                '請先選擇使用者',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            ),
          );
        }

        final totalSeconds = repository.totalSecondsForUser(activeUser.id);
        final dailyTotals = repository.dailyTotalsForUser(activeUser.id);

        // Sort by date descending (most recent first)
        final sortedDays = dailyTotals.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        return Scaffold(
          appBar: AppBar(
            title: Text('${activeUser.displayName} 的使用統計'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: '匯出 JSON',
                onPressed: () => _exportJson(context, repository),
              ),
            ],
          ),
          body: sortedDays.isEmpty
              ? const Center(
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
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary card
                    Card(
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
                                color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.timer,
                                color: Color(0xFFFF6B35),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '總使用時間',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDuration(totalSeconds),
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
                    ),
                    const SizedBox(height: 24),
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
                      final date = entry.key;
                      final seconds = entry.value;
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
                                  _formatDate(date),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _formatDuration(seconds),
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
                ),
        );
      },
    );
  }

  Future<void> _exportJson(BuildContext context, dynamic repository) async {
    try {
      final json = await repository.exportJson();
      if (!context.mounted) return;

      await Clipboard.setData(ClipboardData(text: json));
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已複製 JSON 資料到剪貼簿'),
          backgroundColor: const Color(0xFF0F3460),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F3460),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('匯出失敗', style: TextStyle(color: Colors.white)),
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

  /// Formats a date string (yyyy-MM-dd) into display format (yyyy/MM/dd).
  String _formatDate(String isoDate) {
    return isoDate.replaceAll('-', '/');
  }
}

/// Formats a duration given in total seconds into a human-readable
/// Traditional Chinese string.
///
/// Returns:
/// - "X 小時 Y 分鐘" if >= 1 hour
/// - "Y 分鐘" if >= 1 minute but < 1 hour
/// - "X 秒" if < 1 minute
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
