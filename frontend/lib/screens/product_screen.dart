import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'scanner_screen.dart';
import 'cart_screen.dart';
import '../main.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> products = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreProducts = true;
  int currentPage = 1;
  String currentQuery = "";
  String userRole = "staff";
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _checkRole();
    loadProducts();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 500) {
      if (!isLoadingMore && hasMoreProducts) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (isLoadingMore || !hasMoreProducts) return;
    if (!mounted) return;
    setState(() => isLoadingMore = true);
    try {
      final data = await ApiService.fetchProducts(
        page: currentPage + 1,
        search: currentQuery,
      );
      if (!mounted) return;
      if (data.isEmpty) {
        setState(() => hasMoreProducts = false);
      } else {
        setState(() {
          products.addAll(data);
          currentPage++;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingMore = false);
    }
  }

  void _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userRole = prefs.getString('user_role') ?? "staff";
    });
  }



  Future<void> loadProducts({String query = ""}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      currentPage = 1;
      currentQuery = query;
      hasMoreProducts = true;
    });
    try {
      final data = await ApiService.fetchProducts(page: 1, search: query);
      if (!mounted) return;
      setState(() {
        products = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _deleteProduct(String id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              "Hapus Produk",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Yakin ingin menghapus produk ini?",
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("Batal", style: GoogleFonts.poppins()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  "Hapus",
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await ApiService.deleteProduct(id);
      loadProducts();
    }
  }

  void _openForm({Product? product}) async {
    bool? reload = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );
    if (reload == true) loadProducts();
  }

  void _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    if (result != null && result is String) {
      _searchController.text = result;
      loadProducts(query: result);
    }
  }

  String formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        final isDarkMode = mode == ThemeMode.dark;
        final bgColor = isDarkMode
            ? const Color(0xFF0F0F0F)
            : const Color(0xFFF7F8FA);
        final cardColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[600];

        var scaffold = Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Text(
              "Katalog Produk",
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: textColor),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey[800]!
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      if (!isDarkMode)
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: Tween(
                            begin: 0.75,
                            end: 1.0,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        key: ValueKey(isDarkMode),
                        color: isDarkMode ? Colors.yellow : Colors.grey[800],
                      ),
                    ),
                    onPressed: () {
                      themeNotifier.value = isDarkMode
                          ? ThemeMode.light
                          : ThemeMode.dark;
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: userRole == 'admin'
              ? ScaleTransition(
                  scale: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1),
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: FloatingActionButton(
                    backgroundColor: Colors.blueAccent,
                    elevation: 8,
                    onPressed: () => _openForm(),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                )
              : Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    if (cart.items.isEmpty) return const SizedBox();
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1).animate(
                        CurvedAnimation(
                          parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1),
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CartScreen(),
                            ),
                          );
                        },
                        backgroundColor: Colors.green.withOpacity(0.95),
                        elevation: 8,
                        icon: const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              formatCurrency(cart.totalAmount),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      if (!isDarkMode)
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Cari nama atau scan barcode...",
                      hintStyle: GoogleFonts.poppins(color: subTextColor),
                      prefixIcon: Icon(Icons.search, color: subTextColor),
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.blueAccent.withOpacity(0.18)
                              : Colors.blueAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.blueAccent,
                          ),
                          onPressed: _openScanner,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        loadProducts(query: value);
                      } else {
                        loadProducts(query: '');
                      }
                    },
                    onSubmitted: (value) => loadProducts(query: value),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: isLoading
                      ? _buildShimmerList(isDarkMode, cardColor)
                      : products.isEmpty
                          ? Center(
                              key: const ValueKey('empty'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ScaleTransition(
                                    scale: Tween<double>(begin: 0.8, end: 1)
                                        .animate(
                                      CurvedAnimation(
                                        parent: AlwaysStoppedAnimation(1),
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 72,
                                      color: subTextColor!.withOpacity(0.3),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Produk tidak ditemukan",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Coba cari dengan kata kunci lain",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              key: const ValueKey('list'),
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 6,
                              ),
                              itemCount: products.length + (isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == products.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  );
                                }
                                final item = products[index];
                                bool isLowStock = item.stock < 10;
                                final isCompact = MediaQuery.of(context).size.width < 390;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.03)
                                          : Colors.blueAccent.withOpacity(0.06),
                                    ),
                                    boxShadow: [
                                      if (!isDarkMode)
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.07),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      bool? refresh = await Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              ProductDetailScreen(product: item),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            const begin = Offset(0.0, 0.03);
                                            const end = Offset.zero;
                                            const curve = Curves.easeOutCubic;
                                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                            var offsetAnimation = animation.drive(tween);
                                            var fadeAnimation = CurvedAnimation(parent: animation, curve: curve);
                                            return SlideTransition(
                                              position: offsetAnimation,
                                              child: FadeTransition(opacity: fadeAnimation, child: child),
                                            );
                                          },
                                          transitionDuration: const Duration(milliseconds: 400),
                                        ),
                                      );
                                      if (refresh == true) loadProducts();
                                    },
                                    borderRadius: BorderRadius.circular(22),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF38BDF8),
                                                  Color(0xFF0EA5E9),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.inventory_2_outlined,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: isCompact ? 15 : 16,
                                                        color: textColor,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: isCompact ? 8 : 10,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isLowStock
                                                            ? Colors.red.withOpacity(0.12)
                                                            : Colors.green.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            isLowStock
                                                                ? Icons.warning_amber_rounded
                                                                : Icons.check_circle,
                                                            size: 14,
                                                            color: isLowStock
                                                                ? Colors.red
                                                                : Colors.green,
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            "Stok: ${item.stock}",
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w600,
                                                              color: isLowStock
                                                                  ? Colors.red
                                                                  : Colors.green,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  item.category,
                                                  style: GoogleFonts.poppins(
                                                    color: subTextColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  formatCurrency(item.price),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (userRole == 'admin') ...[
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                InkWell(
                                                  onTap: () => _openForm(product: item),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(
                                                      Icons.edit_rounded,
                                                      size: 20,
                                                      color: Colors.orange[500],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                InkWell(
                                                  onTap: () => _deleteProduct(item.id),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(
                                                      Icons.delete_outline_rounded,
                                                      size: 20,
                                                      color: Colors.red[500],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ] else ...[
                                            Column(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Provider.of<CartProvider>(
                                                      context,
                                                      listen: false,
                                                    ).addItem(item);
                                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("${item.name} +1 ke Keranjang"),
                                                        duration: const Duration(milliseconds: 500),
                                                        backgroundColor: Colors.blueAccent,
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blueAccent,
                                                    shape: const CircleBorder(),
                                                    padding: const EdgeInsets.all(12),
                                                    minimumSize: const Size(0, 0),
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        );
        return scaffold;
      },
    );
  }

  Widget _buildShimmerList(bool isDarkMode, Color cardColor) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: 90,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
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
