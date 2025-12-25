import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../main.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _isProcessing = false;
  bool _showBottomBar = false;
  double _tiltX = 0;
  double _tiltY = 0;
  double _parallax = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showBottomBar = true);
    });
  }

  void _processTransaction() async {
    setState(() => _isProcessing = true);
    
    double total = widget.product.price * _qty;

    if (_qty > widget.product.stock) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok tidak mencukupi!"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    bool success = await ApiService.createTransaction(widget.product.id, _qty, total);

    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaksi Berhasil!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaksi Gagal."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final priceFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    final double estimatedTotal = product.price * _qty;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        final isDarkMode = mode == ThemeMode.dark;
        final bgColor = isDarkMode ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA);
        final cardColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[600];

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Detail Transaksi",
              style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollUpdateNotification) {
                setState(() {
                  _parallax = (n.metrics.pixels).clamp(-40, 80);
                });
              }
              return false;
            },
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onPanUpdate: (d) {
                            setState(() {
                              _tiltX = (d.delta.dy / 200).clamp(-0.08, 0.08);
                              _tiltY = (-d.delta.dx / 200).clamp(-0.08, 0.08);
                            });
                          },
                          onPanEnd: (_) => setState(() {
                            _tiltX = 0;
                            _tiltY = 0;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                if (!isDarkMode)
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                              ],
                            ),
                            transform: Matrix4.identity()
                              ..translate(0.0, _parallax * -0.08)
                              ..rotateX(_tiltX)
                              ..rotateY(_tiltY),
                            child: Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 110,
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.blueAccent.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.category.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueAccent, 
                                    fontWeight: FontWeight.w600, 
                                    fontSize: 12,
                                    letterSpacing: 1.2
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold, 
                                    color: textColor
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: product.stock < 10
                                  ? Colors.red.withOpacity(0.12)
                                  : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.stock < 10
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle,
                                  size: 16,
                                  color: product.stock < 10 ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Stok: ${product.stock}",
                                  style: GoogleFonts.poppins(
                                    color: product.stock < 10 ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: product.stock < 5
                            ? Container(
                                key: const ValueKey('low-stock'),
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Stok menipis, pertimbangkan restock",
                                        style: GoogleFonts.poppins(
                                          color: Colors.red[800],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(key: ValueKey('no-low-stock')),
                      ),
                      if (product.stock < 5) const SizedBox(height: 12),
                      Divider(color: Colors.grey.withOpacity(0.18)),
                      const SizedBox(height: 16),

                      Text(
                        "Harga Satuan",
                        style: GoogleFonts.poppins(fontSize: 14, color: subTextColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceFormatter.format(product.price),
                        style: GoogleFonts.poppins(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          color: textColor
                        ),
                      ),
                    ],
                  ),
                ),
              ),

                AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  offset: _showBottomBar ? Offset.zero : const Offset(0, 0.15),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 260),
                    opacity: _showBottomBar ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    _AnimatedIconButton(
                                      icon: Icons.remove,
                                      color: textColor,
                                      onTap: () => setState(() {
                                        if (_qty > 1) _qty--;
                                      }),
                                    ),
                                    Container(
                                      width: 44,
                                      alignment: Alignment.center,
                                      child: Text(
                                        "$_qty",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    _AnimatedIconButton(
                                      icon: Icons.add,
                                      color: textColor,
                                      onTap: () => setState(() {
                                        if (_qty < product.stock) _qty++;
                                      }),
                                    ),
                                  ],
                                ),
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Total:", style: GoogleFonts.poppins(fontSize: 12, color: subTextColor)),
                                  Text(
                                    priceFormatter.format(estimatedTotal),
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _processTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 5,
                                shadowColor: Colors.blueAccent.withOpacity(0.4),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _isProcessing
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        "KONFIRMASI TRANSAKSI",
                                        key: const ValueKey('label'),
                                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1;

  void _animate() {
    setState(() => _scale = 0.9);
    Future.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _animate();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: IconButton(
          onPressed: null,
          icon: Icon(widget.icon, color: widget.color),
          splashRadius: 20,
        ),
      ),
    );
  }
}