import 'package:equatable/equatable.dart';

abstract class CookEvent extends Equatable {
  const CookEvent();
  @override
  List<Object?> get props => [];
}

class CookSuggestionsRequested extends CookEvent {
  final List<String> pantryItemNames;
  const CookSuggestionsRequested(this.pantryItemNames);
  @override
  List<Object?> get props => [pantryItemNames];
}