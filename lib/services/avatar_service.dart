class AvatarService {
  AvatarService._();

  static const List<String> avatars = [
    'avatars/avatar_1.jpg',
    'avatars/avatar_2.jpg',
    'avatars/avatar_3.jpg',
    'avatars/avatar_4.jpg',
    'avatars/avatar_5.jpg',
    'avatars/avatar_6.jpg',
    'avatars/avatar_7.jpg',
    'avatars/avatar_8.jpg',
    'avatars/avatar_9.jpg',
    'avatars/avatar_10.jpg',
  ];

  static String get defaultAvatar => avatars[0];

  static bool isValidAvatar(String? path) {
    if (path == null) return false;
    return avatars.contains(path);
  }
}

