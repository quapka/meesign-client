import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path_pkg;

import 'daos.dart';
import 'tables.dart';
// FIXME: bug in modular generation? necessary for TaskState
import '../model/key_type.dart';
import '../model/protocol.dart';
import '../model/task.dart';

// auto-generated by drift_dev using
// dart run build_runner build
part 'database.g.dart';

@DriftDatabase(
  tables: [
    Devices,
    Users,
    Tasks,
    Groups,
    GroupMembers,
    Files,
    Challenges,
    Decrypts
  ],
  daos: [DeviceDao, UserDao, TaskDao],
)
class Database extends _$Database {
  static const fileName = 'db.sqlite';

  Database(io.Directory dir) : super(_open(dir));

  static LazyDatabase _open(io.Directory dir) => LazyDatabase(() async {
        // final file = io.File(path_pkg.join(dir.path, fileName));
        return NativeDatabase.memory();
      });

  @override
  int get schemaVersion => 1;
}
