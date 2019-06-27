[![Flutter Community: state_persistence](https://fluttercommunity.dev/_github/header/state_persistence)](https://github.com/fluttercommunity/community)

# State Persistence

[![pub package](https://img.shields.io/pub/v/state_persistence.svg)](https://pub.dartlang.org/packages/state_persistence)

Persist state across app launches. By default this library store 
state as a local JSON file called `data.json` in the applications
data directory. You can change this filename by providing another
storage mechanism.

If you do not want to store your persisted app state as a JSON 
file you can extend `PersistedStateStorage` and provide your own 
methods for saving and loading data. E.g `shared_preferences` or 
`sqflite`. For those of you that are ambitious you could even 
store your state on the web or even in Firebase.

To change the persisted state simply modify the values in the 
data map. These changes will automatically be persisted to disk
based on the `saveTimeout` given to the `PersistedAppState` widget.
By default this value is `500` milliseconds. This timeout is used
to stop disk thrashing on multiple map changes in quick succession.  

### Example

```dart
import 'package:flutter/material.dart';
import 'package:state_persistence/state_persistence.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return PersistedAppState(
      storage: JsonFileStorage(),
      child: MaterialApp(
        title: 'Persistent TextField Example',
        theme: ThemeData(primarySwatch: Colors.indigo),
        home: Scaffold(
          appBar: AppBar(title: Text('Persistent TextField Example')),
          body: Container(
            padding: const EdgeInsets.all(32.0),
            alignment: Alignment.center,
            child: PersistedStateBuilder(
              builder: (BuildContext context, AsyncSnapshot<PersistedData> snapshot) {
                if (snapshot.hasData) {
                  if (_textController == null) {
                    _textController = TextEditingController(text: snapshot.data['text'] ?? '');
                  }
                  return TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter some text',
                    ),
                    onChanged: (String value) => snapshot.data['text'] = value,
                  );
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
```
