import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/sales_record_model.dart';
import '../../models/shop_model.dart';
import '../../services/sales_record_service.dart';
import '../../services/shop_service.dart';
import '../../services/pdf_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'add_payment_screen.dart';
import '../../widgets/premium_background.dart';
import '../../widgets/toast_helper.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final SalesRecordService _salesService = SalesRecordService();
  final ShopService _shopService = ShopService();
  final AuthService _authService = AuthService();
  final _currency = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String _agentName = 'Agent';
  pw.ImageProvider? _logoImage;

  ShopModel? _selectedShop;
  List<ShopModel> _shops = [];
  StreamSubscription? _shopSubscription;

  @override
  void initState() {
    super.initState();
    _listenToShops();
    _loadAgentInfo();
    _loadLogo();
  }

  Future<void> _loadAgentInfo() async {
    final profile = await _authService.getAgentProfile();
    if (mounted && profile != null) {
      setState(() => _agentName = profile['name'] ?? 'Agent');
    }
  }

  Future<void> _loadLogo() async {
    try {
      final byteData = await rootBundle.load('assets/images/company_logo.png');
      _logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }
  }

  @override
  void dispose() {
    _shopSubscription?.cancel();
    super.dispose();
  }

  void _listenToShops() {
    _shopSubscription = _shopService.watchAgentShops(_agentId).listen((shops) {
      if (mounted) {
        setState(() {
          _shops = shops;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Payments',
              style: GoogleFonts.inter(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: TabBar(
              indicatorColor: AppColors.primaryRed,
              labelColor: AppColors.primaryRed,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
                Tab(text: 'All'),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildShopSelector(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPaymentList('pending'),
                    _buildPaymentList('completed'),
                    _buildPaymentList('all'),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'payments_fab',
            backgroundColor: AppColors.primaryRed,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPaymentScreen()),
            ),
            icon: const Icon(Icons.add_card, color: Colors.white),
            label: Text(
              'Add Payment',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardDarkBackground.withOpacity(0.5),
      child: Row(
        children: [
          Text(
            'Filter by Shop:',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ShopModel?>(
                value: _selectedShop,
                dropdownColor: AppColors.cardDarkBackground,
                isExpanded: true,
                hint: Text(
                  'All Shops',
                  style: GoogleFonts.inter(color: AppColors.textLight),
                ),
                items: [
                  DropdownMenuItem<ShopModel?>(
                    value: null,
                    child: Text(
                      'All Shops',
                      style: GoogleFonts.inter(color: AppColors.textLight),
                    ),
                  ),
                  ..._shops.map(
                    (shop) => DropdownMenuItem(
                      value: shop,
                      child: Text(
                        shop.name,
                        style: GoogleFonts.inter(color: AppColors.textLight),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedShop = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(String filterStatus) {
    return StreamBuilder<List<SalesRecordModel>>(
      stream: _selectedShop == null
          ? _salesService.watchSalesRecords(_agentId)
          : _salesService.watchShopSalesRecords(_agentId, _selectedShop!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          );
        }

        var records = snapshot.data ?? [];

        // Apply Status Filter
        if (filterStatus == 'pending') {
          records = records
              .where((r) => r.paymentStatus != 'completed')
              .toList();
        } else if (filterStatus == 'completed') {
          records = records
              .where((r) => r.paymentStatus == 'completed')
              .toList();
        }

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: AppColors.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No ${filterStatus == 'all' ? '' : filterStatus} payments found.',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ],
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
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildPaymentCard(records[index]),
        );
      },
    );
  }

  Widget _buildPaymentCard(SalesRecordModel record) {
    bool isCompleted = record.paymentStatus == 'completed';
    bool isPartial = record.paymentStatus == 'partial';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.greenAccent.withOpacity(0.3)
              : (isPartial
                    ? Colors.orangeAccent.withOpacity(0.3)
                    : AppColors.primaryRed.withOpacity(0.2)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.shopName,
                        style: GoogleFonts.inter(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _dateFormat.format(record.createdAt),
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(record.paymentStatus),
              ],
            ),
            const Divider(color: AppColors.inputBorder, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _amountColumn('Total', record.totalAmount, AppColors.textLight),
                _amountColumn('Paid', record.paidAmount, Colors.greenAccent),
                _amountColumn(
                  'Balance',
                  record.totalAmount - record.paidAmount,
                  isCompleted ? AppColors.textMuted : AppColors.primaryRed,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _generateInvoice(record),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white70, size: 18),
                label: Text(
                  'Invoice',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateInvoice(SalesRecordModel record) async {
    try {
      // Get full shop details if available
      final shop = _shops.firstWhere(
        (s) => s.id == record.shopId,
        orElse: () => ShopModel(
          id: record.shopId,
          name: record.shopName,
          address: 'N/A',
          phone: 'N/A',
          uniqueId: 'N/A',
          whatsapp: 'N/A',
          email: 'N/A',
          agentId: _agentId,
          createdAt: DateTime.now(),
        ),
      );

      await PdfService.shareOrPrintInvoice(
        record: record,
        agentName: _agentName,
        agentId: _agentId,
        shop: shop,
        logo: _logoImage,
      );
    } catch (e) {
      ToastHelper.showTopRightToast(context, 'Error generating invoice: $e');
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = Colors.greenAccent;
        label = 'COMPLETED';
        break;
      case 'partial':
        color = Colors.orangeAccent;
        label = 'PARTIAL';
        break;
      default:
        color = AppColors.primaryRed;
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _amountColumn(String label, double amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
        ),
        Text(
          'Rs ${_currency.format(amount)}',
          style: GoogleFonts.inter(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
