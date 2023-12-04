# MeeSign Core

## Regenerate Drift database code

After modifying the database code (`lib/src/database/{daos,database,tables}.dart`), make sure to also update the auto-generated files:

```bash
dart run build_runner build
```

For more information, see [Drift docs](https://drift.simonbinder.eu/docs/getting-started/).

## Example CLI clients

For the purposes of various testing it can be useful to have a CLI clients. Currently, there is a client `example/time_policy.dart` that support time policy, i.e., it signs only during a certain time range. The next example is an _always sign_ client - that signs any request all the time.

### Always-sign example client

Make sure that you have MeeSign Client setup according to the top-level [README.md](https://github.com/quapka/meesign-client/tree/add-ptsrsap1#meesign-client). The change the directory to `meesign_core/example/`. Compile the `always_sign.dart` application with:

```bash
$ dart compile exe always_sign.dart
```

After the client application is compiled you can start it like this (make sure to have the MeeSign server running and reachable from the device of the client):
```bash
./always_sign.exe --host {meesign-server-host} --port {meesign-server-port} --user-name {client's name}
```
