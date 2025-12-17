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
        final bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7F8FA);
        final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

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
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.shopping_bag_outlined, 
                            size: 100, 
                            color: isDarkMode ? Colors.grey[600] : Colors.blueAccent.withOpacity(0.5)
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
                              color: product.stock < 10 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Stok: ${product.stock}",
                              style: GoogleFonts.poppins(
                                color: product.stock < 10 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.withOpacity(0.2)),
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

              Container(
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
                              IconButton(
                                onPressed: () => setState(() => _qty > 1 ? _qty-- : null),
                                icon: Icon(Icons.remove, color: textColor),
                                splashRadius: 20,
                              ),
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: Text("$_qty", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _qty < product.stock ? _qty++ : null),
                                icon: Icon(Icons.add, color: textColor),
                                splashRadius: 20,
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
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : Text(
                                "KONFIRMASI TRANSAKSI",
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}