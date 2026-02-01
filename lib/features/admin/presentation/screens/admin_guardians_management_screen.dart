import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/presentation/widgets/guardians_list_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/licenses_list_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/cards_list_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/areas_list_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/assignments_list_tab.dart';

class AdminGuardiansManagementScreen extends StatelessWidget {
  const AdminGuardiansManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
              tabs: const [
                Tab(text: 'الأمناء'),
                Tab(text: 'تجديد الرخص'),
                Tab(text: 'تجديد البطاقات'),
                Tab(text: 'المناطق'),
                Tab(text: 'التكليفات'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                GuardiansListTab(),
                LicensesListTab(),
                CardsListTab(),
                AreasListTab(),
                AssignmentsListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
