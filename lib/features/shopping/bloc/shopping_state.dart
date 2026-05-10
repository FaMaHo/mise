import 'package:equatable/equatable.dart';
import '../../../data/local/database.dart';

abstract class ShoppingState extends Equatable {
  const ShoppingState();
  @override
  List<Object?> get props => [];
}

class ShoppingInitial extends ShoppingState {}

class ShoppingLoading extends ShoppingState {}

class ShoppingLoaded extends ShoppingState {
  final List<ShoppingListItem> items;
  const ShoppingLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class ShoppingError extends ShoppingState {
  final String message;
  const ShoppingError(this.message);
  @override
  List<Object?> get props => [message];
}