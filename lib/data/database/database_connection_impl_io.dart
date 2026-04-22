import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final dbDir = Directory('${docs.path}/Moonfin/DB');
    if (!dbDir.existsSync()) {
      await dbDir.create(recursive: true);
    }
    final file = File('${dbDir.path}/offline.db');
    return NativeDatabase.createInBackground(file);
  });
}
