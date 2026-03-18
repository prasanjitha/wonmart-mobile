import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/toast_helper.dart';

class ProfileScreen extends StatefulWidget {
  final String agentName;
  const ProfileScreen({super.key, required this.agentName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String get _agentId => FirebaseAuth.instance.currentUser?.uid ?? 'Unknown';
  final ExportService _exportService = ExportService();
  bool _isExporting = false;

  Future<void> _exportWithDateRange(String type) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryRed,
            onPrimary: Colors.white,
            surface: AppColors.cardDarkBackground,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() => _isExporting = true);
    try {
      if (type == 'sales') {
        await _exportService.exportSalesRecords(_agentId, picked.start, picked.end);
      } else {
        await _exportService.exportReturnRecords(_agentId, picked.start, picked.end);
      }
      if (mounted) ToastHelper.showTopRightToast(context, 'Export ready!');
    } catch (e) {
      if (mounted) ToastHelper.showTopRightToast(context, 'Export failed: $e');
    }
    setState(() => _isExporting = false);
  }

  Future<void> _exportDirect(String type) async {
    setState(() => _isExporting = true);
    try {
      if (type == 'inventory') {
        await _exportService.exportStoreInventory(_agentId);
      } else {
        await _exportService.exportShopList(_agentId);
      }
      if (mounted) ToastHelper.showTopRightToast(context, 'Export ready!');
    } catch (e) {
      if (mounted) ToastHelper.showTopRightToast(context, 'Export failed: $e');
    }
    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

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
            'Agent Profile',
            style: GoogleFonts.inter(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Profile Header / Avatar
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.buttonGradientRed,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Agent Details
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Agent Name',
                      widget.agentName,
                      Icons.person_outline,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white12, height: 1),
                    ),
                    _buildDetailRow(
                      'Agent ID',
                      _agentId.toUpperCase(),
                      Icons.badge_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Export Data Section
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.file_download_outlined, color: Colors.greenAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Data',
                              style: GoogleFonts.inter(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Backup your data as CSV files',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isExporting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
                      )
                    else
                      Column(
                        children: [
                          _buildExportButton(
                            icon: Icons.receipt_long_outlined,
                            label: 'Sales Records',
                            subtitle: 'Select date range',
                            color: AppColors.primaryRed,
                            onTap: () => _exportWithDateRange('sales'),
                          ),
                          const SizedBox(height: 10),
                          _buildExportButton(
                            icon: Icons.assignment_return_outlined,
                            label: 'Return Records',
                            subtitle: 'Select date range',
                            color: Colors.orange,
                            onTap: () => _exportWithDateRange('returns'),
                          ),
                          const SizedBox(height: 10),
                          _buildExportButton(
                            icon: Icons.inventory_2_outlined,
                            label: 'Store Inventory',
                            subtitle: 'Current stock snapshot',
                            color: Colors.blueAccent,
                            onTap: () => _exportDirect('inventory'),
                          ),
                          const SizedBox(height: 10),
                          _buildExportButton(
                            icon: Icons.store_mall_directory_outlined,
                            label: 'Shop List',
                            subtitle: 'All registered shops',
                            color: Colors.purpleAccent,
                            onTap: () => _exportDirect('shops'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // App Info
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wonmart Agent App',
                          style: GoogleFonts.inter(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Version 1.0.0',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradientRed,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
