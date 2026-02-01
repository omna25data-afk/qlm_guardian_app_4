import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/data/models/admin_renewal_model.dart';
import 'package:guardian_app/providers/admin_renewals_provider.dart';
import 'dart:async';

class LicensesListTab extends StatefulWidget {
  const LicensesListTab({super.key});

  @override
  State<LicensesListTab> createState() => _LicensesListTabState();
}

class _LicensesListTabState extends State<LicensesListTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    Provider.of<AdminRenewalsProvider>(context, listen: false)
        .fetchLicenses(refresh: true, search: _searchController.text);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<AdminRenewalsProvider>(context, listen: false)
          .fetchLicenses(refresh: true, search: query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'بحث عن رخصة (اسم الأمين، رقم الرخصة...)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // List
        Expanded(
          child: Consumer<AdminRenewalsProvider>(
            builder: (context, provider, child) {
              // Note: provider has lists for licenses and cards.
              // We need to use 'licenses'.
              
              if (provider.isLoadingLicenses && provider.licenses.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.licensesError != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(provider.licensesError!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchData(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.licenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد رخص',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!provider.isLoadingLicenses &&
                      provider.licensesHasMore &&
                      scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                    provider.fetchLicenses();
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.licenses.length + (provider.licensesHasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.licenses.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final renewal = provider.licenses[index];
                    return _buildRenewalCard(context, renewal);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRenewalCard(BuildContext context, AdminRenewal renewal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    renewal.guardianName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(renewal.status, renewal.statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'تاريخ التجديد: ${renewal.renewalDate}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, String colorName) {
    Color color;
    switch (colorName) {
      case 'success': color = Colors.green; break;
      case 'danger': color = Colors.red; break;
      case 'warning': color = Colors.orange; break;
      case 'primary': color = const Color(0xFF006400); break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
