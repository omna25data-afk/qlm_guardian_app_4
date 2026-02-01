import 'package:flutter/material.dart';
import 'package:guardian_app/features/admin/data/models/admin_renewal_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_renewals_repository.dart';

class AdminRenewalsProvider with ChangeNotifier {
  final AdminRenewalsRepository _repository;

  AdminRenewalsProvider(this._repository);

  // Licenses State
  List<AdminRenewal> _licenses = [];
  bool _isLoadingLicenses = false;
  String? _licensesError;
  int _licensesPage = 1;
  bool _licensesHasMore = true;

  List<AdminRenewal> get licenses => _licenses;
  bool get isLoadingLicenses => _isLoadingLicenses;
  String? get licensesError => _licensesError;
  bool get licensesHasMore => _licensesHasMore;

  // Cards State
  List<AdminRenewal> _cards = [];
  bool _isLoadingCards = false;
  String? _cardsError;
  int _cardsPage = 1;
  bool _cardsHasMore = true;

  List<AdminRenewal> get cards => _cards;
  bool get isLoadingCards => _isLoadingCards;
  String? get cardsError => _cardsError;
  bool get cardsHasMore => _cardsHasMore;

  // Fetch Licenses
  Future<void> fetchLicenses({bool refresh = false, String? search}) async {
    if (refresh) {
      _licensesPage = 1;
      _licenses = [];
      _licensesHasMore = true;
    }

    if (!_licensesHasMore && !refresh) return;
    if (_isLoadingLicenses) return;

    _isLoadingLicenses = true;
    _licensesError = null;
    notifyListeners();

    try {
      final newItems = await _repository.getLicenses(
        page: _licensesPage,
        searchQuery: search,
      );

      if (refresh) {
        _licenses = newItems;
      } else {
        _licenses.addAll(newItems);
      }

      if (newItems.isEmpty || newItems.length < 20) {
        _licensesHasMore = false;
      } else {
        _licensesPage++;
      }
    } catch (e) {
      _licensesError = e.toString();
    } finally {
      _isLoadingLicenses = false;
      notifyListeners();
    }
  }

  // Fetch Cards
  Future<void> fetchCards({bool refresh = false, String? search}) async {
    if (refresh) {
      _cardsPage = 1;
      _cards = [];
      _cardsHasMore = true;
    }

    if (!_cardsHasMore && !refresh) return;
    if (_isLoadingCards) return;

    _isLoadingCards = true;
    _cardsError = null;
    notifyListeners();

    try {
      final newItems = await _repository.getCards(
        page: _cardsPage,
        searchQuery: search,
      );

      if (refresh) {
        _cards = newItems;
      } else {
        _cards.addAll(newItems);
      }

      if (newItems.isEmpty || newItems.length < 20) {
        _cardsHasMore = false;
      } else {
        _cardsPage++;
      }
    } catch (e) {
      _cardsError = e.toString();
    } finally {
      _isLoadingCards = false;
      notifyListeners();
    }
  }
}
