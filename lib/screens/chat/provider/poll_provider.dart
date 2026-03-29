import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/models/poll_model.dart';

final activePollProvider =
    StateNotifierProvider<ActivePollNotifier, Map<String, Poll>>(
      (ref) => ActivePollNotifier(),
    );

class ActivePollNotifier extends StateNotifier<Map<String, Poll>> {
  ActivePollNotifier() : super({});

  /// Add or update a poll
  void addPoll(String pollId, Poll poll) {
    state = {...state, pollId: poll};
  }

  /// Vote on a poll option
  void votePoll({
    required String pollId,
    required String optionId,
    required String userId,
    bool remove = false,
  }) {
    final poll = state[pollId];
    if (poll == null) return;

    final updatedOptions = poll.options.map((option) {
      if (option.id == optionId) {
        final voters = <String>[...option.voterIds];
        if (remove) {
          voters.remove(userId);
        } else {
          if (!voters.contains(userId)) {
            voters.add(userId);
          }
        }
        return option.copyWith(voterIds: voters);
      }
      return option;
    }).toList();

    final updatedPoll = poll.copyWith(options: updatedOptions);
    addPoll(pollId, updatedPoll);
  }

  /// Remove a poll
  void removePoll(String pollId) {
    state = {...state}..remove(pollId);
  }

  /// Clear all polls
  void clearPolls() {
    state = {};
  }

  /// Get user's votes for a poll
  List<String> getUserVotes(String pollId, String userId) {
    final poll = state[pollId];
    if (poll == null) return [];

    return poll.options
        .where((option) => option.voterIds.contains(userId))
        .map((option) => option.id)
        .toList();
  }

  /// Check if user has voted
  bool hasUserVoted(String pollId, String userId) {
    final poll = state[pollId];
    if (poll == null) return false;

    return poll.options.any((option) => option.voterIds.contains(userId));
  }
}
