import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// Your other imports
import 'BudgetOverview.dart';
import 'SavingDeatilsPage.dart';
import 'chat_screen.dart';
import 'models/report/report_page.dart';
import 'models/report/stats.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'LoginPage.dart';
import 'CurrencySelectionScreen.dart';
import 'HomePage.dart';
import 'add_expense_page.dart';
import 'add_income_page.dart';
import 'transfer_page.dart';
import 'monthly_budget_page.dart';
import 'saving_goals_page.dart';
import 'donation_goals_page.dart';
import 'notes_page.dart';
import 'bottom_nav_home.dart';
import 'ThemeProvider.dart';
import 'CalculatorPage.dart';
import 'currency_rates_page.dart';
import 'shopping_list.dart';
import 'ThemeProvider.dart';
import 'services/fingerprint_auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCaVJyfxxTxn5OjIr8dWI9m-kSAP9fM81E",
        authDomain: "wallet-13f58.firebaseapp.com",
        projectId: "wallet-13f58",
        storageBucket: "wallet-13f58.firebasestorage.app",
        messagingSenderId: "1062989154840",
        appId: "1:1062989154840:web:759ee1546e8746020dd16d",
      ),
    );
  } else {
    await Firebase.initializeApp();
    await NotificationService.instance.initialize();

    // ✅ Add test device ID to show test ads
    final RequestConfiguration requestConfiguration = RequestConfiguration(
      testDeviceIds: ['C91AA61BDC00A51EA5338A491DA337AF'], // Replace with your actual test device ID if needed
    );
    await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    await MobileAds.instance.initialize();
  }

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDarkMode: isDarkMode),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      title: 'Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // ✅ Use initial route instead of home
      initialRoute: '/splash',

      // ✅ Define named routes
      routes: {
        '/splash': (context) => const SplashWrapper(),
        '/login': (context) => const LoginPage(),
        '/currency': (context) => CurrencySelectionScreen(),
        '/home': (context) => BottomNavHome(),
        '/expense': (context) => ExpenseScreen(),
        '/income': (context) => IncomeScreen(),
        '/transfer': (context) => TransferScreen(),
        '/monthly_budget': (context) => MonthlyBudgetPage(),
        '/saving_goals': (context) => const SavingGoalsPage(),
        '/add_expense': (context) => ExpenseScreen(),
        '/add_income': (context) => IncomeScreen(),
        '/transfers': (context) => TransferScreen(),
        '/notes': (context) => NotesPage(),
        '/donation_goals': (context) => DonationScreen(),
        '/statistics': (context) => StatsScreen(),
        '/calculator': (context) => CafeCalculator(),
        '/report': (context) => ReportPage(),
        '/currency_rate': (context) => CurrencyRatesPage(),
        '/shopping-list': (context) => ShoppingListPage(),
        '/budgetPage': (context) => BudgetOverviewScreen(),
        '/chatbot': (context) => const ChatScreen()
      },

      // ✅ For routes with arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/savings') {
          final userId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => SavingDetailsPage(userId: userId),
          );
        }

        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
      },
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({Key? key}) : super(key: key);

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showOnboarding = false;
  bool _initialized = false;

  final FingerprintAuthService _fingerprintAuth = FingerprintAuthService();

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    await Future.delayed(const Duration(seconds: 3));
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      bool isBiometricAvailable = await _fingerprintAuth.canCheckBiometrics();
      print("Biometric available: $isBiometricAvailable");

      if (isBiometricAvailable) {
        bool isAuthenticated = await _fingerprintAuth.authenticate();
        print("Fingerprint Authenticated: $isAuthenticated");

        if (!isAuthenticated) {
          FirebaseAuth.instance.signOut();
          setState(() {
            _showOnboarding = true;
            _initialized = true;
          });
          return;
        }
      }
    }

    setState(() {
      _showOnboarding = user == null;
      _initialized = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    } else {
      if (_showOnboarding) {
        return const OnboardingScreen();
      } else {
        return BottomNavHome();
      }
    }
  }
}
