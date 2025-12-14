import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';

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
    double price = double.parse(_priceController.text);
    int stock = int.parse(_stockController.text);

    if (widget.product == null) {
      success = await ApiService.addProduct(name, category, price, stock);
    } else {
      success = await ApiService.updateProduct(widget.product!.id, name, category, price, stock);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil disimpan")));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? "Tambah Produk" : "Edit Produk")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nama Produk", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Harga", border: OutlineInputBorder(), prefixText: "Rp "),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stok Awal", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator() : const Text("SIMPAN"),
              )
            ],
          ),
        ),
      ),
    );
  }
}