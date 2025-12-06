import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageTabsState();
}

class _ReportPageTabsState extends State<ReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;


  DateTimeRange? _selectedRange;

  Map<String, double> incomeByMonth = {};
  Map<String, double> expenseByMonth = {};
  Map<String, double> donationByMonth = {};
  Map<String, double> transferByMonth = {};
  Map<String, double> budgetByMonth = {};

  List<Map<String, dynamic>> incomeDetails = [];
  List<Map<String, dynamic>> expenseDetails = [];
  List<Map<String, dynamic>> donationDetails = [];
  List<Map<String, dynamic>> transferDetails = [];
  List<Map<String, dynamic>> budgetDetails = [];

  final DateFormat monthFormat = DateFormat('yyyy-MM');
  final DateFormat fullDateFormat = DateFormat('yyyy-MM-dd');

  InterstitialAd? _interstitialAd;
  bool _isAdShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadInterstitialAd();
    _fetchData();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // test ad unit
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null && !_isAdShown) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isAdShown = true;
      _loadInterstitialAd();
    }
  }


  bool _isInRange(DateTime date) {
    if (_selectedRange == null) return true;
    return !(date.isBefore(_selectedRange!.start) || date.isAfter(_selectedRange!.end));
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Add userId filter to all except donations (already filtered)
    final incomeSnap = await FirebaseFirestore.instance
        .collection('users').doc(userId)
        .collection('income')
        .get();

    final expenseSnap = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    final donationSnap = await FirebaseFirestore.instance
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .get();

    final transferSnap = await FirebaseFirestore.instance
        .collection('transfers')
        .where('userId', isEqualTo: userId)
        .get();

    final budgetSnap = await FirebaseFirestore.instance
        .collection('users').doc(userId)
        .collection('budgets')
        .get();

    Map<String, double> incomeAgg = {};
    Map<String, double> expenseAgg = {};
    Map<String, double> donationAgg = {};
    Map<String, double> transferAgg = {};
    Map<String, double> budgetAgg = {};

    List<Map<String, dynamic>> incomeList = [];
    List<Map<String, dynamic>> expenseList = [];
    List<Map<String, dynamic>> donationList = [];
    List<Map<String, dynamic>> transferList = [];
    List<Map<String, dynamic>> budgetList = [];

    // Income
    for (var doc in incomeSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      if (!_isInRange(date)) continue;
      final key = monthFormat.format(date);
      final amount = (data['amount'] as num).toDouble();
      incomeAgg[key] = (incomeAgg[key] ?? 0) + amount;
      incomeList.add({
        'date': date,
        'amount': amount,
        'account': data['account'] ?? '',
        'category': data['category'] ?? '',
        'note': data['note'] ?? '',
        'type': data['type'] ?? '',
        'userId': data['userId'] ?? '',
      });
    }

    // Expenses
    for (var doc in expenseSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      if (!_isInRange(date)) continue;
      final key = monthFormat.format(date);
      final amount = (data['amount'] as num).toDouble();
      expenseAgg[key] = (expenseAgg[key] ?? 0) + amount;
      expenseList.add({
        'date': date,
        'amount': amount,
        'account': data['account'] ?? '',
        'category': data['category'] ?? '',
        'note': data['note'] ?? '',
        'type': data['type'] ?? '',
        'userId': data['userId'] ?? '',
      });
    }

    // Donations - filtered by userId
    for (var doc in donationSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['timestamp'] as Timestamp).toDate();
      if (!_isInRange(date)) continue;
      final key = monthFormat.format(date);
      final amount = (data['amount'] as num).toDouble();
      donationAgg[key] = (donationAgg[key] ?? 0) + amount;
      donationList.add({
        'date': date,
        'amount': amount,
        'name': data['name'] ?? '',
        'userId': data['userId'] ?? '',
      });
    }

    // Transfers
    for (var doc in transferSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      if (!_isInRange(date)) continue;
      final key = monthFormat.format(date);
      final amount = (data['amount'] as num).toDouble();
      transferAgg[key] = (transferAgg[key] ?? 0) + amount;
      transferList.add({
        'date': date,
        'amount': amount,
        'currency': data['currency'] ?? '',
        'fromWallet': data['fromWallet'] ?? '',
        'toWallet': data['toWallet'] ?? '',
        'userId': data['userId'] ?? '',
      });
    }

    // Budgets
    for (var doc in budgetSnap.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      if (!_isInRange(createdAt)) continue;

      final key = monthFormat.format(createdAt);
      final budgetAmount = (data['budgetAmount'] as num).toDouble();
      budgetAgg[key] = (budgetAgg[key] ?? 0) + budgetAmount;

      final startDate = DateTime.parse(data['startDate']);
      final endDate = DateTime.parse(data['endDate']);

      budgetList.add({
        'createdAt': createdAt,
        'startDate': startDate,
        'endDate': endDate,
        'amountLeft': (data['amountLeft'] as num).toDouble(),
        'budgetAmount': budgetAmount,
        'category': data['category'] ?? '',
        'spentAmount': (data['spentAmount'] as num).toDouble(),
      });
    }

    setState(() {
      incomeByMonth = incomeAgg;
      expenseByMonth = expenseAgg;
      donationByMonth = donationAgg;
      transferByMonth = transferAgg;
      budgetByMonth = budgetAgg;

      incomeDetails = incomeList;
      expenseDetails = expenseList;
      donationDetails = donationList;
      transferDetails = transferList;
      budgetDetails = budgetList;

      _isLoading = false;
    });
    if (!_isAdShown) {
      _showInterstitialAd();
    }
  }


  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      await _fetchData();
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    String dateRangeText = _selectedRange != null
        ? '${fullDateFormat.format(_selectedRange!.start)} to ${fullDateFormat.format(_selectedRange!.end)}'
        : 'All Time';

    pw.Widget sectionTitle(String title) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        );

    pw.Widget buildSummary(String label, Map<String, double> data) {
      if (data.isEmpty) return pw.Text('No data');
      return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: data.entries
              .map((e) => pw.Text('${e.key}: Rs ${e.value.toStringAsFixed(2)}'))
              .toList());
    }

    pw.Widget buildDetailsTable(List<Map<String, dynamic>> details, List<String> fields) {
      if (details.isEmpty) return pw.Text('No details available');
      return pw.Table.fromTextArray(
          headers: fields,
          data: details.map((item) {
            return fields.map((f) {
              var val = item[f];
              if (val is DateTime) return fullDateFormat.format(val);
              if (val == null) return '';
              return val.toString();
            }).toList();
          }).toList(),
          border: null,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 10));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Center(
              child: pw.Text('Financial Report',
                  style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 12),
          pw.Text('Date Range: $dateRangeText', style: pw.TextStyle(fontSize: 14)),
          pw.Divider(),
          sectionTitle('Income Summary'),
          buildSummary('Income', incomeByMonth),
          pw.SizedBox(height: 8),
          sectionTitle('Income Details'),
          buildDetailsTable(incomeDetails, ['date', 'amount', 'account', 'category', 'note']),
          pw.Divider(),
          sectionTitle('Expenses Summary'),
          buildSummary('Expenses', expenseByMonth),
          pw.SizedBox(height: 8),
          sectionTitle('Expenses Details'),
          buildDetailsTable(expenseDetails, ['date', 'amount', 'account', 'category', 'note', ]),
          pw.Divider(),
          sectionTitle('Donations Summary'),
          buildSummary('Donations', donationByMonth),
          pw.SizedBox(height: 8),
          sectionTitle('Donations Details'),
          buildDetailsTable(donationDetails, ['date', 'amount', 'name',]),
          pw.Divider(),
          sectionTitle('Transfers Summary'),
          buildSummary('Transfers', transferByMonth),
          pw.SizedBox(height: 8),
          sectionTitle('Transfers Details'),
          buildDetailsTable(transferDetails, ['date', 'amount', 'currency', 'fromWallet', 'toWallet']),
          pw.Divider(),
          sectionTitle('Budgets Summary'),
          buildSummary('Budgets', budgetByMonth),
          pw.SizedBox(height: 8),
          sectionTitle('Budgets Details'),
          buildDetailsTable(
              budgetDetails,
              [
                'createdAt',
                'budgetAmount',
                'amountLeft',
                'spentAmount',
                'category',
                'startDate',
                'endDate'
              ]),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Widget _buildSummarySection(String title, Map<String, double> summary) {
    if (summary.isEmpty) return const Text('No summary data available');
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: summary.entries.map((e) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return Chip(
          label: Text(
            '${e.key}: Rs ${e.value.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          backgroundColor: isDarkMode
              ? Colors.transparent
              : const Color(0xFF9B59B6).withOpacity(0.1),
          shape: StadiumBorder(
            side: BorderSide(
              color: isDarkMode ? Colors.white70 : Colors.transparent,
              width: 1.2,
            ),
          ),
        );
      }).toList(),

    );
  }

  Widget _buildDetailsSection(List<Map<String, dynamic>> details, List<String> fields) {
    if (details.isEmpty) return const Center(child: Text('No details available'));
    return ListView.builder(
      itemCount: details.length,
      itemBuilder: (context, index) {
        final item = details[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF9B59B6), width: 1.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF8F5FA), // light purple background
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields.map((field) {
                var val = item[field];
                if (val is DateTime) val = fullDateFormat.format(val);
                if (val == null) val = '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$field: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF9B59B6),
                          ),
                        ),
                        TextSpan(
                          text: '$val',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );

      },
    );
  }

  Widget _buildTabContent(String title, Map<String, double> summary, List<Map<String, dynamic>> details, List<String> fields) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildSummarySection('Summary', summary),
            ),
          ),
          const Divider(),
          Expanded(child: _buildDetailsSection(details, fields)),
        ],
      ),
    );
  }

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
              : Color(0xFF9B59B6),
        ),
        title: Text(
          'Financial Report',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Color(0xFF9B59B6),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            tooltip: 'Select Date Range',
            onPressed: () async {
              setState(() => _isLoading = true);
              await _selectDateRange();
              setState(() => _isLoading = false);
            },
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Export as PDF',
            onPressed: () async {
              setState(() => _isLoading = true);
              await _exportPDF();
              setState(() => _isLoading = false);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Color(0xFF9B59B6),
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey,
          indicatorColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Color(0xFF9B59B6),
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
            Tab(text: 'Donations'),
            Tab(text: 'Transfers'),
            Tab(text: 'Budgets'),
          ],
        ),
      ),


      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(
            'Income',
            incomeByMonth,
            incomeDetails,
            ['date', 'amount', 'account', 'category', 'note'],
          ),
          _buildTabContent(
            'Expenses',
            expenseByMonth,
            expenseDetails,
            ['date', 'amount', 'account', 'category', 'note'],
          ),
          _buildTabContent(
            'Donations',
            donationByMonth,
            donationDetails,
            ['date', 'amount', 'name'],
          ),
          _buildTabContent(
            'Transfers',
            transferByMonth,
            transferDetails,
            ['date', 'amount', 'currency', 'fromWallet', 'toWallet'],
          ),
          _buildTabContent(
            'Budgets',
            budgetByMonth,
            budgetDetails,
            [
              'createdAt',
              'budgetAmount',
              'amountLeft',
              'spentAmount',
              'category',
              'startDate',
              'endDate',
            ],
          ),
        ],
      ),
    );
  }

}