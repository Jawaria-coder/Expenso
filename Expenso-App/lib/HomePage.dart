import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:project/models/report/stats.dart';
import 'package:project/services/notification_service.dart';
import 'package:project/main.dart';
import 'package:project/ThemeProvider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  String userName = '';
  int walletAmount = 0;
  String? currency = 'Rs.';
  bool _isBalanceVisible = true;
  bool isLoading = true;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });
    await fetchCachedData(); // Fetch cache first
    fetchServerData();       // Then refresh from server
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    fetchServerData(); // Refresh on return
  }

  Future<void> fetchCachedData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));

        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            userName = data?['name'] ?? userName;
            walletAmount = (data?['wallet'] as num?)?.toInt() ?? walletAmount;
            currency = data?['currency'] ?? currency;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("⚠️ Cache fetch failed: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchServerData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 2));

        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            userName = data?['name'] ?? userName;
            walletAmount = (data?['wallet'] as num?)?.toInt() ?? walletAmount;
            currency = data?['currency'] ?? currency;
          });
        }
      } catch (e) {
        debugPrint("⚠️ Server fetch failed: $e");
      }
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Error signing out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final primaryColor = const Color(0xFF9B59B6);
    final background = isDark ? Colors.black : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cardColor,
        elevation: 1,
        title: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            'Expenso',
            style: TextStyle(
              color: Color(0xFF9B59B6),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            color: primaryColor,
            onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: primaryColor,
            onPressed: signOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(textColor, primaryColor),
              const SizedBox(height: 30),
              _buildWalletCard(primaryColor),
              const SizedBox(height: 30),
              _buildFeatureGrid(screenWidth, primaryColor, isDark),
              const SizedBox(height: 30),
              _buildQuickActions(screenWidth, primaryColor, textColor, isDark),
              const SizedBox(height: 30),
              _buildStatisticsCard(primaryColor, textColor, cardColor ?? Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(Color textColor, Color iconColor) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            userName.isNotEmpty ? 'Welcome back, $userName!' : 'Welcome!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.notifications_none, color: iconColor),
            onPressed: () async {
              print("🔔 Notification button clicked");
              await NotificationService.instance.sendNotification(
                'Wallet App',
                'Open Your App to calculate your expenses!',
              );
            }

        ),
      ],
    );
  }

  Widget _buildWalletCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.9), Colors.purple.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isBalanceVisible ? '$currency $walletAmount' : '•••••••',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                  icon: Icon(
                    _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                  ),
                ),
                const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 30),
              ],
            ),
          ),
        ],

      ),
    );
  }

  Widget _buildFeatureGrid(double screenWidth, Color primaryColor, bool isDark) {
    final double cardWidth = (screenWidth - 48) / 3.2;
    final List<_Feature> features = [
      _Feature('Monthly\nBudget', Icons.calendar_today_rounded, '/monthly_budget'),
      _Feature('Saving\nGoals', Icons.savings_outlined, '/saving_goals'),
      _Feature('Donation\nGoals', Icons.card_giftcard_outlined, '/donation_goals'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: features.map((feature) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, feature.route),
          child: Animate(
            effects: [
              FadeEffect(duration: 600.ms),
              ScaleEffect(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms),
            ],
            child: Container(
              width: cardWidth,
              height: cardWidth,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(feature.icon, size: 36, color: primaryColor),
                  const SizedBox(height: 10),
                  Text(
                    feature.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(double screenWidth, Color primaryColor, Color textColor, bool isDark) {
    final List<_Feature> quickActions = [
      _Feature('Add\nExpense', Icons.remove_circle_outline, '/add_expense'),
      _Feature('Add\nIncome', Icons.add_circle_outline, '/add_income'),
      _Feature('Add\nTransfer', Icons.compare_arrows_outlined, '/transfer'),
      _Feature('Your\nSaving', Icons.volunteer_activism_outlined, '/savings'),
      _Feature('Notes', Icons.sticky_note_2_outlined, '/notes'),
      _Feature('Calculator', Icons.calculate_outlined, '/calculator'),
      _Feature('Report', Icons.insert_chart_outlined_rounded, '/report'),
      _Feature('Currency Rates', Icons.monetization_on_outlined, '/currency_rate'),
      _Feature('Shopping List', Icons.shopping_cart_outlined, '/shopping-list'),
      _Feature('Chatbot', Icons.chat_bubble_outline, '/chatbot'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: quickActions.map((action) {
          return GestureDetector(
            onTap: () {
              if (action.route == '/savings') {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  Navigator.pushNamed(context, '/savings', arguments: userId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                }
              } else {
                Navigator.pushNamed(context, action.route);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(action.icon, size: 28, color: primaryColor),
                ),
                const SizedBox(height: 8),
                Text(action.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticsCard(Color primaryColor, Color textColor, Color cardColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => StatsScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(Icons.bar_chart, color: primaryColor, size: 40),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text('View Expense & Income Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final String route;

  _Feature(this.title, this.icon, this.route);
}
