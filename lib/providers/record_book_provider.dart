import 'package:flutter/foundation.dart';
import 'package:guardian_app/features/records/data/models/record_book.dart';
import 'package:guardian_app/features/records/data/repositories/records_repository.dart';

/// A provider for managing the list of record books.
class RecordBookProvider with ChangeNotifier {
  final RecordsRepository _repository;

  RecordBookProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RecordBook> _recordBooks = [];
  List<RecordBook> get recordBooks => _recordBooks;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Fetches the list of record books from the repository.
  Future<void> fetchRecordBooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recordBooks = await _repository.getRecordBooks();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
