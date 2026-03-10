import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/inventory_item_model.dart';
import '../../services/inventory_service.dart';
import '../../theme/app_colors.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: Text('My Inventory',
            style: GoogleFonts.inter(
                color: AppColors.textLight, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<InventoryItemModel>>(
        stream: inventoryService.watchInventory(_agentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryRed));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading inventory',
                    style:
                        GoogleFonts.inter(color: AppColors.textMuted)));
          }
          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No inventory assigned yet.\nContact admin to get products assigned.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }

          // Summary totals line
          final totalItems = items.length;

          return Column(
            children: [
              // Summary card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD31027), Color(0xFF8A0000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Products',
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 12)),
                          Text('$totalItems SKUs',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Product list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildItemCard(items[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemCard(InventoryItemModel item) {
    final isLow = item.quantity < 10;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLow
              ? AppColors.primaryRed.withOpacity(0.5)
              : AppColors.inputBorder,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isLow
                ? AppColors.primaryRed.withOpacity(0.15)
                : AppColors.inputBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inventory_2_outlined,
              color: isLow ? AppColors.primaryRed : AppColors.textMuted,
              size: 20),
        ),
        title: Text(item.productName,
            style: GoogleFonts.inter(
                color: AppColors.textLight, fontWeight: FontWeight.w600)),
        subtitle: Text('Unit: ${item.unit}',
            style:
                GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.quantity}',
              style: GoogleFonts.inter(
                color: isLow ? AppColors.primaryRed : const Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (isLow)
              Text('Low Stock',
                  style: GoogleFonts.inter(
                      color: AppColors.primaryRed, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
