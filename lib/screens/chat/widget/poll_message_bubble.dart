import 'package:flutter/material.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/models/poll_model.dart';

class PollMessageBubble extends StatelessWidget {
  final Poll poll;
  final String currentUserId;
  final String time;
  final bool isMe;
  final bool showTail;
  final bool isGrouped;
  final bool showTime;
  final VoidCallback? onVote;

  const PollMessageBubble({
    super.key,
    required this.poll,
    required this.currentUserId,
    required this.time,
    required this.isMe,
    this.showTail = true,
    this.isGrouped = false,
    this.showTime = true,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.totalVotes;
    final userVotes = poll.options
        .where((o) => o.voterIds.contains(currentUserId))
        .map((o) => o.id)
        .toList();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isGrouped ? 3 : 8, horizontal: 1),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? senderMessageColor : receiverMessageColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Poll question
                    Text(
                      poll.question,
                      style: const TextStyle(
                        color: whiteColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (poll.allowMultiple || poll.isAnonymous) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (poll.allowMultiple)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Multiple votes',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (poll.isAnonymous) ...[
                            if (poll.allowMultiple) const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Anonymous',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Poll options
                    ...poll.options.asMap().entries.map((entry) {
                      final option = entry.value;
                      final isSelected = userVotes.contains(option.id);
                      final percentage = totalVotes > 0
                          ? (option.voteCount / totalVotes) * 100
                          : 0.0;

                      return GestureDetector(
                        onTap: poll.isExpired
                            ? null
                            : () {
                                onVote?.call();
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Stack(
                            children: [
                              // Background bar
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? uiColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              // Vote percentage bar
                              if (percentage > 0)
                                Container(
                                  height: 36,
                                  width:
                                      (percentage / 100) *
                                      (MediaQuery.of(context).size.width *
                                              0.70 -
                                          36),
                                  decoration: BoxDecoration(
                                    color: uiColor.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              // Text and vote count
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option.text,
                                          style: const TextStyle(
                                            color: whiteColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: whiteColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    // Total votes info
                    Text(
                      poll.isExpired
                          ? 'Poll ended'
                          : '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (showTime)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                  child: Text(
                    time,
                    style: const TextStyle(color: whiteColor, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
