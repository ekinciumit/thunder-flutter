import 'package:flutter/material.dart';

class MessageReactions extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionTap;

  const MessageReactions({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Tepkileri grupla ve say
    final Map<String, List<String>> groupedReactions = {};
    for (final entry in reactions.entries) {
      for (final emoji in entry.value) {
        if (groupedReactions[emoji] == null) {
          groupedReactions[emoji] = [];
        }
        groupedReactions[emoji]!.add(entry.key);
      }
    }

    if (groupedReactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final userIds = entry.value;
          final count = userIds.length;
          final hasCurrentUser = userIds.contains(currentUserId);

          return GestureDetector(
            onTap: () => onReactionTap(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasCurrentUser 
                    ? Colors.deepPurple.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasCurrentUser 
                      ? Colors.deepPurple.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (count > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasCurrentUser 
                            ? Colors.deepPurple[700]
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}



