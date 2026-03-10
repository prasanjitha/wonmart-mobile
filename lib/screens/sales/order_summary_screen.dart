import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/sales_record_model.dart';
import '../../services/sales_record_service.dart';
import '../../services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/shop_model.dart';
import '../../theme/app_colors.dart';
import '../../services/pdf_service.dart';
import '../../services/shop_service.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/premium_background.dart';
import '../home_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final SalesRecordModel record;

  const OrderSummaryScreen({super.key, required this.record});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final SalesRecordService _salesRecordService = SalesRecordService();
  final AuthService _authService = AuthService();
  final ShopService _shopService = ShopService();

  final TextEditingController _paidAmountController = TextEditingController();
  String _paymentType = 'Cash';
  String _paymentStatus = 'Partial Payment';
  bool _isSaving = false;
  bool _showDetails = false;
  String _agentName = 'Agent';
  ShopModel? _shopDetails;

  final _currency = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadAgentName();
    _loadShopDetails();
    _paidAmountController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadShopDetails() async {
    try {
      final shop = await _shopService.getShopById(widget.record.shopId);
      if (mounted) {
        setState(() {
          _shopDetails = shop;
        });
      }
    } catch (e) {
      debugPrint('Error loading shop details: $e');
    }
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadAgentName() async {
    final profile = await _authService.getAgentProfile();
    if (profile != null) {
      if (mounted) {
        setState(() {
          _agentName = profile['name'] ?? 'Agent';
        });
      }
    }
  }

  void _onStatusChanged(String? newStatus) {
    if (newStatus == null) return;
    setState(() {
      _paymentStatus = newStatus;
      if (newStatus == 'Full Payment') {
        _paidAmountController.text = widget.record.totalAmount.toStringAsFixed(
          2,
        );
      } else if (newStatus == 'Not Paid') {
        _paidAmountController.text = '0';
      }
    });
  }

  double get _dueAmount {
    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return widget.record.totalAmount - paid;
  }

  Future<void> _confirmIssuance() async {
    if (_paymentStatus == 'Partial Payment') {
      final enteredAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
      if (enteredAmount <= 0) {
        ToastHelper.showTopRightToast(
          context,
          'Please enter a valid amount for Partial Payment',
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final agentId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String dbStatus = 'pending';
      if (_paymentStatus == 'Full Payment') dbStatus = 'completed';
      if (_paymentStatus == 'Partial Payment') dbStatus = 'partial';
      if (_paymentStatus == 'Not Paid') dbStatus = 'pending';

      await _salesRecordService.issueOrderWithPayment(
        agentId: agentId,
        agentName: _agentName,
        record: widget.record,
        paymentType: _paymentType,
        paymentStatus: dbStatus,
        paidAmount: double.tryParse(_paidAmountController.text) ?? 0.0,
      );

      if (!mounted) return;
      _showSuccessPopup();
    } catch (e) {
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textLight),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Issuance Cart',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Agent & Shop Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkBackground.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
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
                              'Shop Name',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              widget.record.shopName,
                              style: GoogleFonts.inter(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Date',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'dd MMM yyyy',
                              ).format(widget.record.createdAt),
                              style: GoogleFonts.inter(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.inputBorder, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Shop Price',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                        Text(
                          'Rs ${_currency.format(widget.record.totalAmount)}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // View Details Button
              InkWell(
                onTap: () => setState(() => _showDetails = !_showDetails),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showDetails ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showDetails ? 'Hide Details' : 'View Details',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showDetails) ...[
                const SizedBox(height: 8),
                ...widget.record.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDarkBackground.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: GoogleFonts.inter(
                              color: AppColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${item.quantity} x Rs ${item.agentPrice.toStringAsFixed(0)} (Shop Price)',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Payment Details Section
              Text(
                'PAYMENT DETAILS',
                style: GoogleFonts.inter(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkBackground.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Type',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _paymentType,
                                isExpanded: true,
                                dropdownColor: AppColors.cardDarkBackground,
                                underline: const SizedBox(),
                                items: ['Cash', 'Online', 'Cheque']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: GoogleFonts.inter(
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _paymentType = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Status',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              DropdownButton<String>(
                                value: _paymentStatus,
                                isExpanded: true,
                                dropdownColor: AppColors.cardDarkBackground,
                                underline: const SizedBox(),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textLight,
                                ),
                                items:
                                    [
                                          'Full Payment',
                                          'Partial Payment',
                                          'Not Paid',
                                        ]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              e,
                                              style: GoogleFonts.inter(
                                                color: e == 'Full Payment'
                                                    ? Colors.green
                                                    : (e == 'Not Paid'
                                                          ? Colors.red
                                                          : Colors.orange),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: _onStatusChanged,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: AppColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Paid Amount (Rs.)',
                        labelStyle: GoogleFonts.inter(
                          color: AppColors.textMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Due Amount:',
                            style: GoogleFonts.inter(color: Colors.red),
                          ),
                          Text(
                            'Rs ${_currency.format(_dueAmount)}',
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _confirmIssuance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Confirm Issuance',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textMuted),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
                label: Text(
                  'Go Back',
                  style: GoogleFonts.inter(color: AppColors.textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Issuance items success',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close popup
                    _generateAndPreviewPdf();
                    // Navigate to Home screen -> Sales tab (index 1)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(initialIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  label: Text(
                    'Generate Invoice',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  Future<void> _generateAndPreviewPdf() async {
    try {
      final agentId = FirebaseAuth.instance.currentUser?.uid ?? 'N/A';
      final currentPaidAmount =
          double.tryParse(_paidAmountController.text) ?? 0.0;

      // Load company logo
      pw.ImageProvider? logoImage;
      try {
        final byteData = await rootBundle.load(
          'assets/images/company_logo.png',
        );
        logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Error loading logo: $e');
      }

      final pdfBytes = await PdfService.generateInvoice(
        record: widget.record,
        agentName: _agentName,
        agentId: agentId,
        shop: _shopDetails,
        paidAmount: currentPaidAmount,
        paymentStatus: _paymentStatus,
        logo: logoImage,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'invoice_${widget.record.shopName.replaceAll(' ', '_')}',
      );
    } catch (e) {
      ToastHelper.showTopRightToast(context, 'Error generating PDF: $e');
    }
  }
}
