import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.uid,
    required super.displayName,
    required super.email,
    super.photoUrl,
    super.phoneNumber,
    super.about,
    required super.lastSeen,
    super.isOnline,
    super.fcmToken,
    super.blockedUsers,
    super.privacySettings,
    super.isBusiness = false,
    super.isVerified = false,
    super.businessAddress,
    super.businessWebsite,
    super.businessHours,
    super.greetingMessage,
    super.awayMessage,
    super.ghostModeEnabled = false,
    super.isTemporary = false,
    super.expiresAt,
    super.isDecentralizedVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'about': about,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'fcmToken': fcmToken,
      'blockedUsers': blockedUsers,
      'privacySettings': privacySettings,
      'isBusiness': isBusiness,
      'isVerified': isVerified,
      'businessAddress': businessAddress,
      'businessWebsite': businessWebsite,
      'businessHours': businessHours,
      'greetingMessage': greetingMessage,
      'awayMessage': awayMessage,
      'ghostModeEnabled': ghostModeEnabled,
      'isTemporary': isTemporary,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'isDecentralizedVerified': isDecentralizedVerified,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      about: map['about'] ?? 'Hey there! I am using WhatsApp AI.',
      lastSeen: DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] ?? 0),
      isOnline: map['isOnline'] ?? false,
      fcmToken: map['fcmToken'],
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      privacySettings: Map<String, dynamic>.from(map['privacySettings'] ?? {}),
      isBusiness: map['isBusiness'] ?? false,
      isVerified: map['isVerified'] ?? false,
      businessAddress: map['businessAddress'],
      businessWebsite: map['businessWebsite'],
      businessHours: map['businessHours'] != null ? Map<String, String>.from(map['businessHours']) : null,
      greetingMessage: map['greetingMessage'],
      awayMessage: map['awayMessage'],
      ghostModeEnabled: map['ghostModeEnabled'] ?? false,
      isTemporary: map['isTemporary'] ?? false,
      expiresAt: map['expiresAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt']) : null,
      isDecentralizedVerified: map['isDecentralizedVerified'] ?? false,
    );
  }
}
