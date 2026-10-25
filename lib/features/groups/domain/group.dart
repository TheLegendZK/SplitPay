class Group {
  final String uid;
  final String name;
  final List<String> memberUids;
  final String creatorUid;
  final Map<String, int> memberShares; // uid -> share count (1 = solo, 2 = couple)

  Group({
    required this.uid,
    required this.name,
    required this.memberUids,
    required this.creatorUid,
    this.memberShares = const {},
  });

  int sharesFor(String uid) => memberShares[uid] ?? 1;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'memberUids': memberUids,
      'creatorUid': creatorUid,
      'memberShares': memberShares,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map, String docId) {
    final rawShares = map['memberShares'] as Map<String, dynamic>? ?? {};
    return Group(
      uid: docId,
      name: map['name'] as String? ?? '',
      memberUids: List<String>.from(map['memberUids'] ?? const []),
      creatorUid: map['creatorUid'] as String? ?? '',
      memberShares: rawShares.map(
            (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 1),
      ),
    );
  }
}
