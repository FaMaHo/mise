import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/local/database.dart';
import '../../../data/repositories/shopping_repository.dart';
import '../../../data/repositories/pantry_repository.dart';
import 'shopping_event.dart';
import 'shopping_state.dart';

class ShoppingBloc extends Bloc<ShoppingEvent, ShoppingState> {
  final ShoppingRepository _shoppingRepo;
  final PantryRepository _pantryRepo;
  String? _householdId;
  StreamSubscription<List<ShoppingListItem>>? _sub;

  ShoppingBloc(this._shoppingRepo, this._pantryRepo)
      : super(ShoppingInitial()) {
    on<ShoppingStarted>(_onStarted);
    on<ShoppingItemAdded>(_onAdded);
    on<ShoppingItemCheckedOff>(_onCheckedOff);
    on<ShoppingItemDeleted>(_onDeleted);
    on<ShoppingItemsUpdated>(_onUpdated);
  }

  Future<void> _onStarted(
      ShoppingStarted event, Emitter<ShoppingState> emit) async {
    _householdId = event.householdId;
    emit(ShoppingLoading());
    await _sub?.cancel();
    _shoppingRepo.listenToFirestore(event.householdId);
    _sub = _shoppingRepo.watchItems(event.householdId).listen(
          (items) => add(ShoppingItemsUpdated(items)),
        );
  }

  void _onUpdated(ShoppingItemsUpdated event, Emitter<ShoppingState> emit) {
    emit(ShoppingLoaded(event.items.cast<ShoppingListItem>()));
  }

  Future<void> _onAdded(
      ShoppingItemAdded event, Emitter<ShoppingState> emit) async {
    if (_householdId == null) return;
    await _shoppingRepo.addItem(
      householdId: _householdId!,
      name: event.name,
    );
  }

  Future<void> _onCheckedOff(
      ShoppingItemCheckedOff event, Emitter<ShoppingState> emit) async {
    if (_householdId == null) return;
    // Remove from shopping list and get item data back
    final item = await _shoppingRepo.checkOffItem(event.itemId);
    if (item == null) return;
    // Add directly to pantry
    await _pantryRepo.addItem(
      householdId: _householdId!,
      name: item.name,
      quantity: item.quantity,
    );
  }

  Future<void> _onDeleted(
      ShoppingItemDeleted event, Emitter<ShoppingState> emit) async {
    if (_householdId == null) return;
    await _shoppingRepo.deleteItem(event.itemId, _householdId!);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}