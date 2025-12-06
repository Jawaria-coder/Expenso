import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;

  bool _loading = false;

  double totalIncome = 0;
  double totalExpenses = 0;
  double totalTransfers = 0;
  double totalBudget = 0;

  late TabController _tabController;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllStats();
    _loadInterstitialAd(); // 👈 Load interstitial ad
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ad unit; replace in production
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllStats() async {
    setState(() {
      _loading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      totalIncome = await _fetchTotalFromUserCollection(userId, 'income', 'amount');
      totalBudget = await _fetchTotalFromUserCollection(userId, 'budgets', 'budgetAmount');
      totalExpenses = await _fetchTotalFromTopLevelCollection('expenses', userId, 'amount');
      totalTransfers = await _fetchTotalFromTopLevelCollection('transfers', userId, 'amount');

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<double> _fetchTotalFromUserCollection(String userId, String collectionName, String amountField) async {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collectionName);

    if (_startDate != null) {
      final startTimestamp = Timestamp.fromDate(_startDate!);
      query = query.where(collectionName == 'budgets' ? 'createdAt' : 'date', isGreaterThanOrEqualTo: startTimestamp);
    }

    if (_endDate != null) {
      final endOfDay = _endDate!.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      final endTimestamp = Timestamp.fromDate(endOfDay);
      query = query.where(collectionName == 'budgets' ? 'createdAt' : 'date', isLessThanOrEqualTo: endTimestamp);
    }

    final snap = await query.get();
    double total = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += _toDouble(data[amountField]);
    }
    return total;
  }

  Future<double> _fetchTotalFromTopLevelCollection(String collectionName, String userId, String amountField) async {
    Query query = FirebaseFirestore.instance
        .collection(collectionName)
        .where('userId', isEqualTo: userId);

    if (_startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }

    if (_endDate != null) {
      final endTimestamp = Timestamp.fromDate(
        _endDate!.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
      );
      query = query.where('date', isLessThanOrEqualTo: endTimestamp);
    }

    final snap = await query.get();
    double total = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += _toDouble(data[amountField]);
    }
    return total;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      await _fetchAllStats();
    }
  }

  Future<void> _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _showInterstitialAd(); // 👈 Show ad when end date picked
      await _fetchAllStats();
    }
  }

  double totalSum() => totalIncome + totalExpenses + totalTransfers + totalBudget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF9B59B6),
        ),
        title: const Text('Financial Statistics'),
        titleTextStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF9B59B6),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9B59B6),
          labelColor: const Color(0xFF9B59B6),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pie Chart'),
            Tab(text: 'Bar Chart'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_startDate == null
                        ? 'Start Date'
                        : 'Start: ${_startDate!.toLocal().toString().split(' ')[0]}'),
                    onPressed: _pickStartDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_endDate == null
                        ? 'End Date'
                        : 'End: ${_endDate!.toLocal().toString().split(' ')[0]}'),
                    onPressed: _pickEndDate,
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _fetchAllStats();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPieChartView(),
                _buildBarChartView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ... [_buildPieChartView and _buildBarChartView methods remain unchanged; you already have them fully written above]


Widget _buildPieChartView() {
    final dataMap = <String, double>{
      'Income': totalIncome,
      'Expenses': totalExpenses,
      'Transfers': totalTransfers,
      'Budgets': totalBudget,
    };

    final colors = [
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.orange,
    ];

    final descriptions = [
      'Total income in selected range.',
      'Total expenses in selected range.',
      'Total transfers in selected range.',
      'Total budget in selected range.',
    ];

    final total = totalSum();
    final List<PieChartSectionData> sections = [];

    for (int i = 0; i < dataMap.length; i++) {
      final value = dataMap.values.elementAt(i);
      if (value <= 0) continue;
      final percent = (value / total * 100);
      sections.add(
        PieChartSectionData(
          color: colors[i],
          value: value,
          radius: 100,
          title: '${percent.toStringAsFixed(1)}%',
          titleStyle: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titlePositionPercentageOffset: 0.55,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 4),
            child: Text(
              "Categories",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...List.generate(dataMap.length, (i) {
            final value = dataMap.values.elementAt(i);
            if (value <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${dataMap.keys.elementAt(i)}: \$${value.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildBarChartView() {
    final categories = ['Income', 'Expenses', 'Transfers', 'Budgets'];
    final values = [totalIncome, totalExpenses, totalTransfers, totalBudget];

    double maxY = values.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 100;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  return index < categories.length ? Text(categories[index]) : const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  String formatted;
                  if (value >= 1000000) {
                    formatted = '${(value / 1000000).toStringAsFixed(1)}M';
                  } else if (value >= 1000) {
                    formatted = '${(value / 1000).toStringAsFixed(1)}K';
                  } else {
                    formatted = value.toStringAsFixed(0);
                  }
                  return Text(formatted, style: TextStyle(fontSize: 10));
                },
                reservedSize: 35,
              ),
            ),

          ),
          barGroups: List.generate(categories.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: values[index],
                  color: Color(0xFF9B59B6),
                  width: 24,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }),
        ),
      ),
    );
  }
}