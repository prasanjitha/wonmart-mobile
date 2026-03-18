import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shop_model.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/toast_helper.dart';
import 'add_shop_screen.dart';
import '../../widgets/premium_background.dart';
import 'package:wonmart/models/route_model.dart';
import 'package:wonmart/services/route_service.dart';
import 'edit_shop_screen.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  final ShopService _shopService = ShopService();
  final RouteService _routeService = RouteService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  String _searchQuery = '';

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    _routeController.dispose();
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

  Future<void> _addRoute() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDarkBackground,
        title: Text(
          'Add New Route',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
        content: TextField(
          controller: _routeController,
          style: GoogleFonts.inter(color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: 'e.g. Galle to Matara',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryRed),
            ),
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
              final val = _routeController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(context, val);
                _routeController.clear();
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );

    if (name != null) {
      final newRoute = RouteModel(
        id: '',
        agentId: _agentId,
        name: name,
        createdAt: DateTime.now(),
      );
      await _routeService.addRoute(newRoute);
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Route added successfully');
      }
    }
  }

  Future<void> _deleteRoute(RouteModel route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDarkBackground,
        title: Text(
          'Delete Route',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
        content: Text(
          'Are you sure you want to delete "${route.name}"?',
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
      await _routeService.deleteRoute(route.id, route.agentId);
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Route deleted');
      }
    }
  }

  Future<void> _editRoute(RouteModel route) async {
    _routeController.text = route.name;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDarkBackground,
        title: Text(
          'Edit Route',
          style: GoogleFonts.inter(color: AppColors.textLight),
        ),
        content: TextField(
          controller: _routeController,
          style: GoogleFonts.inter(color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: 'e.g. Galle to Matara',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryRed),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _routeController.clear();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final val = _routeController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(context, val);
                _routeController.clear();
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );

    if (name != null && name != route.name) {
      await _routeService.updateRoute(route.id, route.agentId, name);
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Route updated successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: PremiumBackground(
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
            bottom: TabBar(
              indicatorColor: AppColors.primaryRed,
              labelColor: AppColors.primaryRed,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Shops'),
                Tab(text: 'Routes'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Tab 1: Shops
              Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted,
                          ),
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        }
                        final allShops = snapshot.data ?? [];
                        final shops = _searchQuery.isEmpty
                            ? allShops
                            : allShops
                                  .where(
                                    (s) => s.name.toLowerCase().contains(
                                      _searchQuery,
                                    ),
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildShopCard(shops[i]),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Tab 2: Routes
              StreamBuilder<List<RouteModel>>(
                stream: _routeService.watchAgentRoutes(_agentId),
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
                        'Error loading routes',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    );
                  }
                  final routes = snapshot.data ?? [];

                  if (routes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.route_outlined,
                            color: AppColors.textMuted,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No routes yet.\nTap +Add Route to add your first route.',
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
                      bottom: 150,
                    ),
                    itemCount: routes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardDarkBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x33D31027),
                            child: Icon(
                              Icons.route,
                              color: AppColors.primaryRed,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            route.name,
                            style: GoogleFonts.inter(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Created on ${route.createdAt.day}/${route.createdAt.month}/${route.createdAt.year}',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            color: AppColors.cardDarkBackground,
                            icon: const Icon(Icons.more_vert,
                                color: AppColors.textMuted),
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editRoute(route);
                              } else if (action == 'delete') {
                                _deleteRoute(route);
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
                                      style: GoogleFonts.inter(
                                          color: AppColors.textLight),
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
                                      style: GoogleFonts.inter(
                                          color: AppColors.primaryRed),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'routes_fab',
                onPressed: _addRoute,
                backgroundColor: const Color.fromARGB(255, 255, 166, 0),
                elevation: 4,
                icon: const Icon(
                  Icons.add_road,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                label: Text(
                  'Add Route',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 27, 27, 27),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.extended(
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
              const SizedBox(height: 16),
            ],
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
