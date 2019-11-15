library state_persistence;

import 'dart:async' show Future, Timer;
import 'dart:collection' show MapBase;
import 'dart:convert' show json, JsonCodec;
import 'dart:io' show Directory, File;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

Directory _appDataDir;

/// Add to your widget hierarchy to add app-wide state persistence.
class PersistedAppState extends StatefulWidget {
  const PersistedAppState({
    Key key,
    this.storage = const JsonFileStorage(),
    this.saveTimeout = const Duration(milliseconds: 500),
    @required this.child,
  })  : assert(storage != null && child != null),
        super(key: key);

  /// Storage mechanism used to load/save app state.
  final PersistedStateStorage storage;

  /// When this timeout period expires the changed state is saved.
  /// This stops calling save on many minor changes.
  final Duration saveTimeout;

  /// Child Widget
  final Widget child;

  /// Used to fetch persisted data anywhere across the app.
  /// Results in null if data is not yet loaded.
  static PersistedData of(BuildContext context) => snapshot(context)?.data;

  /// Used to fetch the AsyncSnapshot of the persisted data.
  /// This allows you to monitor the progress of the loading data.
  static AsyncSnapshot<PersistedData> snapshot(BuildContext context) {
    final _PersistedScope scope = context.inheritFromWidgetOfExactType(_PersistedScope);
    return scope.snapshot;
  }

  @override
  _PersistedAppState createState() => _PersistedAppState();
}

class _PersistedAppState extends State<PersistedAppState> {
  Future<PersistedData> _future;
  PersistedData _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(PersistedAppState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storage != widget.storage) {
      _loadData();
    }
  }

  void _loadData() {
    _future = PersistedData.load(widget.storage, widget.saveTimeout).then((result) => _data = result);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersistedData>(
      initialData: _data,
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<PersistedData> snapshot) {
        return _PersistedScope(
          snapshot: snapshot,
          child: widget.child,
        );
      },
    );
  }
}

class _PersistedScope extends InheritedWidget {
  const _PersistedScope({
    Key key,
    @required this.snapshot,
    @required Widget child,
  })  : assert(child != null),
        super(key: key, child: child);

  final AsyncSnapshot<PersistedData> snapshot;

  @override
  bool updateShouldNotify(_PersistedScope old) => old.snapshot != snapshot;
}

/// You can use this builder to access the current persisted data.
/// It will automatically rebuild when the persisted data is loaded.
class PersistedStateBuilder extends StatelessWidget {
  const PersistedStateBuilder({
    Key key,
    @required this.builder,
  })  : assert(builder != null),
        super(key: key);

  final AsyncWidgetBuilder<PersistedData> builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, PersistedAppState.snapshot(context));
  }
}

/// Accessed as a map so you can store key/value pairs of data.
/// Values are dynamic allowing you do store information in multiple depths.
/// This however doesn't guarantee the storage mechanism will save/load multiple depths.
class PersistedData extends MapBase<String, dynamic> {
  PersistedData._(this._storage, this._data, this._saveTimeout);

  final PersistedStateStorage _storage;
  final Map<String, dynamic> _data;
  final Duration _saveTimeout;
  Timer _saveTask;

  static Future<PersistedData> load(PersistedStateStorage storage, Duration saveTimeout) async {
    return PersistedData._(
        storage,
        await storage.load().catchError((e, st) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: e,
            stack: st,
            library: 'state_persistence',
            silent: true,
          ));
        }),
        saveTimeout);
  }

  @override
  Iterable<String> get keys => _data.keys;

  @override
  dynamic operator [](Object key) {
    return _data[key];
  }

  @override
  void operator []=(String key, dynamic value) {
    _data[key] = value;
    persist();
  }

  @override
  dynamic remove(Object key) {
    final value = _data.remove(key);
    persist();
    return value;
  }

  @override
  void clear() {
    _data.clear();
    persist();
  }

  void persist() {
    _saveTask?.cancel();
    _saveTask = Timer(_saveTimeout, () {
      return _storage.save(_data).catchError((e, st) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'state_persistence',
          silent: true,
        ));
      });
    });
  }
}

/// Extend this class to provide your own persisted storage mechanism.
abstract class PersistedStateStorage {
  const PersistedStateStorage();

  Future<Map<String, dynamic>> load();

  Future<void> save(Map<String, dynamic> data);

  Future<void> clear();
}

/// Uses the default [JsonCodec], to store the persisted state.
class JsonFileStorage extends PersistedStateStorage {
  const JsonFileStorage({
    this.filename = 'data.json',
    this.initialData = const {},
    this.clearDataOnLoadError = false,
  }) : assert(filename != null && initialData != null && clearDataOnLoadError != null);

  final String filename;
  final Map<String, dynamic> initialData;
  final bool clearDataOnLoadError;

  Future<File> get stateFile async {
    _appDataDir ??= await getApplicationDocumentsDirectory();
    return File(p.join(_appDataDir.path, filename));
  }

  @override
  Future<Map<String, dynamic>> load() async {
    final file = await stateFile;
    if (await file.exists()) {
      try {
        return json.decode(await file.readAsString());
      } catch (e, st) {
        if (clearDataOnLoadError) {
          await clear();
        }
        FlutterError.reportError(FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'state_persistence',
          silent: true,
        ));
      }
    }
    return Map.from(initialData);
  }

  @override
  Future<void> save(Map<String, dynamic> data) {
    return stateFile.then((file) => file.writeAsString(json.encode(data)));
  }

  @override
  Future<void> clear() {
    return stateFile.then((file) => file.delete());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is JsonFileStorage && runtimeType == other.runtimeType && filename == other.filename;
  }

  @override
  int get hashCode => filename.hashCode;
}
