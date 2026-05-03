import '../../data/local/database.dart';
import '../../data/repositories/pantry_repository.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final AppDatabase db;
  late final PantryRepository pantryRepository;

  void init() {
    db = AppDatabase();
    pantryRepository = PantryRepository(db);
  }
}

final sl = ServiceLocator();
