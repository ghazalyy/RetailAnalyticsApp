import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;
  int? _touchedPieIndex;

  @override
  void initState() {
    super.initState();
    _dashboardData = ApiService.fetchDashboard();
  }

  void _downloadReport() async {
    try {
      await ApiService.downloadReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sedang mengunduh laporan...")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal download: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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

        return Scaffold(
          backgroundColor: bgColor,
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
                    return _buildLoadingShimmer(isDarkMode, cardColor);
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Gagal memuat data",
                        style: TextStyle(color: textColor),
                      ),
                    );
                  } else if (!snapshot.hasData) {
                    return Center(
                      child: Text(
                        "Data Kosong",
                        style: TextStyle(color: textColor),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final kpi = data['kpi'];
                  final trend =
                      data['line_chart_trend'] as Map<String, dynamic>;
                  final categories =
                      data['pie_chart_category'] as Map<String, dynamic>;
                  final lowStockCount = data['low_stock_count'] ?? 0;

                  final List<String> trendKeys = (trend.keys.toList()..sort());

                  final List<FlSpot> trendSpots = [
                    for (int i = 0; i < trendKeys.length; i++)
                      FlSpot(
                        i.toDouble(),
                        (trend[trendKeys[i]] as num).toDouble(),
                      ),
                  ];

                  final double? todaySales = trendKeys.isNotEmpty
                      ? (trend[trendKeys.last] as num).toDouble()
                      : null;
                  final double? yesterdaySales = trendKeys.length >= 2
                      ? (trend[trendKeys[trendKeys.length - 2]] as num)
                            .toDouble()
                      : null;
                  final double? dayDeltaPct =
                      (todaySales != null &&
                          yesterdaySales != null &&
                          yesterdaySales != 0)
                      ? ((todaySales - yesterdaySales) / yesterdaySales) * 100
                      : null;
                  final bestCategory = categories.entries.isNotEmpty
                      ? categories.entries
                            .reduce(
                              (a, b) =>
                                  (a.value as num) >= (b.value as num) ? a : b,
                            )
                            .key
                      : '-';
                  final profitMarginPct =
                      (kpi['total_sales'] != null &&
                          (kpi['total_sales'] as num) != 0)
                      ? ((kpi['total_profit'] as num) /
                                (kpi['total_sales'] as num)) *
                            100
                      : null;

                    final profitDeltaPct = 8.5;

                    final transactionDeltaPct = 5.2;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${getGreeting()}, Admin 👋",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: subTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Dashboard",
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
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
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.download_rounded,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.grey[800],
                                    ),
                                    tooltip: "Download Laporan",
                                    onPressed: _downloadReport,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
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
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
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
                                        isDarkMode
                                            ? Icons.light_mode
                                            : Icons.dark_mode,
                                        key: ValueKey(isDarkMode),
                                        color: isDarkMode
                                            ? Colors.yellow
                                            : Colors.grey[800],
                                      ),
                                    ),
                                    onPressed: () {
                                      themeNotifier.value = isDarkMode
                                          ? ThemeMode.light
                                          : ThemeMode.dark;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final kpiCards = [
                              _buildModernCard(
                                title: "Total Sales",
                                value: kpi['total_sales'],
                                titleColor: Colors.green,
                                bgColor: cardColor,
                                textColor: textColor,
                                isCurrency: true,
                                isDarkMode: isDarkMode,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22C55E),
                                    Color(0xFF16A34A),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                trendDeltaPct: dayDeltaPct,
                                icon: Icons.trending_up,
                              ),
                              _buildModernCard(
                                title: "Total Profit",
                                value: kpi['total_profit'],
                                titleColor: Colors.purpleAccent,
                                bgColor: cardColor,
                                textColor: textColor,
                                isCurrency: true,
                                isDarkMode: isDarkMode,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6D28D9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                trendDeltaPct: profitDeltaPct,
                                icon: Icons.paid_rounded,
                                subtitle: profitMarginPct != null
                                    ? "Margin ${NumberFormat.decimalPercentPattern(locale: 'en', decimalDigits: 1).format(profitMarginPct / 100)}"
                                    : null,
                              ),
                              _buildModernCard(
                                title: "Transaksi",
                                value: kpi['total_orders'],
                                titleColor: Colors.blueAccent,
                                bgColor: cardColor,
                                textColor: textColor,
                                isCurrency: false,
                                isDarkMode: isDarkMode,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF38BDF8),
                                    Color(0xFF0EA5E9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                trendDeltaPct: transactionDeltaPct,
                                icon: Icons.receipt_long_rounded,
                              ),
                              _buildModernCard(
                                title: "Stok Menipis",
                                value: lowStockCount,
                                displayLabel: "items",
                                titleColor: Colors.orange,
                                bgColor: cardColor,
                                textColor: textColor,
                                isCurrency: false,
                                isAlert: true,
                                isDarkMode: isDarkMode,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                icon: Icons.warning_amber_rounded,
                              ),
                            ];

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                  childAspectRatio: 0.98,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: kpiCards.length,
                              itemBuilder: (context, index) =>
                                  kpiCards[index],
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                        Text(
                          "Today's Summary",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!isDarkMode)
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 520;
                              final tiles = [
                                _SummaryTile(
                                  title: 'Sales Today',
                                  value: todaySales != null
                                      ? (isDarkMode
                                            ? formatCurrency(todaySales)
                                            : formatCurrency(todaySales))
                                      : '-',
                                  icon: Icons.today_rounded,
                                  color: Colors.green,
                                  isDarkMode: isDarkMode,
                                ),
                                _SummaryTile(
                                  title: 'vs Yesterday',
                                  value: dayDeltaPct != null
                                      ? (dayDeltaPct >= 0
                                            ? "+${dayDeltaPct.toStringAsFixed(1)}%"
                                            : "${dayDeltaPct.toStringAsFixed(1)}%")
                                      : '-',
                                  icon: dayDeltaPct != null && dayDeltaPct >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: dayDeltaPct != null && dayDeltaPct >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  isDarkMode: isDarkMode,
                                ),
                                _SummaryTile(
                                  title: 'Top Category',
                                  value: bestCategory,
                                  icon: Icons.category_rounded,
                                  color: Colors.blueAccent,
                                  isDarkMode: isDarkMode,
                                ),
                              ];

                              if (isNarrow) {
                                return Column(
                                  children: [
                                    tiles[0],
                                    const SizedBox(height: 12),
                                    tiles[1],
                                    const SizedBox(height: 12),
                                    tiles[2],
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: tiles[0]),
                                  const SizedBox(width: 12),
                                  Expanded(child: tiles[1]),
                                  const SizedBox(width: 12),
                                  Expanded(child: tiles[2]),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Monthly Sales Trend (Last 50 Transactions)",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (!isDarkMode)
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                            ],
                          ),
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final xIndex = spot.x.toInt();
                                      final dateKey =
                                          (xIndex >= 0 &&
                                              xIndex < trendKeys.length)
                                          ? trendKeys[xIndex]
                                          : '';
                                      final dateLabel = _formatDateLabel(
                                        dateKey,
                                      );
                                      return LineTooltipItem(
                                        '${formatCurrency(spot.y)}\n$dateLabel',
                                        GoogleFonts.poppins(
                                          color: textColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final i = value.toInt();
                                      final label =
                                          (i >= 0 && i < trendKeys.length)
                                          ? _formatDateLabel(trendKeys[i])
                                          : '';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          label,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: subTextColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: trendSpots,
                                  isCurved: true,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF38BDF8),
                                      Color(0xFF0EA5E9),
                                    ],
                                  ),
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF38BDF8,
                                        ).withOpacity(0.35),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Revenue vs Profit",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 220,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (!isDarkMode)
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                            ],
                          ),
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return Text(
                                            'Sales',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: subTextColor,
                                            ),
                                          );
                                        case 1:
                                          return Text(
                                            'Profit',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: subTextColor,
                                            ),
                                          );
                                        default:
                                          return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY:
                                          (kpi['total_sales'] as num?)
                                              ?.toDouble() ??
                                          0,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF22C55E),
                                          Color(0xFF16A34A),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY:
                                          (kpi['total_profit'] as num?)
                                              ?.toDouble() ??
                                          0,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6),
                                          Color(0xFF6D28D9),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ],
                                ),
                              ],
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        final label = group.x == 0
                                            ? 'Sales'
                                            : 'Profit';
                                        return BarTooltipItem(
                                          '$label\n${formatCurrency(rod.toY)}',
                                          GoogleFonts.poppins(
                                            color: textColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          "Kategori Produk",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              if (!isDarkMode)
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                            ],
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
                                    sections: _generatePieSections(
                                      categories,
                                      touchedIndex: _touchedPieIndex,
                                    ),
                                    pieTouchData: PieTouchData(
                                      enabled: true,
                                      touchCallback: (evt, resp) {
                                        setState(() {
                                          _touchedPieIndex = resp
                                              ?.touchedSection
                                              ?.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: categories.entries.map((entry) {
                                    final double total = categories.values
                                        .fold<double>(
                                          0,
                                          (p, c) => p + (c as num).toDouble(),
                                        );
                                    final pct = total > 0
                                        ? ((entry.value as num).toDouble() /
                                                  total) *
                                              100
                                        : 0.0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _getColor(entry.key),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${entry.key} – ${pct.toStringAsFixed(1)}%',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: subTextColor,
                                              ),
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

  Widget _buildModernCard({
    required String title,
    required dynamic value,
    required Color titleColor,
    required Color bgColor,
    required Color textColor,
    required bool isDarkMode,
    bool isCurrency = false,
    bool isAlert = false,
    LinearGradient? gradient,
    double? trendDeltaPct,
    IconData? icon,
    String? subtitle,
    String? displayLabel,
  }) {
    return _KpiCard(
      title: title,
      value: value,
      titleColor: titleColor,
      bgColor: bgColor,
      textColor: textColor,
      isDarkMode: isDarkMode,
      isCurrency: isCurrency,
      isAlert: isAlert,
      gradient: gradient,
      trendDeltaPct: trendDeltaPct,
      icon: icon,
      subtitle: subtitle,
      displayLabel: displayLabel,
      formatCurrency: formatCurrency,
    );
  }

  List<PieChartSectionData> _generatePieSections(
    Map<String, dynamic> categories, {
    int? touchedIndex,
  }) {
    double total = 0;
    categories.forEach((key, value) => total += (value as num));

    final entries = categories.entries.toList();
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      final value = (entry.value as num).toDouble();
      final isTouched = touchedIndex == i;
      return PieChartSectionData(
        color: _getColor(entry.key),
        value: value,
        title: '',
        radius: isTouched ? 35 : 25,
      );
    });
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Furniture':
        return Colors.brown;
      case 'Office Supplies':
        return Colors.blue;
      case 'Technology':
        return Colors.redAccent;
      default:
        return Colors.primaries[category.hashCode % Colors.primaries.length];
    }
  }

  String _formatDateLabel(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MM/dd').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Widget _buildLoadingShimmer(bool isDarkMode, Color cardColor) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 28,
                  width: 150,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 155,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 155,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 155,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 155,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 120,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: Container(
                        height: 120,
                        margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 160,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String title;
  final dynamic value;
  final Color titleColor;
  final Color bgColor;
  final Color textColor;
  final bool isDarkMode;
  final bool isCurrency;
  final bool isAlert;
  final LinearGradient? gradient;
  final double? trendDeltaPct;
  final IconData? icon;
  final String? subtitle;
  final String? displayLabel;
  final String Function(num) formatCurrency;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.bgColor,
    required this.textColor,
    required this.isDarkMode,
    required this.isCurrency,
    required this.isAlert,
    required this.formatCurrency,
    this.gradient,
    this.trendDeltaPct,
    this.icon,
    this.subtitle,
    this.displayLabel,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final elevation = _isHovered ? 0.14 : 0.08;
    final scale = _isHovered ? 1.01 : 1.0;

    final content = Container(
      height: 185,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: widget.gradient == null ? widget.bgColor : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!widget.isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(elevation),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.icon != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.gradient != null
                        ? Colors.white.withOpacity(0.12)
                        : widget.titleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: widget.gradient != null
                        ? Colors.white
                        : widget.titleColor,
                  ),
                ),
              if (widget.icon != null) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    color: widget.gradient != null
                        ? Colors.white
                        : widget.titleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: (widget.value as num).toDouble(),
            ),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              final display = widget.isCurrency
                  ? widget.formatCurrency(val)
                  : val.toStringAsFixed(0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    display,
                    style: GoogleFonts.poppins(
                      color: widget.gradient != null
                          ? Colors.white
                          : widget.textColor,
                      fontSize: widget.isCurrency ? 18 : 26,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.displayLabel != null)
                    Text(
                      widget.displayLabel!,
                      style: GoogleFonts.poppins(
                        color: widget.gradient != null
                            ? Colors.white70
                            : widget.textColor.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                ],
              );
            },
          ),
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.subtitle!,
                style: GoogleFonts.poppins(
                  color: widget.gradient != null
                      ? Colors.white70
                      : widget.textColor.withOpacity(0.65),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 4),
          const Spacer(),
          Align(
            alignment: Alignment.bottomLeft,
            child: (!widget.isAlert || (widget.isAlert && (widget.value as num) > 0))
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: widget.gradient != null
                          ? Colors.black.withOpacity(0.35)
                          : (widget.isDarkMode
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isAlert
                                ? Icons.arrow_downward
                                : (widget.trendDeltaPct != null && widget.trendDeltaPct! < 0
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward),
                            color: widget.isAlert
                                ? Colors.red[300] ?? Colors.red
                                : (widget.trendDeltaPct != null && widget.trendDeltaPct! < 0
                                    ? Colors.red[300] ?? Colors.red
                                    : Colors.green[300] ?? Colors.green),
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.isAlert
                                ? "Low Stock"
                                : (widget.trendDeltaPct != null
                                      ? '${widget.trendDeltaPct! >= 0 ? '+' : ''}${widget.trendDeltaPct!.abs().toStringAsFixed(1)}%'
                                      : '+'),
                            style: GoogleFonts.poppins(
                              color: widget.isAlert
                                  ? Colors.red[300] ?? Colors.red
                                  : (widget.trendDeltaPct != null && widget.trendDeltaPct! < 0
                                      ? Colors.red[300] ?? Colors.red
                                      : Colors.green[300] ?? Colors.green),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(height: 28),
          ),
        ],
      ),
    );

    final card = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: content,
    );

    final supportsHover =
        kIsWeb ||
        [
          TargetPlatform.windows,
          TargetPlatform.linux,
          TargetPlatform.macOS,
        ].contains(Theme.of(context).platform);
    if (!supportsHover) return card;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: card,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
