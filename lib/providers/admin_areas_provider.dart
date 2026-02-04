import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_area_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_areas_repository.dart';

class AdminAreasProvider with ChangeNotifier {
  final AdminAreasRepository _repository;

  AdminAreasProvider(this._repository);

  List<AdminArea> _areas = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String? _searchQuery;

  List<AdminArea> get areas => _areas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchAreas({bool refresh = false, String? search}) async {
    if (refresh) {
      _page = 1;
      _areas = [];
      _hasMore = true;
      _searchQuery = search;
    }

    if (!_hasMore && !refresh) return;
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newItems = await _repository.getAreas(
        page: _page,
        searchQuery: _searchQuery,
      );

      if (refresh) {
        _areas = newItems;
      } else {
        _areas.addAll(newItems);
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
