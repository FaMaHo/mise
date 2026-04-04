import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users_table.dart';
import 'tables/households_table.dart';
import 'tables/pantry_items_table.dart';
import 'tables/shopping_list_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Users, Households, PantryItems, ShoppingListItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mise.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}