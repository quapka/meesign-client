import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:meesign_core/meesign_core.dart';
import 'package:meta/meta.dart';
import 'package:convert/convert.dart';

extension Range<T> on Comparable<T> {
  bool within(T a, T b) => compareTo(a) >= 0 && compareTo(b) <= 0;
}

extension Approval<T> on TaskRepository<T> {
  StreamSubscription<Task<T>> approveAll(Device device,
      {required bool Function(Task<T>) agree}) {
    return observeTasks(device.id)
        .expand((tasks) => tasks)
        .where((task) => !task.approved)
        .listen((task) async {
      await approveTask(device.id, task.id, agree: agree(task));
    });
  }
}

class DummyFileStore implements FileStore {
  @override
  String getFilePath(Uuid did, Uuid id, String name, {bool work = false}) =>
      name;

  @override
  Future<String> storeFile(Uuid did, Uuid id, String name, List<int> data,
          {bool work = false}) async =>
      getFilePath(did, id, name, work: work);
}

void printUsage(ArgParser parser, IOSink sink) {
  sink.writeln('Usage:');
  sink.writeln(parser.usage);
}

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'display usage information',
      negatable: false,
    )
    ..addOption(
      'host',
      help: 'MeeSign server address',
      defaultsTo: 'localhost',
    )
    ..addOption(
      'name',
      help: 'Name of the group',
      defaultsTo: 'always sign',
    )
    ..addOption(
      'user-name',
      help: 'Name of the user',
      mandatory: true,
    )
    // NOTE: picking port is yet to be implemented on the client side
    ..addOption(
      'port',
      help: 'MeeSign server port',
      mandatory: true,
    )
    ..addOption(
      'protocol',
      valueHelp: 'gg18, frost, ptsrsap1',
      defaultsTo: 'ptsrsap1',
    )
    ..addOption(
      'max-signers',
      valueHelp: '2',
      defaultsTo: '2',
    )
    ..addOption(
      'min-signers', // threshold
      valueHelp: '2',
      defaultsTo: '2',
    );

  late final ArgResults options;
  late final int maxSigners, minSigners;
  late final Protocol protocol;
  late final String name;
  late final String userName;
  late final int port;

  try {
    options = parser.parse(args);
    minSigners = int.parse(options['min-signers']);
    maxSigners = int.parse(options['max-signers']);
    port = int.parse(options['port']);
  } on Exception catch (e) {
    stderr.writeln(e.toString());
    printUsage(parser, stderr);
    return;
  }
  if (options['help']) {
    printUsage(parser, stdout);
    return;
  }
  name = options['name'];
  userName = options['user-name'];

  switch (options['protocol']) {
    case 'gg18':
      stderr.writeln("Protocol: GG18");
      protocol = Protocol.gg18;
      break;
    case 'frost':
      protocol = Protocol.frost;
      stderr.writeln("Protocol: Frost");
      break;
    case 'ptsrsap1':
      protocol = Protocol.ptsrsap1;
      stderr.writeln("Protocol: PTS RSA P1");
      break;
    default:
      stderr.writeln("Unrecognized protocol: ${options['protocol']}");
      printUsage(parser, stderr);
      return;
  }

  // TODO: assert minSigners <= maxSigners;
  print("Always signing $userName:$name $minSigners-out-of-$maxSigners");

  final appDir = Directory(
      'data.always_sign-$userName-$name-$minSigners-$maxSigners.$protocol/');

  final database = Database(appDir);
  final keyStore = KeyStore(appDir);
  final dispatcher = NetworkDispatcher(
    options['host'],
    keyStore,
    allowBadCerts: true,
    port: port,
  );
  final taskSource = TaskSource(dispatcher);
  final taskDao = database.taskDao;
  final deviceRepository =
      DeviceRepository(dispatcher, keyStore, database.deviceDao);
  final groupRepository =
      GroupRepository(dispatcher, taskSource, taskDao, deviceRepository);
  final fileRepository =
      FileRepository(dispatcher, taskSource, taskDao, DummyFileStore());
  final challengeRepository =
      ChallengeRepository(dispatcher, taskSource, taskDao);

  // final List<Device> devices = [];
  // for (var devInd = 0; devInd < maxSigners; devInd++) {
  Device device = await deviceRepository.fetchOrRegister(userName);
  // devices.add(device);
  // print("$devInd: ${hex.encode(device.id.bytes)}");
  // }

  // final deviceA = (await deviceRepository.search("xxxA")).first;
//   final deviceB = (await deviceRepository.search("B")).first;

//   // final deviceA = await deviceRepository.register("A");
//   // final deviceB = await deviceRepository.register("B");
//   // final deviceC = await deviceRepository.register("B");
//   // print("Devices added");

  // for (var devInd = 0; devInd < maxSigners; devInd++) {
  //   print("$devInd: subscribing");
  await groupRepository.subscribe(device.id);
  await fileRepository.subscribe(device.id);
  await challengeRepository.subscribe(device.id);
  // }

  // print("creating a group");
  // final keyType = KeyType.signChallenge;
  // await groupRepository.group(name, devices, minSigners, protocol, keyType);

  // for (var devInd = 0; devInd < maxSigners; devInd++) {
  print("$userName: approving all");
  groupRepository.approveAll(device, agree: (_) => true);
  fileRepository.approveAll(device, agree: (_) => true);
  challengeRepository.approveAll(device, agree: (_) => true);
  // }

//   await groupRepository.subscribe(deviceA.id);
//   await fileRepository.subscribe(deviceA.id);
//   await challengeRepository.subscribe(deviceA.id);

//   await groupRepository.subscribe(deviceB.id);
//   await fileRepository.subscribe(deviceB.id);
//   await challengeRepository.subscribe(deviceB.id);

//   // // await groupRepository.subscribe(deviceC.id);
//   // // await fileRepository.subscribe(deviceC.id);
//   // // await challengeRepository.subscribe(deviceC.id);
//   // print("Both devices have subscribed");

//   // final members = [deviceA, deviceB]; //, deviceC];
//   // print("Approving group membership");

//   groupRepository.approveAll(deviceA, agree: (_) => true);
//   groupRepository.approveAll(deviceB, agree: (_) => true);
//   // // groupRepository.approveAll(deviceC, agree: (_) => true);

//   fileRepository.approveAll(deviceA, agree: (_) => true);
//   fileRepository.approveAll(deviceB, agree: (_) => true);
//   // // fileRepository.approveAll(deviceC, agree: (_) => true);

//   challengeRepository.approveAll(deviceA, agree: (_) => true);
//   challengeRepository.approveAll(deviceB, agree: (_) => true);
//   // // challengeRepository.approveAll(deviceC, agree: (_) => true);

  // FIXME: Use locks on the tasks itself
  ProcessSignal.sigint.watch().listen((signal) {
    print('closing db');
    database.close();
    exit(0);
  });
}
