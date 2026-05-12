import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/cook/models/recipe_suggestion.dart';

class RecipeApiService {
  static const _baseUrl = 'https://api.spoonacular.com';
  final String apiKey;

  RecipeApiService(this.apiKey);

  Future<List<RecipeSuggestion>> findByIngredients(
    List<String> ingredients, {
    int ranking = 1, // 1 = maximize used, 2 = minimize missed
    int number = 10,
  }) async {
    if (ingredients.isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/recipes/findByIngredients').replace(
      queryParameters: {
        'ingredients': ingredients.join(','),
        'number': number.toString(),
        'ranking': ranking.toString(),
        'ignorePantry': 'true',
        'apiKey': apiKey,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => RecipeSuggestion.fromJson(e)).toList();
  }
  Future<Map<String, dynamic>?> getRecipeInfo(int recipeId) async {
  final uri = Uri.parse('$_baseUrl/recipes/$recipeId/information').replace(
    queryParameters: {
      'apiKey': apiKey,
    },
  );

  final response = await http.get(uri);
  if (response.statusCode != 200) return null;
  return json.decode(response.body);
}
}