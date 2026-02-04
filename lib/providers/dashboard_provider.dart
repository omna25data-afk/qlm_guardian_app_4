import 'package:flutter/foundation.dart';
import 'package:guardian_app/features/dashboard/data/models/dashboard_data.dart';
import 'package:guardian_app/features/dashboard/data/repositories/dashboard_repository.dart';

/// A provider for the dashboard screen.
///
/// It handles the state for loading and displaying dashboard data.
class DashboardProvider with ChangeNotifier, DiagnosticableTreeMixin {
  final DashboardRepository _repository;

  DashboardProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DashboardData? _dashboardData;
  DashboardData? get dashboardData => _dashboardData;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Fetches dashboard data from the repository.
  ///
  /// Updates loading state and notifies listeners upon completion or error.
  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardData = await _repository.getDashboard();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Correcting the debugFillProperties method
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('isLoading', isLoading));
    properties.add(DiagnosticsProperty<DashboardData>('dashboardData', dashboardData));
  }
}
