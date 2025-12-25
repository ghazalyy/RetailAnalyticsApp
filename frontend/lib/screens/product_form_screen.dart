import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../main.dart';

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
  late FocusNode _nameFocus;
  late FocusNode _categoryFocus;
  late FocusNode _priceFocus;
  late FocusNode _stockFocus;
  File? _imageFile;
  bool _isLoading = false;
  bool _animateIn = false;
  List<String> _allCategories = [];
  List<String> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _categoryController = TextEditingController(
      text: widget.product?.category ?? "",
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? "",
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? "",
    );
    _nameFocus = FocusNode()..addListener(_onFocusChange);
    _categoryFocus = FocusNode()..addListener(_onFocusChange);
    _priceFocus = FocusNode()..addListener(_onFocusChange);
    _stockFocus = FocusNode()..addListener(_onFocusChange);

    _categoryController.addListener(_filterCategories);
    _loadCategories();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animateIn = true);
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _categoryFocus.dispose();
    _priceFocus.dispose();
    _stockFocus.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  Future<void> _loadCategories() async {
    try {
      final products = await ApiService.fetchProducts(page: 1, search: '');
      final categories = <String>{};
      for (var p in products) {
        if (p.category.isNotEmpty) {
          categories.add(p.category);
        }
      }
      if (mounted) {
        setState(() {
          _allCategories = categories.toList()..sort();
          _filterCategories();
        });
      }
    } catch (e) {
      if (mounted) print('Error loading categories: $e');
    }
  }

  void _filterCategories() {
    final query = _categoryController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredCategories = []);
      return;
    }
    setState(() {
      _filteredCategories = _allCategories
          .where((c) => c.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool success;
    String name = _nameController.text;
    String category = _categoryController.text;
    String priceClean = _priceController.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    double price = double.tryParse(priceClean) ?? 0;
    int stock = int.tryParse(_stockController.text) ?? 0;

    if (widget.product == null) {
      success = await ApiService.addProduct(name, category, price, stock, _imageFile);
    } else {
      success = await ApiService.updateProduct(
        widget.product!.id,
        name,
        category,
        price,
        stock,
        _imageFile,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Berhasil disimpan"),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menyimpan"),
          backgroundColor: Colors.red,
        ),
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
        final bgColor = isDarkMode
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF7F8FA);
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final inputFillColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[100];

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
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
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
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    offset: _animateIn ? Offset.zero : const Offset(0, 0.08),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _animateIn ? 1 : 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: inputFillColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _imageFile == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, color: Colors.blueAccent, size: 30),
                                      const SizedBox(height: 8),
                                      Text("Foto Produk", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Informasi Dasar",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildCustomField(
                    controller: _nameController,
                    label: "Nama Produk",
                    icon: Icons.label_outline,
                    fillColor: inputFillColor,
                    textColor: textColor,
                    focusNode: _nameFocus,
                    nextFocus: _categoryFocus,
                  ),
                  const SizedBox(height: 16),

                  _buildCustomField(
                    controller: _categoryController,
                    label: "Kategori",
                    icon: Icons.category_outlined,
                    fillColor: inputFillColor,
                    textColor: textColor,
                    focusNode: _categoryFocus,
                    nextFocus: _priceFocus,
                  ),
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _filteredCategories.isNotEmpty ? 1 : 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: BoxConstraints(
                        maxHeight: _filteredCategories.isNotEmpty ? 200 : 0,
                      ),
                      child: _filteredCategories.isNotEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                color: inputFillColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                ),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final cat = _filteredCategories[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      cat,
                                      style: GoogleFonts.poppins(color: textColor),
                                    ),
                                    onTap: () {
                                      setState(() => _categoryController.text = cat);
                                      _categoryFocus.unfocus();
                                    },
                                    hoverColor: Colors.blueAccent.withOpacity(0.08),
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  if (_filteredCategories.isNotEmpty) const SizedBox(height: 12),

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
                          focusNode: _priceFocus,
                          nextFocus: _stockFocus,
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
                          focusNode: _stockFocus,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: Colors.blueAccent.withOpacity(0.4),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _isLoading
                            ? const SizedBox(
                                key: ValueKey('saving'),
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "SIMPAN PRODUK",
                                key: const ValueKey('label'),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color? fillColor,
    required Color textColor,
    bool isNumber = false,
    String? prefixText,
    FocusNode? focusNode,
    FocusNode? nextFocus,
  }) {
    final isFocused = focusNode?.hasFocus ?? false;
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.digitsOnly,
            ]
          : null,
      focusNode: focusNode,
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) => nextFocus?.requestFocus(),
      style: GoogleFonts.poppins(color: textColor),
      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey),
        prefixText: prefixText,
        prefixStyle: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isFocused ? Colors.blueAccent.withOpacity(0.35) : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}