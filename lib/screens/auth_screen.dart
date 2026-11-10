import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../services/sync_service.dart';
import '../widgets/ambient_background.dart';
import '../widgets/glass_container.dart';

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
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _hoverAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _hoverAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
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
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
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
    final textCol = isDark ? Colors.white : Colors.black;
    final subTextCol = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final toggleBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
          style: TextStyle(color: textCol, fontWeight: FontWeight.bold),
        ),
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcoming MBD Character with Entrance & Hover Animation
                    Center(
                      child: SlideTransition(
                        position: _slideAnim,
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
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Subtle ambient neon glow behind the character matching its green accents
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF22C55E).withAlpha(isDark ? 45 : 30),
                                        blurRadius: 50,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                // MBD Character Image
                                Image.asset(
                                  'assets/mbd_character.png',
                                  height: 160,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      'كريدي',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'قم بإنشاء حساب أو تسجيل الدخول لحفظ ومزامنة كافة بياناتك وإعداداتك بأمان.',
                      style: TextStyle(fontSize: 13, color: subTextCol, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Toggle Segment: Login / Register
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
                                      ? (isDark ? const Color(0xFF3F3F46) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_isRegister
                                      ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !_isRegister ? FontWeight.bold : FontWeight.w500,
                                    color: textCol,
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
                                      ? (isDark ? const Color(0xFF3F3F46) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _isRegister
                                      ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'حساب جديد',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _isRegister ? FontWeight.bold : FontWeight.w500,
                                    color: textCol,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input Form
                    GlassContainer(
                      borderRadius: BorderRadius.circular(22),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          // Avatar Selection (Only when registering)
                          if (_isRegister) ...[
                            Column(
                              children: [
                                Text(
                                  'اختر شخصيتك الرمزية (البروفايل)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textCol,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 62,
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
                                          width: 58,
                                          height: 58,
                                          padding: const EdgeInsets.all(2.5),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                              width: 2.5,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF2563EB).withAlpha(80),
                                                      blurRadius: 8,
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
                              ],
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'الاسم أو اللقب',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال اسمك';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
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

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
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
                                  padding: const EdgeInsets.only(top: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'نسيت كلمة المرور؟',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : Text(
                              _isRegister ? 'إنشاء حساب ومزامنة البيانات' : 'تسجيل الدخول والمزامنة',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'أو',
                            style: TextStyle(color: subTextCol, fontSize: 13),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Continue as guest button
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
                        'مواصلة كضيف (المتابعة بالوضع المحلي)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textCol,
                        side: BorderSide(
                          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D5DB),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

