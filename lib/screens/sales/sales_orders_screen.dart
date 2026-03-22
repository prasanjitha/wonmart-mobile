import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/sales_record_model.dart';
import '../../services/sales_record_service.dart';
import '../../services/pdf_service.dart';
import '../../services/auth_service.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import 'create_order_screen.dart';
import '../../widgets/premium_background.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../widgets/toast_helper.dart';

class SalesOrdersScreen extends StatefulWidget {
  final String? initialSearchQuery;
  const SalesOrdersScreen({super.key, this.initialSearchQuery});

  @override
  State<SalesOrdersScreen> createState() => _SalesOrdersScreenState();
}

class _SalesOrdersScreenState extends State<SalesOrdersScreen> {
  final SalesRecordService _salesRecordService = SalesRecordService();
  final AuthService _authService = AuthService();
  final ShopService _shopService = ShopService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _currency = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
      _searchQuery = widget.initialSearchQuery!.toLowerCase();
    }
  }

  @override
  void didUpdateWidget(covariant SalesOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSearchQuery != oldWidget.initialSearchQuery &&
        widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
      _searchQuery = widget.initialSearchQuery!.toLowerCase();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteOrder(SalesRecordModel record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDarkBackground,
          title: Text(
            'Delete Sales Record?',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This will return the items to stock and remove any related payments. This action cannot be undone.',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryRed.withOpacity(0.1),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: AppColors.primaryRed),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _salesRecordService.deleteSalesRecord(_agentId, record);
        if (mounted) {
          ToastHelper.showTopRightToast(context, 'Sales record deleted');
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showTopRightToast(context, 'Error deleting record: $e');
        }
      }
    }
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
            'Sales Orders',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.add,
                color: AppColors.primaryRed,
                size: 28,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: AppColors.textLight),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by shop name...',
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
              child: StreamBuilder<List<SalesRecordModel>>(
                stream: _salesRecordService.watchSalesRecords(_agentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    );
                  }
                  final all = snapshot.data ?? [];
                  final records = _searchQuery.isEmpty
                      ? all
                      : all
                            .where(
                              (r) => r.shopName.toLowerCase().contains(
                                _searchQuery,
                              ),
                            )
                            .toList();

                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.textMuted,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No records yet.\nTap + to create a new order.'
                                : 'No records for "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                            ),
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
                      bottom: 100, // Extra padding for FAB and Nav Bar
                    ),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildOrderCard(records[i]),
                  );
                },
              ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'sales_fab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
          ),
          backgroundColor: AppColors.primaryRed,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add sales',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(SalesRecordModel record) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            title: Text(
              record.shopName,
              style: GoogleFonts.inter(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateFormat.format(record.createdAt),
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${record.items.length} item(s)',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            trailing: Text(
              'Rs ${_currency.format(record.totalAmount)}',
              style: GoogleFonts.inter(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionBtn(
                  Icons.receipt_long_outlined,
                  'Invoice',
                  AppColors.textMuted,
                  () => _generateDetailedInvoice(record),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  Icons.delete_outline,
                  'Delete',
                  AppColors.primaryRed,
                  () => _deleteOrder(record),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  Icons.visibility_outlined,
                  'Details',
                  const Color(0xFFFFD700),
                  () => _showDetailsDialog(record),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(SalesRecordModel record) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDarkBackground,
        title: Text(
          'Order Details',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop: ${record.shopName}',
                  style: GoogleFonts.inter(color: AppColors.textLight),
                ),
                Text(
                  'Date: ${_dateFormat.format(record.createdAt)}',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const Divider(color: AppColors.inputBorder, height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 12,
                    horizontalMargin: 0,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Item',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Qty',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Price',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Total',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                    rows: record.items
                        .map(
                          (i) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  i.productName,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  i.quantity.toString(),
                                  style: GoogleFonts.inter(
                                    color: AppColors.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  i.price.toStringAsFixed(0),
                                  style: GoogleFonts.inter(
                                    color: AppColors.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  i.totalPrice.toStringAsFixed(0),
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFFD700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                const Divider(color: AppColors.inputBorder, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: GoogleFonts.inter(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs ${_currency.format(record.totalAmount)}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _generateDetailedInvoice(record),
            child: Text(
              'Generate Invoice',
              style: GoogleFonts.inter(color: const Color(0xFFFFD700)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateDetailedInvoice(SalesRecordModel record) async {
    try {
      // 1. Load Agent Profile
      final profile = await _authService.getAgentProfile();
      final agentName = profile?['name'] ?? 'Agent';
      final agentId = FirebaseAuth.instance.currentUser?.uid ?? 'N/A';

      // 2. Load Shop Details
      final shop = await _shopService.getShopById(record.shopId);

      // 3. Load Logo
      pw.ImageProvider? logoImage;
      try {
        final byteData = await rootBundle.load(
          'assets/images/company_logo.png',
        );
        logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Error loading logo: $e');
      }

      // 4. Generate and Layout PDF
      // Note: We use PdfService.generateInvoice directly withPrinting.layoutPdf for consistency
      // Or we can use PdfService.shareOrPrintInvoice if that's what's preferred
      final pdfBytes = await PdfService.generateInvoice(
        record: record,
        agentName: agentName,
        agentId: agentId,
        shop: shop,
        paidAmount: record.paidAmount,
        paymentStatus: record.paymentStatus,
        logo: logoImage,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'invoice_${record.shopName.replaceAll(' ', '_')}',
      );
    } catch (e) {
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Error generating invoice: $e');
      }
    }
  }
}
