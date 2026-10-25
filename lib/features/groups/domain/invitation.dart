class Invitation {
  final String id;
  final String groupId;
  final String groupName;
  final String invitedUid;
  final String inviterUid;
  final String status; // 'pending', 'accepted', 'declined'

  Invitation({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.invitedUid,
    required this.inviterUid,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'invitedUid': invitedUid,
      'inviterUid': inviterUid,
      'status': status,
    };
  }

  factory Invitation.fromMap(Map<String, dynamic> map, String docId) {
    return Invitation(
      id: docId,
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      invitedUid: map['invitedUid'] ?? '',
      inviterUid: map['inviterUid'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}
