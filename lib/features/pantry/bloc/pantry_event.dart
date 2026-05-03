import 'package:equatable/equatable.dart';

abstract class PantryEvent extends Equatable {
  const PantryEvent();
  @override
  List<Object?> get props => [];
}

class PantryStarted extends PantryEvent {
  final String householdId;
  const PantryStarted(this.householdId);
  @override
  List<Object?> get props => [householdId];
}

class PantryItemAdded extends PantryEvent {
  final String householdId;
  final String name;
  final String? barcode;
  final int quantity;
  final String? unit;
  final DateTime? expiryDate;

  const PantryItemAdded({
    required this.householdId,
    required this.name,
    this.barcode,
    this.quantity = 1,
    this.unit,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [householdId, name, barcode, quantity];
}

class PantryItemRemoved extends PantryEvent {
  final String itemId;
  final String householdId;
  const PantryItemRemoved(this.itemId, this.householdId);
  @override
  List<Object?> get props => [itemId, householdId];
}

class PantryItemsUpdated extends PantryEvent {
  final List<dynamic> items;
  const PantryItemsUpdated(this.items);
  @override
  List<Object?> get props => [items];
}