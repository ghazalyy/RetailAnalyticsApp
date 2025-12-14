import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = ApiService.fetchDashboard();
  }

  String formatCurrency(num value) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
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
              return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Data Kosong"));
            }

            final data = snapshot.data!;
            final kpi = data['kpi'];
            final trend = data['line_chart_trend'] as Map<String, dynamic>;
            final categories = data['pie_chart_category'] as Map<String, dynamic>;
            final lowStockCount = data['low_stock_count'] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ringkasan Bisnis", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard("Total Sales", kpi['total_sales'], Colors.blue, Icons.attach_money)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildKpiCard("Profit", kpi['total_profit'], Colors.green, Icons.trending_up)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard("Total Transaksi", kpi['total_orders'], Colors.orange, Icons.shopping_cart, isCurrency: false)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildKpiCard("Stok Menipis", lowStockCount, Colors.red, Icons.warning_amber_rounded, isCurrency: false)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text("Tren Penjualan (Bulanan)", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.only(right: 16, left: 0),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 1, getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                            }),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade200)),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generateSpots(trend),
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Penjualan per Kategori", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                            sections: _generatePieSections(categories),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: categories.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                children: [
                                  Container(width: 12, height: 12, color: _getColor(entry.key)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "${entry.key}: ${formatCurrency(entry.value)}",
                                      style: const TextStyle(fontSize: 11),
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
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, dynamic value, Color color, IconData icon, {bool isCurrency = true}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCurrency ? formatCurrency(value) : value.toString(),
            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots(Map<String, dynamic> trendData) {
    List<FlSpot> spots = [];
    int index = 0;
    var sortedKeys = trendData.keys.toList()..sort();
    if (sortedKeys.length > 12) sortedKeys = sortedKeys.sublist(sortedKeys.length - 12);

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
      final percentage = (value / total * 100).toStringAsFixed(1);
      
      return PieChartSectionData(
        color: _getColor(entry.key),
        value: value,
        title: '$percentage%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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