import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_assignment_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_assignments_repository.dart';

class AdminAssignmentsProvider with ChangeNotifier {
  final AdminAssignmentsRepository _repository;

  AdminAssignmentsProvider(this._repository);

  List<AdminAssignment> _assignments = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String? _searchQuery;
  String _currentStatus = 'all';
  String _currentType = 'all';

  List<AdminAssignment> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get currentStatus => _currentStatus;
  String get currentType => _currentType;

  void setFilter({String? status, String? type}) {
    bool changed = false;
    if (status != null && status != _currentStatus) {
      _currentStatus = status;
      changed = true;
    }
    if (type != null && type != _currentType) {
      _currentType = type;
      changed = true;
    }
    if (changed) {
      fetchAssignments(refresh: true);
    }
  }

  Future<void> fetchAssignments({bool refresh = false, String? search}) async {
    if (refresh) {
      _page = 1;
      _assignments = [];
      _hasMore = true;
      _searchQuery = search;
    }

    if (!_hasMore && !refresh) return;
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newItems = await _repository.getAssignments(
        page: _page,
        searchQuery: _searchQuery,
        status: _currentStatus,
        type: _currentType,
      );

      if (refresh) {
        _assignments = newItems;
      } else {
        _assignments.addAll(newItems);
      }

      if (newItems.isEmpty || newItems.length < 20) {
        _hasMore = false;
      } else {
        _page++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
