import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/local_user.dart';
import '../../core/providers/providers.dart';

class UserPickerScreen extends ConsumerStatefulWidget {
  const UserPickerScreen({super.key});

  @override
  ConsumerState<UserPickerScreen> createState() => _UserPickerScreenState();
}

class _UserPickerScreenState extends ConsumerState<UserPickerScreen> {
  @override
  Widget build(BuildContext context) {
    final service = ref.watch(usageTrackingServiceProvider);
    final asyncState = ref.watch(usageTrackingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('使用者管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: const Color(0xFFFF6B35),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Builder(
        builder: (context) {
          final state = asyncState.valueOrNull ?? service.state;
          final users = state.users;
          final activeUserId = state.activeUser?.id;

          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    '尚無使用者',
                    style: TextStyle(fontSize: 18, color: Colors.white54),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '點擊右下角按鈕新增使用者',
                    style: TextStyle(fontSize: 14, color: Colors.white38),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isActive = user.id == activeUserId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Dismissible(
                  key: ValueKey(user.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _showDeleteConfirmation(context, user),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    service.deleteUser(user.id);
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isActive
                          ? const BorderSide(color: Color(0xFFFF6B35), width: 2)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        service.switchUser(user.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isActive
                                  ? const Color(0xFFFF6B35)
                                  : const Color(0xFF1A1A2E),
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName.characters.first
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '上次活躍: ${_formatTimeAgo(user.lastActiveAt)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFFF6B35),
                                size: 28,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    LocalUser user,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3460),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('刪除使用者', style: TextStyle(color: Colors.white)),
        content: Text(
          '確定要刪除 ${user.displayName} 嗎？所有使用紀錄將一併刪除',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade300),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showAddUserDialog(BuildContext context) {
    final controller = TextEditingController();
    final service = ref.read(usageTrackingServiceProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F3460),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('新增使用者', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '輸入顯示名稱',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF6B35)),
            ),
          ),
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isNotEmpty) {
              service.createUser(name);
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                service.createUser(name);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return '剛剛';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分鐘前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小時前';
    } else if (diff.inDays < 30) {
      return '${diff.inDays} 天前';
    } else {
      final months = (diff.inDays / 30).floor();
      return '$months 個月前';
    }
  }
}
