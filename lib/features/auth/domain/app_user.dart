class AppUser {
  const AppUser({
    required this.uid,
    required this.phoneNumber,
    this.displayName,
  });

  final String uid;
  final String phoneNumber;
  final String? displayName;

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'phoneNumber': phoneNumber, 'displayName': displayName};
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      displayName: map['displayName'] as String?,
    );
  }
}
