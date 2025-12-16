import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../main.dart'; // PENTING: Import ini wajib ada untuk akses themeNotifier

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;
  // Kita HAPUS variabel lokal _isDarkMode karena sekarang pakai Global Theme

  @override
  void initState() {
    super.initState();
    _dashboardData = ApiService.fetchDashboard();
  }

  String formatCurrency(num value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    // WRAPPER UTAMA: Mendengarkan perubahan tema dari themeNotifier
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        // Logika penentuan warna berdasarkan mode global
        final isDarkMode = mode == ThemeMode.dark;
        final bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7F8FA);
        final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

        return Scaffold(
          backgroundColor: bgColor,
          
          // --- BODY ---
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _dashboardData = ApiService.fetchDashboard();
                });
              },
              child: FutureBuilder<Map<String, dynamic>>(
                future: _dashboardData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Gagal memuat data", style: TextStyle(color: textColor)));
                  } else if (!snapshot.hasData) {
                    return Center(child: Text("Data Kosong", style: TextStyle(color: textColor)));
                  }

                  final data = snapshot.data!;
                  final kpi = data['kpi'];
                  final trend = data['line_chart_trend'] as Map<String, dynamic>;
                  final categories = data['pie_chart_category'] as Map<String, dynamic>;
                  final lowStockCount = data['low_stock_count'] ?? 0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER SECTION (Sinkron Global) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${getGreeting()}, Admin 👋",
                                  style: GoogleFonts.poppins(fontSize: 14, color: subTextColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Dashboard",
                                  style: GoogleFonts.poppins(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold, 
                                    color: textColor
                                  ),
                                ),
                              ],
                            ),
                            // Tombol Ganti Tema Global
                            Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.transparent),
                                boxShadow: [
                                  if (!isDarkMode)
                                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                                ]
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                  color: isDarkMode ? Colors.yellow : Colors.grey[800],
                                ),
                                onPressed: () {
                                  // Mengubah tema aplikasi secara GLOBAL
                                  themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                                },
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- KPI CARDS ---
                        Row(
                          children: [
                            Expanded(child: _buildModernCard(
                              title: "Total Sales", 
                              value: kpi['total_sales'], 
                              titleColor: Colors.green, 
                              bgColor: cardColor, 
                              textColor: textColor, 
                              isCurrency: true,
                              isDarkMode: isDarkMode
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _buildModernCard(
                              title: "Total Profit", 
                              value: kpi['total_profit'], 
                              titleColor: Colors.purpleAccent, 
                              bgColor: cardColor, 
                              textColor: textColor, 
                              isCurrency: true,
                              isDarkMode: isDarkMode
                            )),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildModernCard(
                              title: "Transaksi", 
                              value: kpi['total_orders'], 
                              titleColor: Colors.blueAccent, 
                              bgColor: cardColor, 
                              textColor: textColor, 
                              isCurrency: false,
                              isDarkMode: isDarkMode
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _buildModernCard(
                              title: "Stok Menipis", 
                              value: lowStockCount, 
                              titleColor: Colors.orange, 
                              bgColor: cardColor, 
                              textColor: textColor, 
                              isCurrency: false, 
                              isAlert: true,
                              isDarkMode: isDarkMode
                            )),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // --- CHART TREN ---
                        Text("Tren Penjualan (7 Hari)", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 16),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [if (!isDarkMode) BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true, 
                                    reservedSize: 22, 
                                    interval: 1, 
                                    getTitlesWidget: (value, meta) => Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(value.toInt().toString(), style: GoogleFonts.poppins(fontSize: 10, color: subTextColor)),
                                    )
                                  )
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _generateSpots(trend),
                                  isCurved: true,
                                  color: Colors.blueAccent,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- PIE CHART ---
                        Text("Kategori Produk", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [if (!isDarkMode) BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 120,
                                width: 120,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 30,
                                    sections: _generatePieSections(categories),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: categories.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        children: [
                                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _getColor(entry.key), shape: BoxShape.circle)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: GoogleFonts.poppins(fontSize: 12, color: subTextColor),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildModernCard({
    required String title, 
    required dynamic value, 
    required Color titleColor, 
    required Color bgColor, 
    required Color textColor, 
    required bool isDarkMode,
    bool isCurrency = false, 
    bool isAlert = false
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(color: titleColor, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            isCurrency ? formatCurrency(value) : value.toString(),
            style: GoogleFonts.poppins(
              color: textColor, 
              fontSize: isCurrency ? 16 : 24, 
              fontWeight: FontWeight.bold
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isAlert ? Icons.arrow_downward : Icons.arrow_upward, 
                color: isAlert ? Colors.red : Colors.green, 
                size: 14
              ),
              const SizedBox(width: 4),
              Text(
                isAlert ? "Low Stock" : "+12.5%", 
                style: GoogleFonts.poppins(
                  color: isAlert ? Colors.red : Colors.green, 
                  fontSize: 10, 
                  fontWeight: FontWeight.w500
                )
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- LOGIC CHART ---
  List<FlSpot> _generateSpots(Map<String, dynamic> trendData) {
    List<FlSpot> spots = [];
    int index = 0;
    var sortedKeys = trendData.keys.toList()..sort();
    if (sortedKeys.length > 7) sortedKeys = sortedKeys.sublist(sortedKeys.length - 7); 

    for (var key in sortedKeys) {
      spots.add(FlSpot(index.toDouble(), (trendData[key] as num).toDouble()));
      index++;
    }
    return spots;
  }

  List<PieChartSectionData> _generatePieSections(Map<String, dynamic> categories) {
    double total = 0;
    categories.forEach((key, value) => total += (value as num));

    return categories.entries.map((entry) {
      final value = (entry.value as num).toDouble();
      return PieChartSectionData(
        color: _getColor(entry.key),
        value: value,
        title: '',
        radius: 25,
      );
    }).toList();
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Furniture': return Colors.brown;
      case 'Office Supplies': return Colors.blue;
      case 'Technology': return Colors.redAccent;
      default: return Colors.primaries[category.hashCode % Colors.primaries.length];
    }
  }
}