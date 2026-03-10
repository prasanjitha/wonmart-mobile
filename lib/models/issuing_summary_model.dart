class IssuingProductSummary {
  final String productId;
  final String productName;
  final String unit;
  final int warehouseStock;
  final int qtyIssued;
  final double expectedRs;

  IssuingProductSummary({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.warehouseStock,
    required this.qtyIssued,
    required this.expectedRs,
  });
}

class IssuingShopDetail {
  final String shopId;
  final String shopName;
  final double margin;
  final int qty;
  final double expected;
  final String status;

  IssuingShopDetail({
    required this.shopId,
    required this.shopName,
    required this.margin,
    required this.qty,
    required this.expected,
    required this.status,
  });
}
