import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../services/sync_service.dart';
import '../widgets/ambient_background.dart';

class AuthScreen extends StatefulWidget {
  final bool isModal;
  final VoidCallback? onContinueAsGuest;

  const AuthScreen({
    super.key,
    this.isModal = false,
    this.onContinueAsGuest,
  });

  static Future<bool?> show(BuildContext context) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen(isModal: true)),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedAvatar = AvatarService.defaultAvatar;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late final AnimationController _entranceController;
  late final AnimationController _hoverController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _characterSlideAnim;
  late final Animation<Offset> _cardSlideAnim;
  late final Animation<double> _hoverAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );
    _characterSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.05, 1.0, curve: Curves.easeOutBack),
    ));
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
    ));

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _hoverAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entranceController.forward().then((_) {
      if (mounted) {
        _hoverController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _hoverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (_isRegister) {
        await AuthService.instance.registerWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
          photoURL: _selectedAvatar,
        );
        // Upload initial local data to newly registered account
        await SyncService.instance.uploadToCloud();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب وربطه بنجاح! ☁️'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        await AuthService.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // Download user cloud data
        await SyncService.instance.downloadFromCloud();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الدخول ومزامنة البيانات بنجاح! ✓'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }

      if (mounted) {
        if (widget.isModal) {
          navigator.pop(true);
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('استعادة كلمة المرور', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني المسجل وسنرسل لك رابطاً لإعادة تعيين كلمة المرور:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await AuthService.instance.sendPasswordResetEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني ✓'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('إرسال الرابط'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final toggleBg = isDark ? const Color(0xFF1F2528) : const Color(0xFFF1F5F9);

    final size = MediaQuery.of(context).size;
    final cardWidth = (size.width - 32.0).clamp(320.0, 460.0);
    final characterWidth = (cardWidth * 0.74).clamp(240.0, 310.0);
    // Aspect ratio of our cropped PNG: 880w x 778h -> 778 / 880 = 0.8841
    final characterHeight = characterWidth * (778.0 / 880.0);
    // In the 778h image, chest cut line is at 717px (717 / 778 = 0.9216)
    final chestY = characterHeight * 0.9216;
    final cardTopOffset = chestY - 4.0;
    final characterLeft = (cardWidth - characterWidth) / 2.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0F10) : const Color(0xFFF8FAFC),
      body: AmbientBackground(
        child: Stack(
          children: [
            // Main Scrollable Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Layer 1: Ambient Neon Green Glow behind Character Head
                        Positioned(
                          top: 20,
                          left: characterLeft + (characterWidth - (characterWidth * 0.65)) / 2,
                          child: Container(
                            width: characterWidth * 0.65,
                            height: characterWidth * 0.65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withAlpha(isDark ? 60 : 35),
                                  blurRadius: 65,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Layer 2: Character Body (behind the Login Card)
                        Positioned(
                          top: 0,
                          left: characterLeft,
                          width: characterWidth,
                          height: characterHeight,
                          child: SlideTransition(
                            position: _characterSlideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: AnimatedBuilder(
                                animation: _hoverAnim,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _hoverAnim.value),
                                    child: child,
                                  );
                                },
                                child: Image.asset(
                                  'assets/mbd_peek.png',
                                  width: characterWidth,
                                  height: characterHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Layer 3: The Login / Registration Card (middle layer)
                        Padding(
                          padding: EdgeInsets.only(top: cardTopOffset),
                          child: SlideTransition(
                            position: _cardSlideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildAuthCard(context, isDark, textCol, subTextCol, toggleBg),
                            ),
                          ),
                        ),

                        // Layer 4: Character Hand Overlay (IN FRONT of the Card)
                        Positioned(
                          top: 0,
                          left: characterLeft,
                          width: characterWidth,
                          height: characterHeight,
                          child: IgnorePointer(
                            child: SlideTransition(
                              position: _characterSlideAnim,
                              child: FadeTransition(
                                opacity: _fadeAnim,
                                child: AnimatedBuilder(
                                  animation: _hoverAnim,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _hoverAnim.value),
                                      child: child,
                                    );
                                  },
                                  child: Image.asset(
                                    'assets/mbd_hand.png',
                                    width: characterWidth,
                                    height: characterHeight,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Modal Close Button
            if (widget.isModal)
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2427) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF2E383C) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 50 : 20),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(Icons.close_rounded, size: 20, color: textCol),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard(
    BuildContext context,
    bool isDark,
    Color textCol,
    Color subTextCol,
    Color toggleBg,
  ) {
    final cardBg = isDark ? const Color(0xFF14181A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF22C55E).withAlpha(55) : const Color(0xFF22C55E).withAlpha(70);
    final inputBg = isDark ? const Color(0xFF1B2023) : const Color(0xFFF8FAFC);
    final inputBorder = isDark ? const Color(0xFF2A3337) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withAlpha(isDark ? 25 : 15),
            blurRadius: 36,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 180 : 35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Badge & Header
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF22C55E).withAlpha(80), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF22C55E)),
                    const SizedBox(width: 5),
                    Text(
                      'كريدي',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isRegister ? 'إنشاء حساب جديد' : 'أهلاً بك مجدداً 👋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textCol,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _isRegister
                  ? 'سجّل حسابك لمزامنة مصاريفك وبياناتك سحابياً بأمان تام'
                  : 'سجّل الدخول للوصول إلى كافة معاملاتك وإعداداتك المحفوظة',
              style: TextStyle(
                fontSize: 13,
                color: subTextCol,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            // Tabs: Login / Register
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: toggleBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isRegister = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isRegister
                              ? (isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: !_isRegister
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF22C55E).withAlpha(80),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                            : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: !_isRegister ? Colors.white : subTextCol,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isRegister = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isRegister
                              ? (isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _isRegister
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF22C55E).withAlpha(80),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                            : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isRegister ? Colors.white : subTextCol,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Avatar picker (Registration only)
            if (_isRegister) ...[
              Text(
                'اختر شخصيتك الرمزية (البروفايل)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AvatarService.avatars.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final avatar = AvatarService.avatars[index];
                    final isSelected = avatar == _selectedAvatar;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = avatar),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withAlpha(90),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                        ),
                        child: ClipOval(
                          child: Image.asset(avatar, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              // Name Field
              _buildInputField(
                controller: _nameController,
                label: 'الاسم أو اللقب',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                inputBg: inputBg,
                inputBorder: inputBorder,
                textCol: textCol,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال اسمك';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],

            // Email Field
            _buildInputField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              inputBg: inputBg,
              inputBorder: inputBorder,
              textCol: textCol,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'يرجى إدخال البريد الإلكتروني';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'يرجى إدخال بريد إلكتروني صالح';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password Field
            _buildInputField(
              controller: _passwordController,
              label: 'كلمة المرور',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              inputBg: inputBg,
              inputBorder: inputBorder,
              textCol: textCol,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: subTextCol,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'يرجى إدخال كلمة المرور';
                }
                if (val.length < 6) {
                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                }
                return null;
              },
            ),

            // Forgot Password
            if (!_isRegister) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),

            // Main Submit Button
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withAlpha(90),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _submit,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isRegister ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isRegister ? 'إنشاء حساب ومزامنة البيانات' : 'تسجيل الدخول والمزامنة',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: isDark ? const Color(0xFF262C30) : const Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('أو', style: TextStyle(color: subTextCol, fontSize: 13)),
                ),
                Expanded(child: Divider(color: isDark ? const Color(0xFF262C30) : const Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 16),

            // Continue as Guest Button
            OutlinedButton.icon(
              onPressed: () {
                if (widget.isModal) {
                  Navigator.pop(context);
                } else {
                  widget.onContinueAsGuest?.call();
                }
              },
              icon: const Icon(Icons.person_outline_rounded, size: 20),
              label: const Text(
                'مواصلة كضيف (الوضع المحلي)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textCol,
                side: BorderSide(
                  color: isDark ? const Color(0xFF2A3337) : const Color(0xFFCBD5E1),
                  width: 1.3,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color inputBg,
    required Color inputBorder,
    required Color textCol,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(color: textCol, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
        ),
      ),
    );
  }
}
