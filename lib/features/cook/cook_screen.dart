import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_card.dart';
import '../pantry/bloc/pantry_bloc.dart';
import '../pantry/bloc/pantry_state.dart';
import 'bloc/cook_bloc.dart';
import 'bloc/cook_event.dart';
import 'bloc/cook_state.dart';
import 'models/recipe_suggestion.dart';
import '../../data/services/recipe_api_service.dart';

class CookScreen extends StatelessWidget {
  const CookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PantryBloc, PantryState>(
      listener: (context, pantryState) {
        if (pantryState is PantryLoaded) {
          final names = pantryState.items.map((i) => i.name).toList();
          context.read<CookBloc>().add(CookSuggestionsRequested(names));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text('What to cook', style: AppTextStyles.heading1),
              ),
              Expanded(
                child: BlocBuilder<CookBloc, CookState>(
                  builder: (context, state) {
                    if (state is CookInitial) {
                      final pantryState = context.read<PantryBloc>().state;
                      if (pantryState is PantryLoaded) {
                        final names =
                            pantryState.items.map((i) => i.name).toList();
                        context
                            .read<CookBloc>()
                            .add(CookSuggestionsRequested(names));
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    if (state is CookLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    if (state is CookEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.kitchen_outlined,
                                size: 48, color: AppColors.borderStrong),
                            const SizedBox(height: 12),
                            Text(
                              'Add items to your pantry first',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is CookError) {
                      return Center(
                          child: Text(state.message, style: AppTextStyles.body));
                    }

                    if (state is CookLoaded) {
                      return _RecipeList(state: state);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recipe list ────────────────────────────────────────────────────────────

class _RecipeList extends StatelessWidget {
  final CookLoaded state;
  const _RecipeList({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (state.fullMatches.isNotEmpty) ...[
          Text('Ready to make', style: AppTextStyles.label),
          const SizedBox(height: 8),
          ...state.fullMatches.map((r) => _RecipeCard(recipe: r)),
          const SizedBox(height: 20),
        ],
        if (state.partialMatches.isNotEmpty) ...[
          Text('Almost there', style: AppTextStyles.label),
          const SizedBox(height: 8),
          ...state.partialMatches.map((r) => _RecipeCard(recipe: r)),
        ],
        if (state.fullMatches.isEmpty && state.partialMatches.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Text(
                'No recipes found for your pantry',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Recipe card ────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final RecipeSuggestion recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showRecipeDetail(context, recipe),
        child: MiseCard(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  recipe.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: AppColors.surface,
                    child: const Icon(Icons.restaurant_outlined,
                        color: AppColors.borderStrong),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: AppTextStyles.body),
                    const SizedBox(height: 4),
                    if (recipe.isFullMatch)
                      Text(
                        'You have everything',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary),
                      )
                    else
                      Text(
                        'Missing: ${recipe.missedIngredients.map((i) => i.name).join(', ')}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.borderStrong),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail bottom sheet ────────────────────────────────────────────────────

void _showRecipeDetail(BuildContext context, RecipeSuggestion recipe) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RecipeDetailSheet(recipe: recipe),
  );
}

class _RecipeDetailSheet extends StatefulWidget {
  final RecipeSuggestion recipe;
  const _RecipeDetailSheet({required this.recipe});

  @override
  State<_RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<_RecipeDetailSheet> {
  String? _instructions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInstructions();
  }

  Future<void> _fetchInstructions() async {
    final service = RecipeApiService('d3e1de5696b44bc793f5f1f0a5a46409');
    final data = await service.getRecipeInfo(widget.recipe.id);
    if (!mounted) return;
    setState(() {
      _instructions = data?['instructions'] ?? 'No instructions available.';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(widget.recipe.imageUrl, height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200, color: AppColors.surface,
                  child: const Icon(Icons.restaurant_outlined,
                      size: 48, color: AppColors.borderStrong),
                )),
          ),
          const SizedBox(height: 16),
          Text(widget.recipe.title, style: AppTextStyles.heading1),
          const SizedBox(height: 16),

          Text('IN YOUR PANTRY', style: AppTextStyles.label),
          const SizedBox(height: 8),
          ...widget.recipe.usedIngredients.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('${i.amount} ${i.unit} ${i.name}', style: AppTextStyles.body),
            ]),
          )),

          if (widget.recipe.missedIngredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('MISSING', style: AppTextStyles.label),
            const SizedBox(height: 8),
            ...widget.recipe.missedIngredients.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.radio_button_unchecked,
                    size: 14, color: AppColors.borderStrong),
                const SizedBox(width: 8),
                Text('${i.amount} ${i.unit} ${i.name}', style: AppTextStyles.body),
              ]),
            )),
          ],

          const SizedBox(height: 20),
          Text('HOW TO PREPARE', style: AppTextStyles.label),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2))
          else
            Html(
              data: _instructions ?? '',
              style: {
                'body': Style(
                  fontSize: FontSize(13),
                  color: AppColors.textPrimary,
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
              },
            ),
        ],
      ),
    );
  }
}