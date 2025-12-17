import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../main.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  String formatCurrency(double value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  void _processCheckout(CartProvider cart) async {
    setState(() => _isProcessing = true);

    List<Map<String, dynamic>> itemsToSend = cart.items.values.map((item) {
      return {
        "productId": item.product.id,
        "quantity": item.quantity,
        "price": item.product.price,
        "category": item.product.category
      };
    }).toList();

    bool success = await ApiService.createBulkTransaction(itemsToSend);

    setState(() => _isProcessing = false);

    if (success && mounted) {
      _showSuccessDialog(cart);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaksi Gagal"), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(CartProvider cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Transaksi Berhasil!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda ingin mencetak struk transaksi ini?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: Text("Tidak", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              _printPdf(cart);
              cart.clear();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text("Cetak Struk", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf(CartProvider cart) async {
    final doc = pw.Document();
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final items = cart.items.values.toList();
    final total = cart.totalAmount;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text("RETAIL APP", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
              pw.Center(child: pw.Text(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10))),
              pw.Divider(),
              ...items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text("${item.product.name} x${item.quantity}", style: const pw.TextStyle(fontSize: 10))),
                  pw.Text(formatCurrency.format(item.product.price * item.quantity), style: const pw.TextStyle(fontSize: 10)),
                ],
              )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatCurrency.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text("Terima Kasih!", style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        final isDarkMode = mode == ThemeMode.dark;
        final bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7F8FA);
        final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text("Keranjang Belanja", style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
               Consumer<CartProvider>(
                builder: (_, cart, __) => IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: cart.items.isEmpty ? null : () => cart.clear(),
                ),
              )
            ],
          ),
          body: Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("Keranjang Kosong", style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                );
              }

              final cartItems = cart.items.values.toList();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartItems.length,
                      itemBuilder: (ctx, i) {
                        final item = cartItems[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [if (!isDarkMode) BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.inventory_2, color: Colors.blueAccent),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(formatCurrency(item.product.price), style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => cart.removeSingleItem(item.product.id),
                                  ),
                                  Text("${item.quantity}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => cart.addItem(item.product),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                            Text(formatCurrency(cart.totalAmount), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : () => _processCheckout(cart),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isProcessing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text("BAYAR SEKARANG", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }
}