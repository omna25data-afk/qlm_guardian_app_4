import 'package:flutter/foundation.dart';
import 'package:guardian_app/features/admin/data/models/admin_dashboard_data.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_dashboard_repository.dart';

class AdminDashboardProvider with ChangeNotifier {
  final AdminDashboardRepository _repository;

  AdminDashboardProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AdminDashboardData? _data;
  AdminDashboardData? get data => _data;

  String? _error;
  String? get error => _error;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _repository.getDashboardData();
    } catch (e) {
      _error = e.toString();
      debugPrint('Admin Dashboard Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
