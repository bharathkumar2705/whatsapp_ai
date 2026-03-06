class UserEntity {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String phoneNumber;
  final String about;
  final DateTime lastSeen;
  final bool isOnline;
  final String? fcmToken;
  final List<String> blockedUsers;
  final Map<String, dynamic> privacySettings;

  // Business Fields
  final bool isBusiness;
  final bool isVerified;
  final String? businessAddress;
  final String? businessWebsite;
  final Map<String, String>? businessHours;
  final String? greetingMessage;
  final String? awayMessage;
  final bool ghostModeEnabled;
  final bool isTemporary;
  final DateTime? expiresAt;
  final bool isDecentralizedVerified;

  UserEntity({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl = '',
    this.phoneNumber = '',
    this.about = 'Hey there! I am using WhatsApp AI.',
    required this.lastSeen,
    this.isOnline = false,
    this.fcmToken,
    this.blockedUsers = const [],
    this.privacySettings = const {
      'lastSeen': 'Everyone',
      'profilePhoto': 'Everyone',
      'appLock': false,
    },
    this.isBusiness = false,
    this.isVerified = false,
    this.businessAddress,
    this.businessWebsite,
    this.businessHours,
    this.greetingMessage,
    this.awayMessage,
    this.ghostModeEnabled = false,
    this.isTemporary = false,
    this.expiresAt,
    this.isDecentralizedVerified = false,
  });
}
