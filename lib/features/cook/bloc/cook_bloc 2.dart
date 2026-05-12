import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/recipe_api_service.dart';
import 'cook_event.dart';
import 'cook_state.dart';

class CookBloc extends Bloc<CookEvent, CookState> {
  final RecipeApiService _apiService;

  CookBloc(this._apiService) : super(CookInitial()) {
    on<CookSuggestionsRequested>(_onRequested);
  }

  Future<void> _onRequested(
    CookSuggestionsRequested event,
    Emitter<CookState> emit,
  ) async {
    if (event.pantryItemNames.isEmpty) {
      emit(CookEmpty());
      return;
    }

    emit(CookLoading());

    try {
      // Two calls: full matches first (ranking=1), then partial (ranking=2)
      final fullMatches = await _apiService.findByIngredients(
        event.pantryItemNames,
        ranking: 1,
      );

      final partialMatches = await _apiService.findByIngredients(
        event.pantryItemNames,
        ranking: 2,
      );

      // Remove full matches from partial list to avoid duplicates
      final fullIds = fullMatches.map((r) => r.id).toSet();
      final partialOnly = partialMatches
          .where((r) => !fullIds.contains(r.id) && r.missedCount > 0)
          .toList();

      emit(CookLoaded(fullMatches: fullMatches, partialMatches: partialOnly));
    } catch (e) {
      emit(CookError(e.toString()));
    }
  }
}