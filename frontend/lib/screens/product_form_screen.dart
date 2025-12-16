import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../main.dart'; // Pastikan import ini ada untuk akses themeNotifier

class ProductFormScreen extends StatefulWidget {
  final Product? product; 

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _categoryController = TextEditingController(text: widget.product?.category ?? "");
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? "");
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? "");
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool success;
    String name = _nameController.text;
    String category = _categoryController.text;
    // Hapus karakter non-digit jika user tidak sengaja memasukkan format uang
    String priceClean = _priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    double price = double.tryParse(priceClean) ?? 0;
    int stock = int.tryParse(_stockController.text) ?? 0;

    if (widget.product == null) {
      success = await ApiService.addProduct(name, category, price, stock);
    } else {
      success = await ApiService.updateProduct(widget.product!.id, name, category, price, stock);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil disimpan"), backgroundColor: Colors.green)
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan"), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        final isDarkMode = mode == ThemeMode.dark;
        final bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7F8FA);
        final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final inputFillColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];

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
              isEditing ? "Edit Produk" : "Tambah Produk",
              style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Informasi Dasar", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  
                  // --- NAMA PRODUK ---
                  _buildCustomField(
                    controller: _nameController,
                    label: "Nama Produk",
                    icon: Icons.label_outline,
                    fillColor: inputFillColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),

                  // --- KATEGORI ---
                  _buildCustomField(
                    controller: _categoryController,
                    label: "Kategori",
                    icon: Icons.category_outlined,
                    fillColor: inputFillColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),

                  // --- HARGA & STOK (Side by Side) ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildCustomField(
                          controller: _priceController,
                          label: "Harga",
                          icon: Icons.attach_money,
                          fillColor: inputFillColor,
                          textColor: textColor,
                          isNumber: true,
                          prefixText: "Rp ",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCustomField(
                          controller: _stockController,
                          label: "Stok",
                          icon: Icons.inventory_2_outlined,
                          fillColor: inputFillColor,
                          textColor: textColor,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- TOMBOL SIMPAN ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                        shadowColor: Colors.blueAccent.withOpacity(0.4),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            "SIMPAN PRODUK", 
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Widget Helper untuk Input Field ---
  Widget _buildCustomField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color? fillColor,
    required Color textColor,
    bool isNumber = false,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.poppins(color: textColor),
      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey),
        prefixText: prefixText,
        prefixStyle: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}