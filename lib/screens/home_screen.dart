import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../widgets/toast_helper.dart';
import '../services/shop_service.dart';
import '../models/shop_model.dart';
import 'shops/shops_screen.dart';

import 'sales/sales_orders_screen.dart';
import 'sales/create_order_screen.dart';
import 'payments/payments_screen.dart';
import 'store_tab.dart';
import '../services/sales_record_service.dart';
import '../services/sales_payment_service.dart';
import '../widgets/premium_background.dart';
import '../widgets/glass_card.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  String? _salesSearchQuery;
  Timer? _summaryTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _scheduleDailySummary();
  }

  @override
  void dispose() {
    _summaryTimer?.cancel();
    super.dispose();
  }

  void _scheduleDailySummary() {
    // Check every minute if it's past 16:00 and hasn't saved today
    _summaryTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final now = DateTime.now();
      if (now.hour >= 23) {
        final prefs = await SharedPreferences.getInstance();
        final dateKey = 'inventory_summary_${now.year}_${now.month}_${now.day}';
        final hasSavedToday = prefs.getBool(dateKey) ?? false;

        if (!hasSavedToday) {
          final agentId = FirebaseAuth.instance.currentUser?.uid;
          if (agentId == null) return;

          final profile = await AuthService().getAgentProfile();
          final agentName = profile?['name'] ?? 'Agent';

          final filePath = await PdfService.generateAndSaveInventorySummary(
            agentId,
            agentName,
          );

          if (filePath != null) {
            await prefs.setBool(dateKey, true);
            if (mounted) {
              ToastHelper.showTopRightToast(
                context,
                'Daily Inventory auto-saved to phone',
              );
            }
          }
        }
      }
    });
  }

  List<Widget> get _tabs => [
    _HomeTab(
      onTabChange: (index) => setState(() => _currentIndex = index),
      onSalesSearch: (query) {
        setState(() {
          _salesSearchQuery = query;
          _currentIndex = 1; // Direct jump to Sales
        });
      },
    ),
    SalesOrdersScreen(initialSearchQuery: _salesSearchQuery),
    const ShopsScreen(),
    const PaymentsScreen(),
    const StoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.inputBorder, width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.darkBackground,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.white.withOpacity(0.9), // Increased opacity
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Sales',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Shops'),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Store',
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final Function(int) onTabChange;
  final Function(String) onSalesSearch;
  const _HomeTab({required this.onTabChange, required this.onSalesSearch});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final AuthService _auth = AuthService();
  final SalesRecordService _recordService = SalesRecordService();
  final SalesPaymentService _paymentService = SalesPaymentService();
  final ShopService _shopService = ShopService();

  String _firstName = 'Agent';
  String _region = '';
  List<Map<String, dynamic>> _topProducts = [];
  List<ShopModel> _recentShops = [];

  final _currency = NumberFormat('#,##0.00', 'en_US');

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await _auth.getAgentFirstName();
    final region = await _auth.getAgentRegion();
    final topProducts = await _recordService.getTopSoldProducts(_agentId);
    final shops = await _shopService.getAgentShops(_agentId);

    if (mounted) {
      setState(() {
        _firstName = name;
        _region = region;
        _topProducts = topProducts;
        _recentShops = shops.take(8).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors
            .transparent, // Fully transparent to show PremiumBackground clearly
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSalesCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Quick Actions'),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          'Recent Shops',
                          () => widget.onTabChange(2),
                        ),
                        const SizedBox(height: 16),
                        _buildRecentShops(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Business Insights'),
                        const SizedBox(height: 16),
                        _buildBusinessInsights(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Top Product Sales'),
                        const SizedBox(height: 16),
                        _buildTopProducts(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    if (_topProducts.isEmpty) {
      return GlassCard(
        child: Center(
          child: Text(
            'No sales data yet',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        children: _topProducts.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final isLast = index == _topProducts.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? const Color(0xFFFFD700).withOpacity(0.1)
                            : AppColors.inputBackground.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index == 0
                              ? const Color(0xFFFFD700).withOpacity(0.5)
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            color: index == 0
                                ? const Color(0xFFFFD700)
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['productName'],
                            style: GoogleFonts.inter(
                              color: AppColors.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product['totalQuantity']}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${product['unit']}',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBusinessInsights() {
    return Column(
      children: [
        StreamBuilder<double>(
          stream: _recordService.watchOutstandingBalance(_agentId),
          builder: (context, snapshot) {
            final val = snapshot.data ?? 0.0;
            return _buildInsightCard(
              'Outstanding Balance',
              'Rs ${_currency.format(val)}',
              Icons.account_balance_wallet_outlined,
              const Color(0xFFFFA726),
              'Total collection pending',
              loading: snapshot.connectionState == ConnectionState.waiting,
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<double>(
          stream: _recordService.watchMonthlySales(_agentId),
          builder: (context, snapshot) {
            final val = snapshot.data ?? 0.0;
            return _buildInsightCard(
              'Monthly Sales',
              'Rs ${_currency.format(val)}',
              Icons.analytics_outlined,
              const Color(0xFF66BB6A),
              'Sales in ${DateFormat('MMMM').format(DateTime.now())}',
              loading: snapshot.connectionState == ConnectionState.waiting,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle, {
    bool loading = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(
                0.2,
              ), // Increased opacity for iconic highlight
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                loading
                    ? _shimmerText(80)
                    : Text(
                        value,
                        style: GoogleFonts.inter(
                          color: AppColors.textLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                if (!loading) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(agentName: _firstName),
                  ),
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryRed,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Agent $_firstName 👋',
                    style: GoogleFonts.inter(
                      color: AppColors.textLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_region.isNotEmpty)
                    Text(
                      _region,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFFFFD700), // Gold tint for visibility
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSalesCard() {
    final textShadow = [
      Shadow(
        offset: const Offset(0, 1),
        blurRadius: 10,
        color: Colors.black.withOpacity(0.7),
      ),
    ];

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/today_sale_card_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TODAY'S SUMMARY",
                        style: GoogleFonts.inter(
                          color: Colors.yellow,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: textShadow,
                        ),
                      ),
                      if (_region.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _region,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<double>(
                          stream: _recordService.watchTodayTotalSales(_agentId),
                          builder: (context, snapshot) {
                            final val = snapshot.data ?? 0.0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Sales",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    shadows: textShadow,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs ${_currency.format(val)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    shadows: textShadow,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: StreamBuilder<double>(
                          stream: _paymentService.watchTodayTotalPayments(
                            _agentId,
                          ),
                          builder: (context, snapshot) {
                            final val = snapshot.data ?? 0.0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Collected",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    shadows: textShadow,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs ${_currency.format(val)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    shadows: textShadow,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerText(double width) {
    return Container(
      width: width,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSectionHeader(String title, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          Icons.receipt_long,
          'Create Invoice',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
          ),
        ),
        _buildActionItem(
          Icons.storefront,
          'Add Shop',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopsScreen()),
          ),
        ),
        _buildActionItem(
          Icons.payments_outlined,
          'Record Payment',
          () => widget.onTabChange(3),
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryRed.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.primaryRed, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentShops() {
    if (_recentShops.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardDarkBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Center(
          child: Text(
            'No shops yet',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _recentShops.length,
        itemBuilder: (context, index) {
          final shop = _recentShops[index];
          return GestureDetector(
            onTap: () => widget.onSalesSearch(shop.name),
            child: GlassCard(
              width: 220,
              margin: EdgeInsets.only(
                right: index == _recentShops.length - 1 ? 0 : 12,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: AppColors.primaryRed,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (shop.hasGps)
                        const Icon(
                          Icons.gps_fixed,
                          color: Colors.greenAccent,
                          size: 12,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shop.name,
                    style: GoogleFonts.inter(
                      color: AppColors.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.address,
                          style: GoogleFonts.inter(
                            color: Colors.grey[300],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
