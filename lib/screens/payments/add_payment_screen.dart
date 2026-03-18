import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/sales_record_model.dart';
import '../../models/shop_model.dart';
import '../../models/sales_payment_model.dart';
import '../../services/sales_record_service.dart';
import '../../services/shop_service.dart';
import '../../services/sales_payment_service.dart';
import '../../services/pdf_invoice_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/premium_background.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final ShopService _shopService = ShopService();
  final SalesRecordService _salesService = SalesRecordService();
  final SalesPaymentService _paymentService = SalesPaymentService();
  final AuthService _authService = AuthService();

  final _currency = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String _actualAgentName = 'Agent';

  List<ShopModel> _shops = [];
  StreamSubscription? _shopSubscription;
  ShopModel? _selectedShop;

  List<SalesRecordModel> _salesRecords = [];
  SalesRecordModel? _selectedRecord;

  final TextEditingController _amountController = TextEditingController();
  String _paymentType = 'full'; // full or partial
  bool _isSaving = false;
  bool _isSaved = false;
  SalesPaymentModel? _lastSavedPayment;
  pw.ImageProvider? _companyLogo;

  @override
  void initState() {
    super.initState();
    _listenToShops();
    _loadAgentName();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      final byteData = await rootBundle.load('assets/images/company_logo.png');
      _companyLogo = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }
  }

  Future<void> _loadAgentName() async {
    final name = await _authService.getAgentFirstName();
    // Re-fetching full name for the invoice
    final profile = await _authService.getAgentProfile();
    if (mounted) {
      setState(() {
        _actualAgentName = profile?['name'] as String? ?? name;
      });
    }
  }

  @override
  void dispose() {
    _shopSubscription?.cancel();
    _amountController.dispose();
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

  Future<void> _loadSalesRecords(String shopId) async {
    // We need to fetch sales records for this shop that are not completed
    // Using a stream for simplicity in this wizard but could be a future
    _salesService.watchShopSalesRecords(_agentId, shopId).first.then((records) {
      if (mounted) {
        setState(() {
          _salesRecords = records
              .where((r) => r.paymentStatus != 'completed')
              .toList();
          _selectedRecord = null;
          _amountController.clear();
        });
      }
    });
  }

  void _onRecordSelected(SalesRecordModel? record) {
    setState(() {
      _selectedRecord = record;
      if (record != null) {
        final balance =
            record.totalAmount - record.totalReturnAmount - record.paidAmount;
        _amountController.text = _paymentType == 'full'
            ? balance.toStringAsFixed(2)
            : '';
      }
    });
  }

  void _onPaymentTypeChanged(String? type) {
    if (type == null) return;
    setState(() {
      _paymentType = type;
      if (_selectedRecord != null) {
        final balance =
            _selectedRecord!.totalAmount -
            _selectedRecord!.totalReturnAmount -
            _selectedRecord!.paidAmount;
        _amountController.text = type == 'full'
            ? balance.toStringAsFixed(2)
            : '';
      }
    });
  }

  Future<void> _savePayment() async {
    if (_selectedShop == null || _selectedRecord == null) {
      ToastHelper.showTopRightToast(context, 'Please select a shop and record');
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final balance =
        _selectedRecord!.totalAmount -
        _selectedRecord!.totalReturnAmount -
        _selectedRecord!.paidAmount;

    if (amount <= 0 || amount > balance) {
      ToastHelper.showTopRightToast(context, 'Invalid payment amount');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payment = SalesPaymentModel(
        id: '', // Will be generated
        salesRecordId: _selectedRecord!.id,
        totalAmount: _selectedRecord!.totalAmount,
        payAmount: amount,
        status: (amount >= balance) ? 'completed' : 'partial',
        createdAt: DateTime.now(),
        agentId: _agentId,
        agentName: _actualAgentName,
        shopId: _selectedShop!.id,
        shopName: _selectedShop!.name,
        paymentType: _paymentType,
      );

      final savedId = await _paymentService.addPayment(
        payment,
        _selectedRecord!,
      );

      setState(() {
        _isSaved = true;
        _isSaving = false;
        _lastSavedPayment = payment.copyWith(id: savedId);

        // Update record to post-payment state for accurate receipt generation
        _selectedRecord = SalesRecordModel(
          id: _selectedRecord!.id,
          shopId: _selectedRecord!.shopId,
          shopName: _selectedRecord!.shopName,
          items: _selectedRecord!.items,
          totalAmount: _selectedRecord!.totalAmount,
          totalReturnAmount: _selectedRecord!.totalReturnAmount,
          createdAt: _selectedRecord!.createdAt,
          paymentStatus: (amount >= balance) ? 'completed' : 'partial',
          paidAmount: _selectedRecord!.paidAmount + amount,
        );
      });

      _showSuccessPopup(amount, balance - amount);
    } catch (e) {
      setState(() => _isSaving = false);
      ToastHelper.showTopRightToast(context, 'Error saving payment: $e');
    }
  }

  void _showSuccessPopup(double paidToday, double netBalance) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.greenAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Recorded!',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _popupItem(
                      'PAID TODAY',
                      'Rs. ${paidToday.toStringAsFixed(0)}',
                      Colors.greenAccent,
                    ),
                    const SizedBox(height: 16),
                    _popupItem(
                      'NET BALANCE',
                      'Rs. ${netBalance.toStringAsFixed(0)}',
                      Colors.white,
                    ),
                  ],
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
                    if (_lastSavedPayment != null && _selectedRecord != null) {
                      PdfInvoiceService.sharePaymentReceipt(
                        _lastSavedPayment!,
                        _selectedRecord!,
                        logo: _companyLogo,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  label: Text(
                    'Download Receipt',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showRecordDetails() {
    if (_selectedRecord == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDarkBackground,
        title: Text(
          'Record Details',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Shop', _selectedRecord!.shopName),
            _detailRow('Date', _dateFormat.format(_selectedRecord!.createdAt)),
            _detailRow(
              'Total',
              'Rs ${_currency.format(_selectedRecord!.totalAmount)}',
            ),
            _detailRow(
              'Already Paid',
              'Rs ${_currency.format(_selectedRecord!.paidAmount)}',
            ),
            if (_selectedRecord!.totalReturnAmount > 0)
              _detailRow(
                'Return Amount',
                'Rs ${_currency.format(_selectedRecord!.totalReturnAmount)}',
              ),
            const Divider(color: AppColors.inputBorder),
            Text(
              'Items:',
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            ..._selectedRecord!.items.map(
              (it) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${it.productName} x ${it.quantity} ${it.unit}',
                  style: GoogleFonts.inter(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
            'Collect Payment',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 300, // Increased bottom padding to scroll buttons higher
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Step 1: Select Shop'),
              _buildShopDropdown(),
              const SizedBox(height: 24),

              if (_selectedShop != null) ...[
                _buildSectionTitle('Step 2: Select Sales Record'),
                _buildRecordDropdown(),
                if (_selectedRecord != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${_dateFormat.format(_selectedRecord!.createdAt)}',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showRecordDetails,
                        icon: const Icon(
                          Icons.receipt_long,
                          size: 16,
                          color: Color(0xFFFFD700),
                        ),
                        label: Text(
                          'View Record',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.inputBorder, height: 32),

                  _buildSectionTitle('Step 3: Payment Details'),
                  _buildPaymentForm(),
                ],
              ],

              const SizedBox(height: 100),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildShopDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedShop?.id,
          dropdownColor: AppColors.cardDarkBackground,
          isExpanded: true,
          hint: Text(
            'Select a shop',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
          items: _shops
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s.id,
                  child: Text(
                    s.name,
                    style: GoogleFonts.inter(color: AppColors.textLight),
                  ),
                ),
              )
              .toList(),
          onChanged: _isSaved
              ? null
              : (id) {
                  if (id != null) {
                    final shop = _shops.firstWhere((s) => s.id == id);
                    setState(() => _selectedShop = shop);
                    _loadSalesRecords(shop.id);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildRecordDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRecord?.id,
          dropdownColor: AppColors.cardDarkBackground,
          isExpanded: true,
          itemHeight: 65,
          menuMaxHeight: 400,
          selectedItemBuilder: (BuildContext context) {
            return _salesRecords.map((r) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Order #${r.id.substring(0, 8).toUpperCase()} - Rs ${_currency.format(r.totalAmount)} - ${_dateFormat.format(r.createdAt)}',
                  style: GoogleFonts.inter(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          hint: Text(
            'Select a record',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
          items: _salesRecords
              .map(
                (r) => DropdownMenuItem<String>(
                  value: r.id,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${r.id.substring(0, 8).toUpperCase()}',
                              style: GoogleFonts.inter(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Rs ${_currency.format(r.totalAmount)}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.shopName,
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              _dateFormat.format(r.createdAt),
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: _isSaved
              ? null
              : (id) {
                  if (id != null) {
                    final record = _salesRecords.firstWhere((r) => r.id == id);
                    _onRecordSelected(record);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    final balance =
        _selectedRecord!.totalAmount -
        _selectedRecord!.totalReturnAmount -
        _selectedRecord!.paidAmount;

    return Column(
      children: [
        _infoCard(
          'Outstanding Balance',
          'Rs ${_currency.format(balance)}',
          AppColors.primaryRed,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(child: _radioOption('Full Payment', 'full')),
            const SizedBox(width: 12),
            Expanded(child: _radioOption('Partial Payment', 'partial')),
          ],
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _amountController,
          enabled: !_isSaved && _paymentType == 'partial',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Paying Amount (Rs)',
            labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(
              Icons.account_balance_wallet,
              color: Colors.greenAccent,
            ),
          ),
          onChanged: (val) {
            setState(() {}); // Refresh pending amount
          },
        ),

        const SizedBox(height: 12),
        if (_selectedRecord != null) _buildPendingAmountInfo(balance),
      ],
    );
  }

  Widget _buildPendingAmountInfo(double balance) {
    final paying = double.tryParse(_amountController.text) ?? 0.0;
    final remaining = balance - paying;
    if (remaining < 0) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Remaining Balance: ',
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        ),
        Text(
          'Rs ${_currency.format(remaining)}',
          style: GoogleFonts.inter(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textMuted)),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _radioOption(String label, String value) {
    bool isSelected = _paymentType == value;
    return GestureDetector(
      onTap: _isSaved ? null : () => _onPaymentTypeChanged(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryRed.withOpacity(0.1)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? AppColors.primaryRed : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isSaved)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_lastSavedPayment != null && _selectedRecord != null) {
                  PdfInvoiceService.sharePaymentReceipt(
                    _lastSavedPayment!,
                    _selectedRecord!,
                    logo: _companyLogo,
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: Text(
                'Generate Invoice',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _savePayment,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Save Payment',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.inputBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isSaved ? 'Go Back' : 'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
