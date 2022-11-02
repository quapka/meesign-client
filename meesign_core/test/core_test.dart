@Timeout(Duration(seconds: 180))

import 'dart:async';
import 'dart:io';

import 'package:meesign_core/meesign_core.dart';
import 'package:meesign_core/src/model/key_type.dart';
import 'package:test/test.dart';

import 'matcher.dart';

extension ListStream<T> on Stream<Iterable<T>> {
  Future<T> firstElement() async =>
      (await firstWhere((iter) => iter.isNotEmpty)).first;

  Future<T> firstElementWhere(bool Function(T) test) =>
      map((iter) => iter.where(test)).firstElement();
}

class SimpleDirProvider implements DirProvider {
  final String path;

  SimpleDirProvider(this.path);

  @override
  Future<Directory> getStoreDirectory() async => Directory(path);
}

// TODO: use stream matchers?

Future<void> approveFirst(
  TaskRepository taskRepository,
  Device d, {
  bool agree = true,
}) async {
  final t = await taskRepository.observeTasks(d.id).firstElement();
  await taskRepository.approveTask(d.id, t.id, agree: agree);
}

Future<void> approveAllFirst(
  TaskRepository taskRepository,
  Iterable<Device> devices,
) =>
    Future.wait(
      devices.map((d) => approveFirst(taskRepository, d)),
    );

void sync(
  GroupRepository groupRepository,
  FileRepository fileRepository,
  Iterable<Device> devices,
) async {
  await Future.wait(devices.map((d) async {
    await groupRepository.sync(d.id);
    await fileRepository.sync(d.id);
  }));

  Timer(
    Duration(milliseconds: 100),
    () => sync(groupRepository, fileRepository, devices),
  );
}

Future<void> sign(
  DeviceRepository deviceRepository,
  GroupRepository groupRepository,
  FileRepository fileRepository, {
  required int n,
  required int t,
}) async {
  assert(2 <= t && t <= n);

  final ds = await Future.wait(
    [for (var i = 0; i < n; i++) deviceRepository.register('d$i')],
  );

  await Future.wait(ds.map((d) => groupRepository.subscribe(d.id)));

  await groupRepository.group(
      '$t out of $n', ds, t, Protocol.gg18, KeyType.signPdf);
  approveAllFirst(groupRepository, ds);
  final gs = await Future.wait(
    ds.map((d) => groupRepository.observeGroups(d.id).firstElement()),
  );
  expect(gs.map((g) => g.id), allEqual);

  await Future.wait(ds.map((d) => fileRepository.subscribe(d.id)));

  await fileRepository.sign('test/file.pdf', gs[0].id);
  approveAllFirst(fileRepository, ds.take(t));
  final fs = await Future.wait(
    ds.map((d) => fileRepository.observeFiles(d.id).firstElement()),
  );

  await Future.wait(ds.map(
    (d) => fileRepository
        .observeTasks(d.id)
        .firstElementWhere((t) => t.state == TaskState.finished),
  ));
}

const String outputPath = 'test/output';

void main() {
  late MPCClient client;
  late DeviceRepository deviceRepository;
  late GroupRepository groupRepository;
  late FileRepository fileRepository;

  setUp(() {
    client = ClientFactory.create('localhost', allowBadCerts: true);
    deviceRepository = DeviceRepository(client);
    final taskSource = TaskSource(client);
    groupRepository = GroupRepository(client, taskSource, deviceRepository);
    final fileStore = FileStore(SimpleDirProvider(outputPath));
    fileRepository =
        FileRepository(client, taskSource, fileStore, groupRepository);
  });

  Future<void> testSign({required int n, required int t}) =>
      sign(deviceRepository, groupRepository, fileRepository, n: n, t: t);

  test('2-3 sign', () => testSign(n: 3, t: 2));
  test('3-3 sign', () => testSign(n: 3, t: 3));
  test('3-5 sign', () => testSign(n: 5, t: 3));

  tearDown(() {
    try {
      Directory(outputPath).deleteSync(recursive: true);
    } catch (_) {}
  });
}
