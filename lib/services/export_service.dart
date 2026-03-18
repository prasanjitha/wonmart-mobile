import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'sales_record_service.dart';
import 'store_service.dart';
import 'shop_service.dart';


class ExportService {
  final SalesRecordService _salesService = SalesRecordService();
  final StoreService _storeService = StoreService();
  final ShopService _shopService = ShopService();
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Export all sales records for a date range to CSV and share
  Future<void> exportSalesRecords(String agentId, DateTime startDate, DateTime endDate) async {
    final records = await _salesService.getSalesRecordsInRange(agentId, startDate, endDate);

    final List<List<String>> rows = [
      ['Date', 'Shop Name', 'Product', 'Qty', 'Unit', 'Retail Price', 'Agent Price', 'Total', 'Margin %', 'Profit', 'Payment Status', 'Paid Amount'],
    ];

    for (var record in records) {
      for (var item in record.items) {
        rows.add([
          _dateFormat.format(record.createdAt),
          record.shopName,
          item.productName,
          item.quantity.toString(),
          item.unit,
          item.price.toStringAsFixed(2),
          item.agentPrice.toStringAsFixed(2),
          item.totalAgentPrice.toStringAsFixed(2),
          item.marginPercentage.toStringAsFixed(1),
          item.totalProfit.toStringAsFixed(2),
          record.paymentStatus,
          record.paidAmount.toStringAsFixed(2),
        ]);
      }
    }

    await _generateAndShare(rows, 'sales_records_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.csv');
  }

  /// Export return items to CSV and share
  Future<void> exportReturnRecords(String agentId, DateTime startDate, DateTime endDate) async {
    final records = await _salesService.getSalesRecordsInRange(agentId, startDate, endDate);

    final List<List<String>> rows = [
      ['Date', 'Shop Name', 'Product', 'Qty', 'Unit', 'Return Price', 'Total Return', 'Reason', 'Added to Stock'],
    ];

    for (var record in records) {
      for (var item in record.returnItems) {
        rows.add([
          _dateFormat.format(record.createdAt),
          record.shopName,
          item.productName,
          item.quantity.toString(),
          item.unit,
          item.price.toStringAsFixed(2),
          item.totalPrice.toStringAsFixed(2),
          item.returnReason ?? 'N/A',
          item.isAddedToStock == true ? 'Yes' : 'No',
        ]);
      }
    }

    await _generateAndShare(rows, 'return_records_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.csv');
  }

  /// Export current store inventory to CSV and share
  Future<void> exportStoreInventory(String agentId) async {
    final items = await _storeService.getAgentStore(agentId);

    final List<List<String>> rows = [
      ['Product Name', 'Quantity', 'Unit', 'Price (Rs)', 'Total Value (Rs)'],
    ];

    for (var item in items) {
      rows.add([
        item.productName,
        item.quantity.toString(),
        item.unit,
        item.price.toStringAsFixed(2),
        (item.quantity * item.price).toStringAsFixed(2),
      ]);
    }

    await _generateAndShare(rows, 'store_inventory_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
  }

  /// Export shop list to CSV and share
  Future<void> exportShopList(String agentId) async {
    final shops = await _shopService.getAgentShops(agentId);

    final List<List<String>> rows = [
      ['Shop Name', 'Address', 'Phone', 'WhatsApp', 'Email'],
    ];

    for (var shop in shops) {
      rows.add([
        shop.name,
        shop.address,
        shop.phone,
        shop.whatsapp,
        shop.email,
      ]);
    }

    await _generateAndShare(rows, 'shop_list_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
  }

  /// Internal: Generate CSV file and share it
  Future<void> _generateAndShare(List<List<String>> rows, String fileName) async {
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Wonmart Export - $fileName',
      ),
    );
  }
}
