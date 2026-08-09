/// App-level user profile, mirrored between FirebaseAuth and Firestore
/// users/{uid}, plus locally-stored preferences.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final double defaultTargetPercentage;
  final bool notificationsEnabled;
  final bool darkModeEnabled;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.defaultTargetPercentage = 75.0,
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    double? defaultTargetPercentage,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      defaultTargetPercentage:
          defaultTargetPercentage ?? this.defaultTargetPercentage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'defaultTargetPercentage': defaultTargetPercentage,
        'notificationsEnabled': notificationsEnabled,
        'darkModeEnabled': darkModeEnabled,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        defaultTargetPercentage:
            (json['defaultTargetPercentage'] as num?)?.toDouble() ?? 75.0,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
      );
}
