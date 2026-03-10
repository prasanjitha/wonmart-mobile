import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shop_model.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toast_helper.dart';
import 'add_shop_screen.dart';
import '../../widgets/premium_background.dart';
import 'edit_shop_screen.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  final ShopService _shopService = ShopService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteShop(ShopModel shop) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDarkBackground,
        title: Text(
          'Delete Shop',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
        content: Text(
          'Are you sure you want to delete "${shop.name}"?',
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
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _shopService.deleteShop(shop.id, shop.agentId);
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Shop deleted');
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
            'My Shops',
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
                MaterialPageRoute(builder: (_) => const AddShopScreen()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
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
                    hintText: 'Search by name...',
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

            // Shop list
            Expanded(
              child: StreamBuilder<List<ShopModel>>(
                stream: _shopService.watchAgentShops(_agentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading shops',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    );
                  }
                  final allShops = snapshot.data ?? [];
                  final shops = _searchQuery.isEmpty
                      ? allShops
                      : allShops
                            .where(
                              (s) =>
                                  s.name.toLowerCase().contains(_searchQuery),
                            )
                            .toList();

                  if (shops.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.textMuted,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No shops yet.\nTap + to add your first shop.'
                                : 'No shops found for "$_searchQuery"',
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
                    itemCount: shops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildShopCard(shops[i]),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'shops_fab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddShopScreen()),
          ),
          backgroundColor: AppColors.primaryRed,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Shop',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(ShopModel shop) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0x33D31027),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.storefront,
            color: AppColors.primaryRed,
            size: 22,
          ),
        ),
        title: Text(
          shop.name,
          style: GoogleFonts.inter(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              shop.address,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'ID: ${shop.uniqueId.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD700),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                if (shop.hasGps)
                  const Icon(
                    Icons.location_on,
                    color: Colors.greenAccent,
                    size: 13,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.cardDarkBackground,
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          onSelected: (action) {
            if (action == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditShopScreen(shop: shop)),
              );
            } else if (action == 'delete') {
              _deleteShop(shop);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textLight,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit',
                    style: GoogleFonts.inter(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_outline,
                    color: AppColors.primaryRed,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: GoogleFonts.inter(color: AppColors.primaryRed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
