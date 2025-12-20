import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Retail Analytics Color Scheme
class RetailColorsSplash {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryAccent = Color(0xFF00D4FF);
  static const Color secondaryAccent = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _chartController;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoPosition;
  late Animation<double> _glowStrength;
  late Animation<int> _textCharCount;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _logoScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoPosition = Tween(begin: const Offset(0, 0.4), end: const Offset(0, 0)).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _glowStrength = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    final appName = "Retail Analytics";
    _textCharCount = StepTween(begin: 0, end: appName.length).animate(
      CurvedAnimation(parent: _textController, curve: Curves.linear),
    );

    _logoController.forward();
    _progressController.forward();
    _chartController.forward();

    // Start text animation after logo completes
    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _textController.forward();
      }
    });

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 5));

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const MainLayout() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetailColorsSplash.primaryDark,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  RetailColorsSplash.primaryDark,
                  RetailColorsSplash.primaryDark.withOpacity(0.95),
                  const Color(0xFF1a1a2e),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Animated candlestick chart background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _chartController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _CandlestickPainter(progress: _chartController.value),
                );
              },
            ),
          ),

          // Main content
          Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // Animated logo with position movement
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, _) {
                  final glow = 10 + 25 * _glowStrength.value;
                  return Transform.translate(
                    offset: _logoPosition.value * 100,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              RetailColorsSplash.primaryAccent.withOpacity(0.22),
                              RetailColorsSplash.secondaryAccent.withOpacity(0.12),
                            ],
                          ),
                          border: Border.all(
                            color: RetailColorsSplash.primaryAccent.withOpacity(0.35),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: RetailColorsSplash.primaryAccent.withOpacity(0.4),
                              blurRadius: glow,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          size: 90,
                          color: RetailColorsSplash.primaryAccent,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // App Title with typing animation
              AnimatedBuilder(
                animation: _textCharCount,
                builder: (context, _) {
                  final appName = "Retail Analytics";
                  final displayText = appName.substring(0, _textCharCount.value.toInt());
                  return Text(
                    displayText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: RetailColorsSplash.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

// Candlestick chart painter for animated background
class _CandlestickPainter extends CustomPainter {
  final double progress; // 0..1

  _CandlestickPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Define chart path data with more realistic price movements
    final List<Map<String, double>> candles = [
      {'open': 0.48, 'high': 0.52, 'low': 0.45, 'close': 0.47}, // Red with long wicks
      {'open': 0.47, 'high': 0.48, 'low': 0.40, 'close': 0.42}, // Very long red
      {'open': 0.42, 'high': 0.45, 'low': 0.38, 'close': 0.43}, // Long green with lower wick
      {'open': 0.43, 'high': 0.46, 'low': 0.41, 'close': 0.45}, // Green
      {'open': 0.45, 'high': 0.47, 'low': 0.44, 'close': 0.46}, // Small green
      {'open': 0.46, 'high': 0.48, 'low': 0.45, 'close': 0.47}, // Small green
      {'open': 0.47, 'high': 0.49, 'low': 0.46, 'close': 0.48}, // Green
      {'open': 0.48, 'high': 0.54, 'low': 0.47, 'close': 0.53}, // Very long green
      {'open': 0.53, 'high': 0.56, 'low': 0.52, 'close': 0.54}, // Green
      {'open': 0.54, 'high': 0.60, 'low': 0.53, 'close': 0.58}, // Very long green
      {'open': 0.58, 'high': 0.61, 'low': 0.57, 'close': 0.60}, // Green
      {'open': 0.60, 'high': 0.65, 'low': 0.55, 'close': 0.56}, // Long red with huge wick
      {'open': 0.56, 'high': 0.60, 'low': 0.52, 'close': 0.54}, // Red
      {'open': 0.54, 'high': 0.56, 'low': 0.53, 'close': 0.55}, // Small green
      {'open': 0.55, 'high': 0.57, 'low': 0.54, 'close': 0.56}, // Small green
      {'open': 0.56, 'high': 0.58, 'low': 0.55, 'close': 0.57}, // Small green
      {'open': 0.57, 'high': 0.61, 'low': 0.56, 'close': 0.60}, // Long green
      {'open': 0.60, 'high': 0.62, 'low': 0.59, 'close': 0.61}, // Small green
      {'open': 0.61, 'high': 0.63, 'low': 0.60, 'close': 0.62}, // Small green
      {'open': 0.62, 'high': 0.67, 'low': 0.61, 'close': 0.66}, // Long green
      {'open': 0.66, 'high': 0.70, 'low': 0.63, 'close': 0.64}, // Red with long upper wick
      {'open': 0.64, 'high': 0.66, 'low': 0.58, 'close': 0.60}, // Long red
      {'open': 0.60, 'high': 0.62, 'low': 0.56, 'close': 0.58}, // Red
      {'open': 0.58, 'high': 0.60, 'low': 0.55, 'close': 0.57}, // Red
      {'open': 0.57, 'high': 0.59, 'low': 0.56, 'close': 0.58}, // Small green
      {'open': 0.58, 'high': 0.59, 'low': 0.55, 'close': 0.56}, // Red with lower wick
      {'open': 0.56, 'high': 0.58, 'low': 0.52, 'close': 0.54}, // Red
      {'open': 0.54, 'high': 0.58, 'low': 0.52, 'close': 0.57}, // Long green hammer
      {'open': 0.57, 'high': 0.63, 'low': 0.56, 'close': 0.62}, // Very long green
      {'open': 0.62, 'high': 0.65, 'low': 0.61, 'close': 0.64}, // Green
      {'open': 0.64, 'high': 0.67, 'low': 0.63, 'close': 0.66}, // Green
      {'open': 0.66, 'high': 0.69, 'low': 0.65, 'close': 0.68}, // Green
      {'open': 0.68, 'high': 0.74, 'low': 0.67, 'close': 0.72}, // Very long green
      {'open': 0.72, 'high': 0.75, 'low': 0.71, 'close': 0.73}, // Green
      {'open': 0.73, 'high': 0.74, 'low': 0.70, 'close': 0.71}, // Red
      {'open': 0.71, 'high': 0.75, 'low': 0.70, 'close': 0.74}, // Long green
      {'open': 0.74, 'high': 0.77, 'low': 0.73, 'close': 0.76}, // Green
      {'open': 0.76, 'high': 0.82, 'low': 0.75, 'close': 0.80}, // Very long green
      {'open': 0.80, 'high': 0.83, 'low': 0.79, 'close': 0.82}, // Green
      {'open': 0.82, 'high': 0.88, 'low': 0.81, 'close': 0.86}, // Very long green
      {'open': 0.86, 'high': 0.89, 'low': 0.85, 'close': 0.87}, // Green
      {'open': 0.87, 'high': 0.90, 'low': 0.83, 'close': 0.84}, // Red with wicks
      {'open': 0.84, 'high': 0.86, 'low': 0.78, 'close': 0.80}, // Long red
      {'open': 0.80, 'high': 0.82, 'low': 0.79, 'close': 0.81}, // Small green
      {'open': 0.81, 'high': 0.83, 'low': 0.80, 'close': 0.82}, // Small green
      {'open': 0.82, 'high': 0.86, 'low': 0.81, 'close': 0.85}, // Long green
      {'open': 0.85, 'high': 0.92, 'low': 0.84, 'close': 0.90}, // Very long green
      {'open': 0.90, 'high': 0.94, 'low': 0.89, 'close': 0.92}, // Green
      {'open': 0.92, 'high': 0.96, 'low': 0.91, 'close': 0.94}, // Green
      {'open': 0.94, 'high': 0.98, 'low': 0.90, 'close': 0.92}, // Red with huge upper wick
    ];

    final visibleCount = (candles.length * progress).toInt();
    if (visibleCount < 1) return;

    final candleWidth = size.width / (candles.length + 2);
    final brightRed = const Color(0xFFFF1744);
    const brightGreen = Color(0xFF00E676);

    // Draw visible candlesticks
    for (int i = 0; i < visibleCount; i++) {
      final candle = candles[i];
      final x = (i + 1) * candleWidth;
      
      final open = candle['open']!;
      final close = candle['close']!;
      final high = candle['high']!;
      final low = candle['low']!;
      
      final isBullish = close >= open;
      
      // Calculate positions from bottom
      final openY = size.height - (open * size.height * 0.65) - 60;
      final closeY = size.height - (close * size.height * 0.65) - 60;
      final highY = size.height - (high * size.height * 0.65) - 60;
      final lowY = size.height - (low * size.height * 0.65) - 60;
      
      final bodyTop = isBullish ? closeY : openY;
      final bodyBottom = isBullish ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).abs();
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = (isBullish ? brightGreen : brightRed).withOpacity(0.35);
      
      final wickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = (isBullish ? brightGreen : brightRed).withOpacity(0.45);

      // Draw upper wick
      canvas.drawLine(
        Offset(x, highY),
        Offset(x, bodyTop),
        wickPaint,
      );
      
      // Draw lower wick
      canvas.drawLine(
        Offset(x, bodyBottom),
        Offset(x, lowY),
        wickPaint,
      );

      // Draw candle body
      if (bodyHeight < 2) {
        // Doji - draw as a line
        canvas.drawLine(
          Offset(x - candleWidth * 0.3, (bodyTop + bodyBottom) / 2),
          Offset(x + candleWidth * 0.3, (bodyTop + bodyBottom) / 2),
          wickPaint,
        );
      } else {
        final bodyRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - candleWidth * 0.3,
            bodyTop,
            x + candleWidth * 0.3,
            bodyBottom,
          ),
          const Radius.circular(1),
        );
        canvas.drawRRect(bodyRect, paint);
      }
    }

    // Draw connecting line for overall trend
    if (visibleCount > 1) {
      final path = Path();
      for (int i = 0; i < visibleCount; i++) {
        final candle = candles[i];
        final x = (i + 1) * candleWidth;
        final close = candle['close']!;
        final y = size.height - (close * size.height * 0.65) - 60;
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = brightGreen.withOpacity(0.2);
      
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
