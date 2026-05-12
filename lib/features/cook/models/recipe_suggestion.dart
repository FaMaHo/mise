class RecipeIngredient {
  final int id;
  final String name;
  final double amount;
  final String unit;

  const RecipeIngredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        id: json['id'],
        name: json['name'],
        amount: (json['amount'] as num).toDouble(),
        unit: json['unit'] ?? '',
      );
}

class RecipeSuggestion {
  final int id;
  final String title;
  final String imageUrl;
  final List<RecipeIngredient> usedIngredients;
  final List<RecipeIngredient> missedIngredients;
  final int missedCount;

  const RecipeSuggestion({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.usedIngredients,
    required this.missedIngredients,
    required this.missedCount,
  });

  bool get isFullMatch => missedCount == 0;

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) =>
      RecipeSuggestion(
        id: json['id'],
        title: json['title'],
        imageUrl: json['image'] ?? '',
        usedIngredients: (json['usedIngredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e))
            .toList(),
        missedIngredients: (json['missedIngredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e))
            .toList(),
        missedCount: json['missedIngredientCount'] ?? 0,
      );
}