import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/providers/admin_renewals_provider.dart';
import 'dart:async';

class CardsListTab extends StatefulWidget {
  const CardsListTab({super.key});

  @override
  State<CardsListTab> createState() => _CardsListTabState();
}

class _CardsListTabState extends State<CardsListTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    Provider.of<AdminRenewalsProvider>(context, listen: false)
        .fetchCards(refresh: true, search: _searchController.text);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<AdminRenewalsProvider>(context, listen: false)
          .fetchCards(refresh: true, search: query);
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'بحث عن بطاقة...',
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

        Expanded(
          child: Consumer<AdminRenewalsProvider>(
            builder: (context, provider, child) {
              if (provider.isLoadingCards && provider.cards.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.cardsError != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(provider.cardsError!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchData(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.cards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد بطاقات',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!provider.isLoadingCards &&
                      provider.cardsHasMore &&
                      scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                    provider.fetchCards();
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.cards.length + (provider.cardsHasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.cards.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final guardian = provider.cards[index];
                    return _buildGuardianCardRenewalCard(context, guardian);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuardianCardRenewalCard(BuildContext context, dynamic guardian) {
    if (guardian is! AdminGuardian) return const SizedBox();
    
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        guardian.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(guardian.cardStatus, guardian.cardStatusColor),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                     Icon(Icons.credit_card, size: 14, color: Colors.grey[600]),
                     const SizedBox(width: 4),
                     Text('البطاقة: ${guardian.professionCardNumber ?? "-"}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                     const Spacer(),
                     Icon(Icons.event, size: 14, color: Colors.grey[600]),
                     const SizedBox(width: 4),
                     Text('الانتهاء: ${guardian.professionCardExpiryDate ?? "-"}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          
           if (guardian.cardRenewals != null && guardian.cardRenewals!.isNotEmpty) ...[
             const Divider(height: 1, indent: 16, endIndent: 16),
             Padding(
               padding: const EdgeInsets.all(12),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('آخر التجديدات:', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                   const SizedBox(height: 8),
                   ...guardian.cardRenewals!.take(2).map((renewal) {
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 6.0),
                       child: Row(
                         children: [
                           const Icon(Icons.history, size: 14, color: Colors.grey),
                           const SizedBox(width: 4),
                           Text('رقم: ${renewal['renewal_number'] ?? "-"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                           const SizedBox(width: 12),
                           const Icon(Icons.date_range, size: 14, color: Colors.grey),
                           const SizedBox(width: 4),
                           Text('تاريخ: ${renewal['renewal_date'] ?? "-"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                           const Spacer(),
                           Text('ينتهي: ${renewal['expiry_date'] ?? "-"}', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     );
                   }),
                 ],
               ),
             ),
           ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text ?? '-',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
