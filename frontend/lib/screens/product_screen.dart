import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart'; 
import 'scanner_screen.dart';
import '../main.dart'; // Import themeNotifier
import '../models/product_model.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> products = [];
  bool isLoading = true;
  String userRole = "staff"; // Default role
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkRole();
    loadProducts();
  }

  // Cek Role (Admin/Staff) dari penyimpanan lokal
  void _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_role') ?? "staff";
    });
  }

  Future<void> loadProducts({String query = ""}) async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.fetchProducts(page: 1, search: query);
      setState(() {
        products = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _deleteProduct(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Hapus Produk", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Yakin ingin menghapus produk ini?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Batal", style: GoogleFonts.poppins())),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Hapus", style: GoogleFonts.poppins(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await ApiService.deleteProduct(id);
      loadProducts(); 
    }
  }

  void _openForm({Product? product}) async {
    bool? reload = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)),
    );
    if (reload == true) loadProducts();
  }

  void _openScanner() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
    if (result != null && result is String) {
      _searchController.text = result;
      loadProducts(query: result);
    }
  }

  String formatCurrency(num value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
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
        final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Text(
              "Katalog Produk",
              style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold),
            ),
            iconTheme: IconThemeData(color: textColor),
            actions: [
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: textColor),
                onPressed: () {
                  themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                },
              )
            ],
          ),
          
          // --- LOGIKA TOMBOL TAMBAH (Hanya Admin) ---
          floatingActionButton: userRole == 'admin'
              ? FloatingActionButton(
                  backgroundColor: Colors.blueAccent,
                  onPressed: () => _openForm(),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null, // Staff tidak melihat tombol ini
              
          body: Column(
            children: [
              // --- SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      if (!isDarkMode)
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Cari nama atau scan barcode...",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent), 
                        onPressed: _openScanner
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    onSubmitted: (value) => loadProducts(query: value),
                  ),
                ),
              ),

              // --- LIST PRODUK ---
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? Center(child: Text("Produk tidak ditemukan", style: GoogleFonts.poppins(color: subTextColor)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final item = products[index];
                              bool isLowStock = item.stock < 10;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    if (!isDarkMode)
                                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    // Navigasi ke Detail Produk (Untuk Transaksi)
                                    bool? refresh = await Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: item)));
                                    if (refresh == true) loadProducts();
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // 1. Gambar/Icon Produk
                                        Container(
                                          width: 60, height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(15)
                                          ),
                                          child: const Icon(Icons.inventory_2_outlined, color: Colors.blueAccent, size: 30),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // 2. Info Nama & Harga
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name, 
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                                maxLines: 1, overflow: TextOverflow.ellipsis
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.category, 
                                                style: GoogleFonts.poppins(color: subTextColor, fontSize: 12)
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                formatCurrency(item.price), 
                                                style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 14)
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 3. Stok & Tombol Admin (Jika Ada)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            // Badge Stok
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isLowStock ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: isLowStock ? Border.all(color: Colors.red.withOpacity(0.5)) : null,
                                              ),
                                              child: Text(
                                                "Stok: ${item.stock}",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: isLowStock ? Colors.red : textColor,
                                                  fontWeight: FontWeight.w600
                                                ),
                                              ),
                                            ),
                                            
                                            // --- LOGIKA ADMIN ONLY ---
                                            // Jika Admin -> Tampilkan tombol Edit & Hapus
                                            // Jika Staff -> Kosong (SizedBox)
                                            if (userRole == 'admin') ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  InkWell(
                                                    onTap: () => _openForm(product: item),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(4.0),
                                                      child: Icon(Icons.edit_rounded, size: 20, color: Colors.orange[400]),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  InkWell(
                                                    onTap: () => _deleteProduct(item.id),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(4.0),
                                                      child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red[400]),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ] else ...[
                                               // Staff tidak melihat apa-apa disini
                                               const SizedBox(height: 20), // Spacer agar layout seimbang
                                            ]
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}