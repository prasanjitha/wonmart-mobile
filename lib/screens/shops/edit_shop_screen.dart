import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/shop_model.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/toast_helper.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditShopScreen extends StatefulWidget {
  final ShopModel shop;
  const EditShopScreen({super.key, required this.shop});

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _emailController;

  bool _gpsEnabled = false;
  bool _fetchingGps = false;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;

  final ShopService _shopService = ShopService();
  final RouteService _routeService = RouteService();

  String? _selectedRouteId;
  List<RouteModel> _routes = [];
  bool _isLoadingRoutes = true;

  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop.name);
    _addressController = TextEditingController(text: widget.shop.address);
    _phoneController = TextEditingController(text: widget.shop.phone);
    _whatsappController = TextEditingController(text: widget.shop.whatsapp);
    _emailController = TextEditingController(text: widget.shop.email);
    _gpsEnabled = widget.shop.hasGps;
    _latitude = widget.shop.latitude;
    _longitude = widget.shop.longitude;
    _selectedRouteId = widget.shop.routeId;
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await _routeService.getAgentRoutes(_agentId);
      setState(() {
        _routes = routes;
        _isLoadingRoutes = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoutes = false);
        ToastHelper.showTopRightToast(context, 'Failed to load routes');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _toggleGps(bool value) async {
    if (value) {
      setState(() => _fetchingGps = true);
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever) {
          if (mounted) {
            ToastHelper.showTopRightToast(
              context,
              'Location permission denied permanently',
            );
          }
          setState(() => _fetchingGps = false);
          return;
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _gpsEnabled = true;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _fetchingGps = false;
        });
        if (mounted) {
          ToastHelper.showTopRightToast(context, 'Location updated!');
        }
      } catch (_) {
        setState(() => _fetchingGps = false);
        if (mounted) {
          ToastHelper.showTopRightToast(
            context,
            'Failed to get location. Try again.',
          );
        }
      }
    } else {
      setState(() {
        _gpsEnabled = false;
        _latitude = null;
        _longitude = null;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (_selectedRouteId == null) {
      ToastHelper.showTopRightToast(context, 'Please select a route');
      return;
    }

    if (name.isEmpty || address.isEmpty || phone.isEmpty) {
      ToastHelper.showTopRightToast(
        context,
        'Name, address and phone are required',
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _shopService.updateShop(widget.shop.id, widget.shop.agentId, {
        'name': name,
        'address': address,
        'phone': phone,
        'whatsapp': _whatsappController.text.trim(),
        'email': _emailController.text.trim(),
        'routeId': _selectedRouteId,
        'hasGps': _gpsEnabled,
        'latitude': _latitude,
        'longitude': _longitude,
      });
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Shop updated!');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Failed to update shop');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Shop',
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
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop ID badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.cardDarkBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Shop ID: ${widget.shop.uniqueId.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            _buildSectionCard([
              _isLoadingRoutes
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      dropdownColor: AppColors.cardDarkBackground,
                      value: _selectedRouteId,
                      hint: Text(
                        'Select Route *',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.route_outlined,
                            color: AppColors.primaryRed),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 12,
                        ),
                      ),
                      items: _routes.map((r) {
                        return DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            r.name,
                            style:
                                GoogleFonts.inter(color: AppColors.textLight),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedRouteId = val);
                      },
                    ),
            ]),

            const SizedBox(height: 16),

            _buildSectionCard([
              CustomTextField(
                hintText: 'Shop Name *',
                prefixIcon: Icons.storefront_outlined,
                controller: _nameController,
              ),
              CustomTextField(
                hintText: 'Address *',
                prefixIcon: Icons.location_on_outlined,
                controller: _addressController,
              ),
              CustomTextField(
                hintText: 'Phone Number *',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
              ),
              CustomTextField(
                hintText: 'WhatsApp Number',
                prefixIcon: Icons.chat_outlined,
                keyboardType: TextInputType.phone,
                controller: _whatsappController,
              ),
              CustomTextField(
                hintText: 'Email (optional)',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
            ]),

            const SizedBox(height: 16),

            // GPS toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDarkBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _gpsEnabled
                          ? Colors.greenAccent.withOpacity(0.15)
                          : AppColors.inputBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.gps_fixed,
                      color: _gpsEnabled
                          ? Colors.greenAccent
                          : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS Location',
                          style: GoogleFonts.inter(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _gpsEnabled && _latitude != null
                              ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                              : 'Toggle to update location',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _fetchingGps
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : Switch(
                          value: _gpsEnabled,
                          onChanged: _toggleGps,
                          activeColor: Colors.greenAccent,
                          activeTrackColor: Colors.greenAccent.withOpacity(0.3),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 28),
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
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> fields) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDarkBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(children: fields),
    );
  }
}
