import 'package:equatable/equatable.dart';

abstract class ShoppingEvent extends Equatable {
  const ShoppingEvent();
  @override
  List<Object?> get props => [];
}

class ShoppingStarted extends ShoppingEvent {
  final String householdId;
  const ShoppingStarted(this.householdId);
  @override
  List<Object?> get props => [householdId];
}

class ShoppingItemAdded extends ShoppingEvent {
  final String name;
  const ShoppingItemAdded(this.name);
  @override
  List<Object?> get props => [name];
}

class ShoppingItemCheckedOff extends ShoppingEvent {
  final String itemId;
  const ShoppingItemCheckedOff(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class ShoppingItemDeleted extends ShoppingEvent {
  final String itemId;
  const ShoppingItemDeleted(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class ShoppingItemsUpdated extends ShoppingEvent {
  final List<dynamic> items;
  const ShoppingItemsUpdated(this.items);
  @override
  List<Object?> get props => [items];
}