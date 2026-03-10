import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/store_models.dart';
import '../services/store_service.dart';
import '../services/sales_record_service.dart';
import '../models/issuing_summary_model.dart';
import '../models/sales_record_model.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_background.dart';

class StoreTab extends StatefulWidget {
  const StoreTab({super.key});

  @override
  State<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends State<StoreTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final StoreService _storeService = StoreService();
  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Store',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryRed,
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: 'My Store'),
              Tab(text: 'Store History'),
              Tab(text: 'Issuing Overview'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMyStoreTab(),
            _buildHistoryTab(),
            _IssuingOverviewTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStoreTab() {
    return StreamBuilder<List<StoreItemModel>>(
      stream: _storeService.watchAgentStore(_agentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          );
        }
        final allItems = snapshot.data ?? [];
        final items = _searchQuery.isEmpty
            ? allItems
            : allItems
                  .where(
                    (i) => i.productName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: AppColors.textLight),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No items in store'
                            : 'No products matching "$_searchQuery"',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 100,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardDarkBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryRed.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppColors.primaryRed,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: GoogleFonts.inter(
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Unit: ${item.unit}',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.quantity}',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<StoreHistoryModel>>(
      stream: _storeService.watchStoreHistory(_agentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          );
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Center(
            child: Text(
              'No history available',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = history[index];
            return _HistoryCard(entry: entry);
          },
        );
      },
    );
  }
}

class _IssuingOverviewTab extends StatefulWidget {
  @override
  State<_IssuingOverviewTab> createState() => _IssuingOverviewTabState();
}

