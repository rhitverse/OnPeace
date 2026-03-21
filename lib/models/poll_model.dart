class PollOption {
  final String id;
  final String text;
  final List<String> voterIds; // UIDs of users who voted for this option

  PollOption({required this.id, required this.text, this.voterIds = const []});

  int get voteCount => voterIds.length;

  PollOption copyWith({String? id, String? text, List<String>? voterIds}) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voterIds: voterIds ?? this.voterIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'voterIds': voterIds};
  }

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] as String,
      text: map['text'] as String,
      voterIds: List<String>.from(map['voterIds'] as List? ?? []),
    );
  }
}

class Poll {
  final String pollId;
  final String question;
  final List<PollOption> options;
  final String createdBy;
  final DateTime createdAt;
  final bool allowMultiple;
  final bool isAnonymous;
  final DateTime? expiresAt;

  Poll({
    required this.pollId,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdAt,
    this.allowMultiple = false,
    this.isAnonymous = false,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  int get totalVotes =>
      options.fold(0, (sum, option) => sum + option.voteCount);

  Poll copyWith({
    String? pollId,
    String? question,
    List<PollOption>? options,
    String? createdBy,
    DateTime? createdAt,
    bool? allowMultiple,
    bool? isAnonymous,
    DateTime? expiresAt,
  }) {
    return Poll(
      pollId: pollId ?? this.pollId,
      question: question ?? this.question,
      options: options ?? this.options,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pollId': pollId,
      'question': question,
      'options': options.map((o) => o.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'allowMultiple': allowMultiple,
      'isAnonymous': isAnonymous,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory Poll.fromMap(Map<String, dynamic> map) {
    return Poll(
      pollId: map['pollId'] as String,
      question: map['question'] as String,
      options: (map['options'] as List? ?? [])
          .map((o) => PollOption.fromMap(o as Map<String, dynamic>))
          .toList(),
      createdBy: map['createdBy'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      allowMultiple: map['allowMultiple'] as bool? ?? false,
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
    );
  }
}
