import 'package:drift/drift.dart';

class ShoppingListItems extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  TextColumn get addedByUserId => text()();
  DateTimeColumn get addedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}