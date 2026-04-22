import 'package:drift/drift.dart';

import 'database_connection_impl_io.dart'
    if (dart.library.html) 'database_connection_impl_web.dart' as impl;

QueryExecutor openConnection() => impl.openConnection();
