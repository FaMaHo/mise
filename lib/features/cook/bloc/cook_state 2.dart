import 'package:equatable/equatable.dart';
import '../models/recipe_suggestion.dart';

abstract class CookState extends Equatable {
  const CookState();
  @override
  List<Object?> get props => [];
}

class CookInitial extends CookState {}
class CookLoading extends CookState {}
class CookEmpty extends CookState {}  // pantry is empty

class CookLoaded extends CookState {
  final List<RecipeSuggestion> fullMatches;
  final List<RecipeSuggestion> partialMatches;

  const CookLoaded({
    required this.fullMatches,
    required this.partialMatches,
  });

  @override
  List<Object?> get props => [fullMatches, partialMatches];
}

class CookError extends CookState {
  final String message;
  const CookError(this.message);
  @override
  List<Object?> get props => [message];
}