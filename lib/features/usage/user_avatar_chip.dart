import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import 'user_picker_screen.dart';

/// A compact chip widget that displays the active user's name.
///
/// Designed to be placed in the [MetronomeScreen] AppBar. Tapping
/// navigates to [UserPickerScreen] for user management.
class UserAvatarChip extends ConsumerWidget {
  const UserAvatarChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(usageTrackingStateProvider);

    return asyncState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _buildChip(
        context,
        label: '選擇使用者',
        initial: null,
      ),
      data: (state) {
        final activeUser = state.activeUser;
        return _buildChip(
          context,
          label: activeUser?.displayName ?? '選擇使用者',
          initial: activeUser?.displayName.isNotEmpty == true
              ? activeUser!.displayName.characters.first
              : null,
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required String? initial,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserPickerScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initial != null) ...[
              CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFFFF6B35),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              const Icon(
                Icons.person_outline,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
