import 'package:flutter/material.dart';
import 'package:state_persistence/state_persistence.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  TextEditingController? _textController;

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
                final data = snapshot.data;
                if (data != null) {
                  if (_textController == null) {
                    _textController = TextEditingController(text: data['text'] ?? '');
                  }
                  return TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter some text',
                    ),
                    onChanged: (String value) => data['text'] = value,
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
