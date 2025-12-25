import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class RetailColors {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryAccent = Color(0xFF00D4FF);
  static const Color secondaryAccent = Color(0xFF10B981);
  static const Color successGreen = Color(0xFF34D399);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color inputBg = Color(0xFF0F172A);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  late final AnimationController _logoController;
  late final AnimationController _bgController;
  late final AnimationController _formController;

  late final Animation<double> _logoScale;
  late final Animation<double> _glowStrength;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _glowStrength = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _logoController.forward();
    _formController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bgController.dispose();
    _formController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _doLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email dan Password harus diisi"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.login(_emailController.text, _passController.text);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Login gagal: ${e.toString().replaceAll('Exception:', '')}",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return Scaffold(
          backgroundColor: RetailColors.primaryDark,
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      RetailColors.primaryDark,
                      RetailColors.primaryDark.withOpacity(0.95),
                      const Color(0xFF1a1a2e),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (_, __) {
                      return Opacity(
                        opacity: 0.20,
                        child: CustomPaint(
                          painter: _StatsPainter(progress: _bgController.value),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, _) {
                            final glow = 10 + 25 * _glowStrength.value;
                            return Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      RetailColors.primaryAccent.withOpacity(0.22),
                                      RetailColors.secondaryAccent.withOpacity(0.12),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: RetailColors.primaryAccent.withOpacity(0.35),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: RetailColors.primaryAccent.withOpacity(0.35),
                                      blurRadius: glow,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.bar_chart_rounded,
                                  size: 80,
                                  color: RetailColors.primaryAccent,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Welcome Back!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: RetailColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Silakan login untuk mengelola toko Anda",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: RetailColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 48),

                      FadeTransition(
                        opacity: _formController,
                        child: SlideTransition(
                          position: _formController.drive(
                            Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                                .chain(CurveTween(curve: Curves.easeOut)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: RetailColors.cardBg.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: RetailColors.primaryAccent.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: RetailColors.primaryAccent.withOpacity(0.1),
                                  blurRadius: 32,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildModernInput(
                                  controller: _emailController,
                                  label: "Email Address",
                                  icon: Icons.email_outlined,
                                  inputType: TextInputType.emailAddress,
                                  hintText: "admin@retailapp.com",
                                ),
                                const SizedBox(height: 20),
                                _buildModernInput(
                                  controller: _passController,
                                  label: "Password",
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  hintText: "Enter your password",
                                ),
                                const SizedBox(height: 28),
                                _buildLoginButton(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        "Retail Analytics v1.0.0",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: RetailColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: RetailColors.primaryAccent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _doLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: RetailColors.primaryAccent,
          foregroundColor: RetailColors.primaryDark,
          disabledBackgroundColor: RetailColors.primaryAccent.withOpacity(0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: RetailColors.primaryDark,
                ),
              )
            : Text(
                "LOGIN",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      keyboardType: inputType,
      style: GoogleFonts.poppins(
        color: RetailColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.poppins(
          color: RetailColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.poppins(
          color: RetailColors.textSecondary.withOpacity(0.6),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: RetailColors.primaryAccent,
          size: 20,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: RetailColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: RetailColors.inputBg.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: RetailColors.primaryAccent.withOpacity(0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: RetailColors.primaryAccent.withOpacity(0.15),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: RetailColors.primaryAccent,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _StatsPainter extends CustomPainter {
  final double progress;

  _StatsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgGrid = Paint()
      ..color = RetailColors.textSecondary.withOpacity(0.05)
      ..strokeWidth = 1;

    const gridStep = 56.0;
    for (double x = 0; x <= size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), bgGrid);
    }
    for (double y = 0; y <= size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bgGrid);
    }

    final bars = 18;
    final barWidth = size.width / (bars * 2);
    final barPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < bars; i++) {
      final phase = 2 * math.pi * (progress + i / bars);
      final hFactor = 0.25 + 0.65 * (0.5 + 0.5 * math.sin(phase));
      final barHeight = size.height * hFactor * 0.6;
      final x = i * (2 * barWidth) + barWidth * 0.5;
      final y = size.height - barHeight - 24;
      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(8),
      );

      final brightRed = const Color(0xFFFF1744);
      const brightGreen = Color(0xFF00E676);
      
      barPaint.color = Color.lerp(
            brightRed.withOpacity(0.7),
            brightGreen.withOpacity(0.7),
            hFactor,
          ) ??
          brightGreen.withOpacity(0.7);
      canvas.drawRRect(rRect, barPaint);
    }

    final path = Path();
    final points = 24;
    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final x = t * size.width;
      final wave = 0.5 + 0.4 * math.sin(2 * math.pi * (t + progress));
      final y = size.height * (0.55 - 0.25 * wave);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _StatsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
