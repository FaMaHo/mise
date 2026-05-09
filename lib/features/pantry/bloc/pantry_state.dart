import 'package:equatable/equatable.dart';
import '../../../data/local/database.dart';

abstract class PantryState extends Equatable {
  const PantryState();
  @override
  List<Object?> get props => [];
}

class PantryInitial extends PantryState {}

class PantryLoading extends PantryState {}

class PantryLoaded extends PantryState {
  final List<PantryItem> items;
  final List<PantryItem> expiringItems;
  final List<ShoppingListItem> shoppingItems;

  const PantryLoaded({
    required this.items,
    required this.expiringItems,
    required this.shoppingItems,
  });


  List<PantryItem> get allItems => items;

  // Items expiring within 3 days
  List<PantryItem> get soonExpiring => expiringItems;

  @override
  List<Object?> get props => [items, expiringItems, shoppingItems];
}

class PantryError extends PantryState {
  final String message;
  const PantryError(this.message);
  @override
  List<Object?> get props => [message];
}