class _IssuingOverviewTabState extends State<_IssuingOverviewTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isAllProductsView = true;
  String? _selectedProductId;
  List<SalesRecordModel> _filteredRecords = [];
  bool _isLoading = false;

  final SalesRecordService _recordService = SalesRecordService();
  final StoreService _storeService = StoreService();
  final _currency = NumberFormat('#,##0', 'en_US');

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final records = await _recordService.getSalesRecordsInRange(
        _agentId,
        _startDate,
        _endDate,
      );
      setState(() {
        _filteredRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryRed,
            onPrimary: Colors.white,
            surface: AppColors.cardDarkBackground,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
              : _buildAggregationSummary(),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Stock Payments Summary',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aggregate issuances by product over a specified date range.',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          // Date pickers row
          Row(
            children: [
              // Start Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('START DATE', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(DateFormat('MM/dd/yyyy').format(_startDate), style: GoogleFonts.inter(color: Colors.white, fontSize: 12))),
                            const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // End Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('END DATE', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(DateFormat('MM/dd/yyyy').format(_endDate), style: GoogleFonts.inter(color: Colors.white, fontSize: 12))),
                            const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // View Toggles row
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton('All Products', _isAllProductsView, () {
                    setState(() {
                      _isAllProductsView = true;
                      _selectedProductId = null;
                    });
                  }),
                ),
                Expanded(
                  child: _buildToggleButton('By Product', !_isAllProductsView, () {
                    setState(() => _isAllProductsView = false);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.greenAccent.withOpacity(0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: active ? Colors.black : AppColors.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAggregationSummary() {
    return FutureBuilder<List<StoreItemModel>>(
      future: _storeService.getAgentStore(_agentId),
      builder: (context, stockSnapshot) {
        if (!stockSnapshot.hasData) return const SizedBox();

        final Map<String, IssuingProductSummary> summaries = {};
        
        for (var record in _filteredRecords) {
          for (var item in record.items) {
            final stockItem = stockSnapshot.data!.firstWhere(
              (s) => s.id == item.productId,
              orElse: () => StoreItemModel(
                id: item.productId,
                productName: item.productName,
                unit: item.unit,
                quantity: 0,
                price: item.agentPrice,
                lastUpdated: DateTime.now(),
              ),
            );

            if (summaries.containsKey(item.productId)) {
              final existing = summaries[item.productId]!;
              summaries[item.productId] = IssuingProductSummary(
                productId: item.productId,
                productName: item.productName,
                unit: item.unit,
                warehouseStock: stockItem.quantity,
                qtyIssued: existing.qtyIssued + item.quantity,
                expectedRs: existing.expectedRs + (item.quantity * item.agentPrice),
              );
            } else {
              summaries[item.productId] = IssuingProductSummary(
                productId: item.productId,
                productName: item.productName,
                unit: item.unit,
                warehouseStock: stockItem.quantity,
                qtyIssued: item.quantity,
                expectedRs: item.quantity * item.agentPrice,
              );
            }
          }
        }

        if (_isAllProductsView) {
          double grandTotal = 0;
          for (var s in summaries.values) {
            grandTotal += s.expectedRs;
          }
          
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDarkBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ALL PRODUCTS SUMMARY', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(
                      '${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 24),
                // Table Header
                Row(
                  children: [
                    Expanded(flex: 3, child: Text('PRODUCT NAME', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('WAREHOUSE STOCK', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('QTY ISSUED', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('EXPECTED RS.', textAlign: TextAlign.right, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 12),
                ...summaries.values.map((s) => _buildProductSummaryRow(s)),
                const Divider(color: Colors.white10, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('GRAND TOTAL:', style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 24),
                    Text(
                      'Rs. ${_currency.format(grandTotal)}',
                      style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          // By Product View
          if (_selectedProductId == null && summaries.isNotEmpty) {
            _selectedProductId = summaries.keys.first;
          }
          
          final selectedSummary = summaries[_selectedProductId];
          final shopDetails = _getShopDetailsForProduct(_selectedProductId);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Product Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProductId,
                      dropdownColor: AppColors.cardDarkBackground,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      isExpanded: true,
                      items: summaries.values.map((s) {
                        return DropdownMenuItem(
                          value: s.productId,
                          child: Text(s.productName, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedProductId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedSummary != null)
                  Row(
                    children: [
                      _buildSummaryStatCard('STOCK', '${selectedSummary.warehouseStock}', Colors.white),
                      const SizedBox(width: 8),
                      _buildSummaryStatCard('ISSUED', '${selectedSummary.qtyIssued}', Colors.greenAccent),
                      const SizedBox(width: 8),
                      _buildSummaryStatCard('EXPECTED', 'Rs. ${_currency.format(selectedSummary.expectedRs)}', Colors.greenAccent, flex: 2),
                    ],
                  ),
                const SizedBox(height: 16),
                // Shop List Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('SHOP', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('MARGIN', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('EXPECTED', textAlign: TextAlign.right, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('STATUS', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: ListView(
                    children: shopDetails.map((sd) => _buildShopDetailRow(sd)).toList(),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildProductSummaryRow(IssuingProductSummary s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.productName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(s.productId, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text('${s.warehouseStock}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 12))),
          Expanded(flex: 2, child: Text('${s.qtyIssued}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text('Rs. ${_currency.format(s.expectedRs)}', textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSummaryStatCard(String label, String value, Color color, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDarkBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(color: color, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildShopDetailRow(IssuingShopDetail sd) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(sd.shopName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Text('${sd.margin.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.deepPurpleAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text('${sd.qty}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text('Rs. ${_currency.format(sd.expected)}', textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sd.status,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: sd.status == 'COMPLETED' ? Colors.greenAccent : (sd.status == 'PENDING' ? Colors.orangeAccent : (sd.status == 'PARTIAL' ? Colors.amberAccent : Colors.white24)),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),

              ),
            ),
          ),
        ],
      ),
    );
  }

  List<IssuingShopDetail> _getShopDetailsForProduct(String? productId) {
    if (productId == null) return [];
    
    final Map<String, IssuingShopDetail> shopMap = {};
    
    for (var record in _filteredRecords) {
      for (var item in record.items) {
        if (item.productId == productId) {
          final expected = item.quantity * item.agentPrice;
          final margin = item.price > 0 ? ((item.price - item.agentPrice) / item.price * 100) : 0.0;
          
          if (shopMap.containsKey(record.shopId)) {
            final existing = shopMap[record.shopId]!;
            shopMap[record.shopId] = IssuingShopDetail(
              shopId: record.shopId,
              shopName: record.shopName,
              margin: margin,
              qty: existing.qty + item.quantity,
              expected: existing.expected + expected,
              status: record.paymentStatus == 'completed' ? 'COMPLETED' : (record.paymentStatus == 'pending' ? 'PENDING' : (record.paymentStatus == 'partial' ? 'PARTIAL' : 'UNKNOWN')),
            );
          } else {
            shopMap[record.shopId] = IssuingShopDetail(
              shopId: record.shopId,
              shopName: record.shopName,
              margin: margin,
              qty: item.quantity,
              expected: expected,
              status: record.paymentStatus == 'completed' ? 'COMPLETED' : (record.paymentStatus == 'pending' ? 'PENDING' : (record.paymentStatus == 'partial' ? 'PARTIAL' : 'UNKNOWN')),
            );
          }
        }
      }
    }
    
    return shopMap.values.toList();
  }

}

class _HistoryCard extends StatefulWidget {
  final StoreHistoryModel entry;
  const _HistoryCard({required this.entry});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.entry.date);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get Items',
                        style: GoogleFonts.inter(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.entry.id}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Date: $dateStr | Time: ${widget.entry.time}',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    _isExpanded ? 'Hide Details' : 'View Details',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.inputBorder)),
              ),
              child: Column(
                children: widget.entry.products.map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.productName,
                          style: GoogleFonts.inter(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${p.quantity} ${p.unit}',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
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
    );
  }
}
