import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/shop_model.dart';
import '../../models/store_models.dart';
import '../../services/shop_service.dart';
import '../../services/store_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/premium_background.dart';
import 'order_summary_screen.dart';
import '../../models/sales_record_model.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final ShopService _shopService = ShopService();
  final StoreService _storeService = StoreService();

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  List<ShopModel> _shops = [];
  List<StoreItemModel> _storeItems = [];
  ShopModel? _selectedShop;
  StoreItemModel? _selectedProduct;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _marginController = TextEditingController();
  final TextEditingController _sellerPriceController = TextEditingController();

  String _pricingMode = 'Margin'; // 'Margin' or 'Seller Price'

  // Order items list
  final List<SalesRecordItem> _orderRows = [];

  // Return items state
  StoreItemModel? _selectedReturnProduct;
  final TextEditingController _returnQuantityController =
      TextEditingController();
  final TextEditingController _returnPriceController = TextEditingController();
  final List<SalesRecordItem> _returnRows = [];
  String? _selectedReturnReason;
  final TextEditingController _otherReturnReasonController =
      TextEditingController();
  bool _isAddedToStock = false;

  final List<String> _returnReasons = [
    'damaged',
    'expired',
    'overstock',
    'other',
  ];

  bool _isLoading = true;
  bool _isSaving = false;

  final _currency = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final shops = await _shopService.getAgentShops(_agentId);
    final storeItems = await _storeService.getAgentStore(_agentId);
    setState(() {
      _shops = shops;
      _storeItems = storeItems.where((i) => i.quantity > 0).toList();
      _isLoading = false;
    });
  }

  double get _total =>
      _orderRows.fold(0, (sum, item) => sum + item.totalAgentPrice);
  double get _totalProfit =>
      _orderRows.fold(0, (sum, item) => sum + item.totalProfit);
  double get _totalReturnAmount =>
      _returnRows.fold(0, (sum, item) => sum + item.totalAgentPrice);

  void _addItem() {
    if (_selectedProduct == null) {
      ToastHelper.showTopRightToast(context, 'Please select a product');
      return;
    }
    final qty = int.tryParse(_quantityController.text) ?? 0;

    if (qty <= 0) {
      ToastHelper.showTopRightToast(context, 'Enter a valid quantity');
      return;
    }
    if (qty > _selectedProduct!.quantity) {
      ToastHelper.showTopRightToast(context, 'Not enough stock');
      return;
    }

    final retailPrice = _selectedProduct!.price;
    double agentPrice;
    double margin;

    if (_pricingMode == 'Margin') {
      margin = double.tryParse(_marginController.text) ?? 0.0;
      agentPrice = retailPrice * (1 - margin / 100);
    } else {
      agentPrice = double.tryParse(_sellerPriceController.text) ?? retailPrice;
      margin = retailPrice > 0
          ? ((retailPrice - agentPrice) / retailPrice) * 100
          : 0.0;
    }

    final totalRetailPrice = qty * retailPrice;
    final totalAgentPrice = qty * agentPrice;
    final totalProfit = totalRetailPrice - totalAgentPrice;

    setState(() {
      _orderRows.add(
        SalesRecordItem(
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.productName,
          quantity: qty,
          unit: _selectedProduct!.unit,
          price: retailPrice,
          totalPrice: totalRetailPrice,
          marginPercentage: margin,
          agentPrice: agentPrice,
          totalAgentPrice: totalAgentPrice,
          totalProfit: totalProfit,
        ),
      );
      _quantityController.clear();
      _marginController.clear();
      _sellerPriceController.clear();
      _selectedProduct = null;
    });
  }

  void _addReturnItem() {
    if (_selectedReturnProduct == null) {
      ToastHelper.showTopRightToast(
        context,
        'Please select a product to return',
      );
      return;
    }
    if (_selectedReturnReason == null) {
      ToastHelper.showTopRightToast(context, 'Please select a return reason');
      return;
    }
    if (_selectedReturnReason == 'other' &&
        _otherReturnReasonController.text.trim().isEmpty) {
      ToastHelper.showTopRightToast(context, 'Please enter a reason');
      return;
    }
    final qty = int.tryParse(_returnQuantityController.text) ?? 0;

    if (qty <= 0) {
      ToastHelper.showTopRightToast(context, 'Enter a valid quantity');
      return;
    }

    final returnPrice = double.tryParse(_returnPriceController.text) ?? 0.0;
    if (returnPrice <= 0) {
      ToastHelper.showTopRightToast(context, 'Enter a valid return price');
      return;
    }

    final totalReturnPrice = qty * returnPrice;
    final String returnReason = _selectedReturnReason == 'other'
        ? _otherReturnReasonController.text.trim()
        : _selectedReturnReason!;

    setState(() {
      _returnRows.add(
        SalesRecordItem(
          productId: _selectedReturnProduct!.id,
          productName: _selectedReturnProduct!.productName,
          quantity: qty,
          unit: _selectedReturnProduct!.unit,
          price: returnPrice,
          totalPrice: totalReturnPrice,
          marginPercentage: 0.0,
          agentPrice: returnPrice,
          totalAgentPrice: totalReturnPrice,
          totalProfit: 0.0,
          returnReason: returnReason,
          isAddedToStock: _isAddedToStock,
        ),
      );
      _returnQuantityController.clear();
      _returnPriceController.clear();
      _selectedReturnProduct = null;
      _selectedReturnReason = null;
      _otherReturnReasonController.clear();
      _isAddedToStock = false;
    });
  }

  void _removeRow(int index) {
    setState(() => _orderRows.removeAt(index));
  }

  void _removeReturnRow(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDarkBackground,
        title: Text(
          'Delete Item',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
        content: Text(
          'Are you sure remove this item?',
          style: GoogleFonts.inter(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _returnRows.removeAt(index));
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  void _updateReturnRow(
    int index, {
    int? quantity,
    double? price,
    String? returnReason,
    bool? isAddedToStock,
  }) {
    setState(() {
      final item = _returnRows[index];
      final updatedQuantity = quantity ?? item.quantity;
      final updatedPrice = price ?? item.price;

      final updatedTotalReturnPrice = updatedQuantity * updatedPrice;

      _returnRows[index] = item.copyWith(
        quantity: updatedQuantity,
        price: updatedPrice,
        totalPrice: updatedTotalReturnPrice,
        agentPrice: updatedPrice,
        totalAgentPrice: updatedTotalReturnPrice,
        returnReason: returnReason,
        isAddedToStock: isAddedToStock,
      );
    });
  }

  void _updateRow(
    int index, {
    int? quantity,
    double? price,
    double? margin,
    String? mode,
    double? sellerPrice,
  }) {
    setState(() {
      final item = _orderRows[index];
      final updatedQuantity = quantity ?? item.quantity;
      final updatedPrice = price ?? item.price; // Retail Price

      double updatedMargin;
      double updatedAgentPrice;

      if (mode == 'Seller Price' && sellerPrice != null) {
        updatedAgentPrice = sellerPrice;
        updatedMargin = updatedPrice > 0
            ? ((updatedPrice - updatedAgentPrice) / updatedPrice) * 100
            : 0.0;
      } else {
        updatedMargin = margin ?? item.marginPercentage;
        updatedAgentPrice = updatedPrice * (1 - updatedMargin / 100);
      }

      final updatedTotalRetailPrice = updatedQuantity * updatedPrice;
      final updatedTotalAgentPrice = updatedQuantity * updatedAgentPrice;
      final updatedTotalProfit =
          updatedTotalRetailPrice - updatedTotalAgentPrice;

      _orderRows[index] = item.copyWith(
        quantity: updatedQuantity,
        price: updatedPrice,
        totalPrice: updatedTotalRetailPrice,
        marginPercentage: updatedMargin,
        agentPrice: updatedAgentPrice,
        totalAgentPrice: updatedTotalAgentPrice,
        totalProfit: updatedTotalProfit,
      );
    });
  }

  Future<void> _confirmOrder() async {
    if (_selectedShop == null) {
      ToastHelper.showTopRightToast(context, 'Please select a shop');
      return;
    }
    if (_orderRows.isEmpty) {
      ToastHelper.showTopRightToast(context, 'Add at least one product');
      return;
    }

    // Check if return fields are partially filled but not added
    final hasReturnProduct = _selectedReturnProduct != null;
    final hasReturnQty = _returnQuantityController.text.trim().isNotEmpty;
    final hasReturnPrice = _returnPriceController.text.trim().isNotEmpty;
    if (hasReturnProduct || hasReturnQty || hasReturnPrice) {
      ToastHelper.showTopRightToast(
        context,
        'You have unsaved return items. Please click "Add Return" first.',
      );
      return;
    }

    final record = SalesRecordModel(
      id: '',
      shopId: _selectedShop!.id,
      shopName: _selectedShop!.name,
      items: _orderRows,
      returnItems: _returnRows,
      totalAmount: _total,
      totalReturnAmount: _totalReturnAmount,
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
        ),
      );
    }

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
            'Create Sales Order',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shop selector
                    _buildSectionLabel('Select Shop'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ShopModel>(
                          value: _selectedShop,
                          hint: Text(
                            'Choose a shop',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                            ),
                          ),
                          dropdownColor: AppColors.inputBackground,
                          isExpanded: true,
                          items: _shops
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s.name,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedShop = v),
                        ),
                      ),
                    ),

                    // Add Product Section
                    _buildSectionLabel('Add Product'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDarkBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Column(
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<StoreItemModel>(
                              value: _selectedProduct,
                              hint: Text(
                                'Select a product',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              dropdownColor: AppColors.inputBackground,
                              isExpanded: true,
                              items: _storeItems
                                  .map(
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        '${i.productName} (Qty: ${i.quantity})',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedProduct = v),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSectionLabel('Pricing Mode'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _pricingMode,
                                      dropdownColor: AppColors.inputBackground,
                                      isExpanded: true,
                                      items: ['Margin', 'Seller Price']
                                          .map(
                                            (m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(
                                                'By $m',
                                                style: GoogleFonts.inter(
                                                  color: AppColors.textLight,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _pricingMode = v);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textLight,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Qty',
                                    hintStyle: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: _pricingMode == 'Margin'
                                    ? TextField(
                                        controller: _marginController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: GoogleFonts.inter(
                                          color: AppColors.textLight,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Margin %',
                                          hintStyle: GoogleFonts.inter(
                                            color: AppColors.textMuted,
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.inputBackground,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                        ),
                                      )
                                    : TextField(
                                        controller: _sellerPriceController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        style: GoogleFonts.inter(
                                          color: AppColors.textLight,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Price',
                                          hintStyle: GoogleFonts.inter(
                                            color: AppColors.textMuted,
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.inputBackground,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _addItem,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryRed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'ADD Item',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Order items list
                    _buildSectionLabel('Order Items'),
                    if (_orderRows.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardDarkBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Center(
                          child: Text(
                            'No items added yet',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ..._orderRows.asMap().entries.map(
                      (entry) => _buildOrderRow(entry.key),
                    ),

                    const SizedBox(height: 20),

                    // Return Product Section
                    _buildSectionLabel('Add Return Product'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDarkBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Column(
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<StoreItemModel>(
                              value: _selectedReturnProduct,
                              hint: Text(
                                'Select a product',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              dropdownColor: AppColors.inputBackground,
                              isExpanded: true,
                              items: _storeItems
                                  .map(
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        i.productName,
                                        style: GoogleFonts.inter(
                                          color: AppColors.textLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedReturnProduct = v),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _returnQuantityController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textLight,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Qty',
                                    hintStyle: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _returnPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: GoogleFonts.inter(
                                    color: AppColors.textLight,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Price',
                                    hintStyle: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedReturnReason,
                                hint: Text(
                                  'Why returning?',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                                dropdownColor: AppColors.inputBackground,
                                isExpanded: true,
                                items: _returnReasons
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(
                                          r,
                                          style: GoogleFonts.inter(
                                            color: AppColors.textLight,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedReturnReason = v),
                              ),
                            ),
                          ),
                          if (_selectedReturnReason == 'other') ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _otherReturnReasonController,
                              style: GoogleFonts.inter(
                                color: AppColors.textLight,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter reason...',
                                hintStyle: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppColors.inputBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: AppColors.textMuted,
                                ),
                                child: Checkbox(
                                  value: _isAddedToStock,
                                  activeColor: Colors.orange,
                                  onChanged: (v) => setState(
                                    () => _isAddedToStock = v ?? false,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Add this item quantity to my stock',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _addReturnItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Add Return',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Return items list
                    _buildSectionLabel('Return Items'),
                    if (_returnRows.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardDarkBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Center(
                          child: Text(
                            'No return items',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ..._returnRows.asMap().entries.map(
                      (entry) => _buildReturnRow(entry.key),
                    ),

                    const SizedBox(height: 20),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDarkBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grand Total (Shop Price)',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Rs ${_currency.format(_total)}',
                            style: GoogleFonts.inter(
                              color: AppColors.primaryRed,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(height: 12),
                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.cardDarkBackground,
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(
                    //       color: const Color(0xFF00C853).withOpacity(0.3),
                    //     ),
                    //   ),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Text(
                    //         'Grand Profit',
                    //         style: GoogleFonts.inter(
                    //           color: AppColors.textMuted,
                    //           fontSize: 14,
                    //         ),
                    //       ),
                    //       Text(
                    //         'Rs ${_currency.format(_totalProfit)}',
                    //         style: GoogleFonts.inter(
                    //           color: const Color(0xFF00C853),
                    //           fontSize: 20,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 24),

                    // Confirm button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradientRed,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _confirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                        label: Text(
                          'Confirm & Issue Order',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Spacer to allow scrolling to middle
                    const SizedBox(height: 350),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildOrderRow(int index) {
    final item = _orderRows[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
                onPressed: () => _showEditDialog(index),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
                onPressed: () => _removeRow(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Table of details
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 0.5),
            ),
            child: Table(
              border: TableBorder.all(color: Colors.white70, width: 0.5),
              columnWidths: const {
                0: FlexColumnWidth(1.2), // Product ID
                1: FlexColumnWidth(2.0), // Product Name
                2: FlexColumnWidth(1.2), // Quantity
                3: FlexColumnWidth(1.5), // Retail Price
                4: FlexColumnWidth(1.2), // Margin %
                5: FlexColumnWidth(1.5), // Shop Price
              },
              children: [
                // Header
                TableRow(
                  children: [
                    _buildTableCell('Product ID', isHeader: true),
                    _buildTableCell('Product Name', isHeader: true),
                    _buildTableCell('Quentity', isHeader: true),
                    _buildTableCell('retail price', isHeader: true),
                    _buildTableCell('margin %', isHeader: true),
                    _buildTableCell('shop price', isHeader: true),
                  ],
                ),
                // Data
                TableRow(
                  children: [
                    _buildTableCell(item.productId),
                    _buildTableCell(item.productName),
                    _buildTableCell(item.quantity.toString()),
                    _buildTableCell(item.price.toStringAsFixed(0)),
                    _buildTableCell(item.marginPercentage.toStringAsFixed(0)),
                    _buildTableCell(item.agentPrice.toStringAsFixed(0)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  'Total shop price',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Rs ${_currency.format(item.totalAgentPrice)}',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row(
          //   children: [
          //     SizedBox(
          //       width: 130,
          //       child: Text(
          //         'Profit :',
          //         style: GoogleFonts.inter(
          //           color: const Color(0xFF00C853),
          //           fontSize: 16,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //     ),
          //     Text(
          //       'Rs ${_currency.format(item.totalProfit)}',
          //       style: GoogleFonts.inter(
          //         color: const Color(0xFF00C853),
          //         fontSize: 16,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Tooltip(
      message: text,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isHeader ? Colors.white : AppColors.textLight,
            fontSize: isHeader ? 11 : 12,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _showEditDialog(int index) async {
    final item = _orderRows[index];
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.price.toString());
    final marginCtrl = TextEditingController(
      text: item.marginPercentage.toStringAsFixed(2),
    );
    final sellerPriceCtrl = TextEditingController(
      text: item.agentPrice.toStringAsFixed(2),
    );
    String editMode = 'Margin';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDarkBackground,
          title: Text(
            'Edit Item',
            style: GoogleFonts.inter(color: AppColors.textLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.inter(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Retail Price (Rs)',
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: editMode,
                  dropdownColor: AppColors.inputBackground,
                  decoration: InputDecoration(
                    labelText: 'Pricing Mode',
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                  items: ['Margin', 'Seller Price']
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m,
                            style: GoogleFonts.inter(
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => editMode = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (editMode == 'Margin')
                  TextField(
                    controller: marginCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.inter(color: AppColors.textLight),
                    decoration: InputDecoration(
                      labelText: 'Margin (%)',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.inputBorder),
                      ),
                    ),
                  )
                else
                  TextField(
                    controller: sellerPriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.inter(color: AppColors.textLight),
                    decoration: InputDecoration(
                      labelText: 'Seller Price (Rs)',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.inputBorder),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                final q = int.tryParse(qtyController.text) ?? item.quantity;
                final p = double.tryParse(priceController.text) ?? item.price;
                final m =
                    double.tryParse(marginCtrl.text) ?? item.marginPercentage;
                final sp =
                    double.tryParse(sellerPriceCtrl.text) ?? item.agentPrice;

                _updateRow(
                  index,
                  quantity: q,
                  price: p,
                  margin: m,
                  mode: editMode,
                  sellerPrice: sp,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReturnEditDialog(int index) async {
    final item = _returnRows[index];
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.price.toString());

    // Determine if the stored reason matches one of the predefined reasons
    String? dialogReason;
    String otherReason = '';
    if (item.returnReason != null &&
        _returnReasons.contains(item.returnReason)) {
      dialogReason = item.returnReason;
    } else if (item.returnReason != null) {
      dialogReason = 'other';
      otherReason = item.returnReason!;
    }
    final otherReasonCtrl = TextEditingController(text: otherReason);
    bool dialogAddToStock = item.isAddedToStock ?? false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDarkBackground,
          title: Text(
            'Edit Return Item',
            style: GoogleFonts.inter(color: AppColors.textLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.inter(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Return Price (Rs)',
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: dialogReason,
                  dropdownColor: AppColors.inputBackground,
                  decoration: InputDecoration(
                    labelText: 'Why returning?',
                    labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                  items: _returnReasons
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r,
                            style: GoogleFonts.inter(
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setDialogState(() => dialogReason = v);
                  },
                ),
                if (dialogReason == 'other') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otherReasonCtrl,
                    style: GoogleFonts.inter(color: AppColors.textLight),
                    decoration: InputDecoration(
                      labelText: 'Enter reason',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.inputBorder),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(unselectedWidgetColor: AppColors.textMuted),
                      child: Checkbox(
                        value: dialogAddToStock,
                        activeColor: Colors.orange,
                        onChanged: (v) =>
                            setDialogState(() => dialogAddToStock = v ?? false),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Add this item quantity to my stock',
                        style: GoogleFonts.inter(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                final q = int.tryParse(qtyController.text) ?? item.quantity;
                final p = double.tryParse(priceController.text) ?? item.price;
                final String reason = dialogReason == 'other'
                    ? otherReasonCtrl.text.trim()
                    : (dialogReason ?? '');

                _updateReturnRow(
                  index,
                  quantity: q,
                  price: p,
                  returnReason: reason,
                  isAddedToStock: dialogAddToStock,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnRow(int index) {
    final item = _returnRows[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
                onPressed: () => _showReturnEditDialog(index),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
                onPressed: () => _removeReturnRow(index),
              ),
            ],
          ),
          if (item.returnReason != null && item.returnReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reason: ${item.returnReason}',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (item.isAddedToStock == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.greenAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Will be added to stock',
                    style: GoogleFonts.inter(
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.quantity} x Rs ${item.price.toStringAsFixed(2)}',
                style: GoogleFonts.inter(color: AppColors.textLight),
              ),
              Text(
                '- Rs ${_currency.format(item.totalPrice)}',
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
