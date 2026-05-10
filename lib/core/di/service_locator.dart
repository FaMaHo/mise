import '../../data/local/database.dart';
import '../../data/repositories/pantry_repository.dart';
import '../../data/repositories/shopping_repository.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final AppDatabase db;
  late final PantryRepository pantryRepository;
  late final ShoppingRepository shoppingRepository;

  void init() {
    db = AppDatabase();
    pantryRepository = PantryRepository(db);
    shoppingRepository = ShoppingRepository(db);
  }
}

final sl = ServiceLocator();
