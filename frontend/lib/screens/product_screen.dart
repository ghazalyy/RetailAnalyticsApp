import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart'; 
import 'scanner_screen.dart';
import '../main.dart';
import '../models/product_model.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> products = [];
  bool isLoading = true;
  String userRole = "staff"; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkRole();
    loadProducts();
  }

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
        title: const Text("Hapus Produk"),
        content: const Text("Yakin ingin menghapus produk ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Katalog Produk"),
        actions: [
          IconButton(
            icon: Icon(themeNotifier.value == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
            },
          )
        ],
      ),
      floatingActionButton: userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari nama atau scan barcode...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _openScanner),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) => loadProducts(query: value),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? const Center(child: Text("Produk tidak ditemukan"))
                    : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final item = products[index];
                          final price = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.price);
                          
                          bool isLowStock = item.stock < 10;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 2,
                            shape: isLowStock 
                                ? RoundedRectangleBorder(side: const BorderSide(color: Colors.red, width: 1), borderRadius: BorderRadius.circular(12)) 
                                : null,
                            child: ListTile(
                              leading: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.inventory, color: Colors.blue),
                              ),
                              title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.category),
                                  Text(
                                    "Stok: ${item.stock}", 
                                    style: TextStyle(
                                      color: isLowStock ? Colors.red : Colors.grey[600], 
                                      fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal
                                    )
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  if (userRole == 'admin') ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                                      onPressed: () => _openForm(product: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _deleteProduct(item.id),
                                    ),
                                  ]
                                ],
                              ),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: item)));
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}