import 'package:flutter/material.dart';
import '../services/avatar_service.dart';
import 'bouncing_button.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.size = 40,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatarImage();

    Widget content = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: avatar,
            ),
          ),
          if (showEditBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: size * 0.18,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return BouncingButton(
        onTap: onTap,
        scaleFactor: 0.94,
        child: content,
      );
    }

    return content;
  }

  Widget _buildAvatarImage() {
    if (photoUrl != null && photoUrl!.isNotEmpty && photoUrl!.startsWith('avatars/')) {
      return Image.asset(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final initial = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : 'U';

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Helper to show a modern, animated bottom sheet to select from the 10 avatars
  static Future<String?> showAvatarPicker(
    BuildContext context, {
    String? currentAvatar,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(120),
      builder: (ctx) => _AvatarPickerModal(selectedAvatar: currentAvatar),
    );
  }
}

class _AvatarPickerModal extends StatefulWidget {
  final String? selectedAvatar;

  const _AvatarPickerModal({this.selectedAvatar});

  @override
  State<_AvatarPickerModal> createState() => _AvatarPickerModalState();
}

class _AvatarPickerModalState extends State<_AvatarPickerModal> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedAvatar ?? AvatarService.defaultAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: borderCol, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'اختر شخصيتك الرمزية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر الصورة التي تعبّر عنك لتمثيل حسابك في التطبيق',
              style: TextStyle(fontSize: 12, color: subTextCol),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Grid of 10 avatars
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AvatarService.avatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final avatarPath = AvatarService.avatars[index];
                final isSelected = avatarPath == _selected;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = avatarPath);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withAlpha(80),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        avatarPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 22),

            // Confirm selection button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_selected);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'تأكيد الاختيار',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
