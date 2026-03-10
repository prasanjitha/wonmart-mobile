import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../models/shop_model.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/toast_helper.dart';
import '../../widgets/premium_background.dart';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({super.key});

  @override
  State<AddShopScreen> createState() => _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();

  bool _gpsEnabled = false;
  bool _fetchingGps = false;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;

  final ShopService _shopService = ShopService();
  final _uuid = const Uuid();

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
        // Check/request permissions
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
          ToastHelper.showTopRightToast(context, 'Location captured!');
        }
      } catch (e) {
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
    final whatsapp = _whatsappController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ToastHelper.showTopRightToast(context, 'Shop name is required');
      return;
    }
    if (address.isEmpty) {
      ToastHelper.showTopRightToast(context, 'Address is required');
      return;
    }
    if (phone.isEmpty) {
      ToastHelper.showTopRightToast(context, 'Phone number is required');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final agentId = FirebaseAuth.instance.currentUser!.uid;
      final shop = ShopModel(
        id: '',
        agentId: agentId,
        uniqueId: _uuid.v4(),
        name: name,
        address: address,
        phone: phone,
        whatsapp: whatsapp,
        email: email,
        hasGps: _gpsEnabled,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: DateTime.now(),
      );
      await _shopService.addShop(shop);
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Shop added successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showTopRightToast(context, 'Failed to save shop');
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
            'Add New Shop',
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
              _buildSection('Shop Details', [
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
              ]),
              const SizedBox(height: 16),
              _buildSection('Contact Info', [
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

              // GPS Toggle Card
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
                            'Save GPS Location',
                            style: GoogleFonts.inter(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _gpsEnabled && _latitude != null
                                ? 'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}'
                                : 'Toggle to capture current location',
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
                            activeTrackColor: Colors.greenAccent.withOpacity(
                              0.3,
                            ),
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
                          'Add Shop',
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
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDarkBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(children: fields),
        ),
      ],
    );
  }
}
