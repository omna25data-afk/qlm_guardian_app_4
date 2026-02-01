import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_guardian_repository.dart';

class AdminGuardiansProvider with ChangeNotifier {
  final AdminGuardianRepository _repository;

  AdminGuardiansProvider(this._repository);

  List<AdminGuardian> _guardians = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String _currentStatus = 'all';
  String? _currentSearch;

  List<AdminGuardian> get guardians => _guardians;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchGuardians({
    bool refresh = false,
    String? status,
    String? search,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _guardians = [];
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    
    // Update filters if provided
    if (status != null) _currentStatus = status;
    if (search != null) _currentSearch = search;
    
    notifyListeners();

    try {
      final newGuardians = await _repository.getGuardians(
        page: _currentPage,
        status: _currentStatus,
        searchQuery: _currentSearch,
      );

      if (refresh) {
        _guardians = newGuardians;
      } else {
        _guardians.addAll(newGuardians);
      }

      if (newGuardians.isEmpty || newGuardians.length < 20) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_currentSearch == query) return;
    fetchGuardians(refresh: true, search: query);
  }

  void setFilterStatus(String status) {
    if (_currentStatus == status) return;
    fetchGuardians(refresh: true, status: status);
  }
}
