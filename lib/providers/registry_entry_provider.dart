import 'package:flutter/foundation.dart';
import 'package:guardian_app/features/registry/data/models/registry_entry.dart';
import 'package:guardian_app/features/registry/data/repositories/registry_repository.dart';

/// A provider for managing the list of registry entries.
class RegistryEntryProvider with ChangeNotifier {
  final RegistryRepository _repository;

  RegistryEntryProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RegistryEntry> _entries = [];
  List<RegistryEntry> get entries => _entries;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Fetches the list of registry entries from the repository.
  /// Can be filtered by status or a search query.
  Future<void> fetchEntries({
    String? status, 
    String? searchQuery,
    int? bookNumber,
    int? recordBookId,
    int? contractTypeId,
    int? hijriYear,
    int? hijriMonth,
    String? sortBy,
    String? sortOrder,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _entries = await _repository.getRegistryEntries(
        status: status, 
        searchQuery: searchQuery,
        bookNumber: bookNumber,
        recordBookId: recordBookId,
        contractTypeId: contractTypeId,
        hijriYear: hijriYear,
        hijriMonth: hijriMonth,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
