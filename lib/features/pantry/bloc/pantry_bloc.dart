import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/pantry_repository.dart';
import 'pantry_event.dart';
import 'pantry_state.dart';

class PantryBloc extends Bloc<PantryEvent, PantryState> {
  final PantryRepository _repository;
  StreamSubscription<List<PantryItem>>? _itemsSubscription;
  StreamSubscription<List<PantryItem>>? _expiringSubscription;
  StreamSubscription<void>? _firestoreSubscription;
  // Add at the top with other subscriptions:
  StreamSubscription<List<ShoppingListItem>>? _shoppingSubscription;
  List<ShoppingListItem> _currentShopping = [];

  List<PantryItem> _currentItems = [];
  List<PantryItem> _currentExpiring = [];

  PantryBloc(this._repository) : super(PantryInitial()) {
    on<PantryStarted>(_onStarted);
    on<PantryItemAdded>(_onItemAdded);
    on<PantryItemRemoved>(_onItemRemoved);
    on<PantryItemsUpdated>(_onItemsUpdated);
  }

  Future<void> _onStarted(
    PantryStarted event,
    Emitter<PantryState> emit,
  ) async {
    emit(PantryLoading());

    // Listen to Firestore for realtime updates from teammates
    _firestoreSubscription = _repository
        .listenToFirestore(event.householdId)
        .listen((_) {});

    // Watch local Drift DB for all items
    _itemsSubscription = _repository
        .watchItems(event.householdId)
        .listen((items) {
      _currentItems = items;
      add(PantryItemsUpdated(items));
    });

    // Watch expiring items separately
    _expiringSubscription = _repository
        .watchExpiringItems(event.householdId)
        .listen((items) {
      _currentExpiring = items;
      add(PantryItemsUpdated(_currentItems));
    });
    _shoppingSubscription = _repository
      .watchShoppingItems(event.householdId)
      .listen((items) {
      _currentShopping = items;
      add(PantryItemsUpdated(_currentItems));
    });
  }

  Future<void> _onItemAdded(
    PantryItemAdded event,
    Emitter<PantryState> emit,
  ) async {
    try {
      await _repository.addItem(
        householdId: event.householdId,
        name: event.name,
        barcode: event.barcode,
        quantity: event.quantity,
        unit: event.unit,
        expiryDate: event.expiryDate,
      );
    } catch (e) {
      emit(PantryError(e.toString()));
    }
  }

  Future<void> _onItemRemoved(
    PantryItemRemoved event,
    Emitter<PantryState> emit,
  ) async {
    try {
      await _repository.removeItem(event.itemId, event.householdId);
    } catch (e) {
      emit(PantryError(e.toString()));
    }
  }

  void _onItemsUpdated(
    PantryItemsUpdated event,
    Emitter<PantryState> emit,
  ) {
    emit(PantryLoaded(
      items: _currentItems,
      expiringItems: _currentExpiring,
      shoppingItems: _currentShopping,
    ));
  }

  @override
  Future<void> close() {
    _itemsSubscription?.cancel();
    _expiringSubscription?.cancel();
    _firestoreSubscription?.cancel();
    _shoppingSubscription?.cancel();
    return super.close();
  }
}