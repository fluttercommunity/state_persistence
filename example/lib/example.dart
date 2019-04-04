import 'package:flutter/material.dart';
import 'package:state_persistence/state_persistence.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PersistedAppState(
      storage: JsonFileStorage(),
      child: MaterialApp(
        title: 'Persistent Tab Example',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: ExampleScreen1(),
      ),
    );
  }
}

class ExampleScreen1 extends StatefulWidget {
  @override
  _ExampleScreen1State createState() => _ExampleScreen1State();
}

class _ExampleScreen1State extends State<ExampleScreen1> with SingleTickerProviderStateMixin {
  PersistedData _data;
  TabController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data = PersistedAppState.of(context);
    if (_data != null && _controller == null) {
      _controller = TabController(initialIndex: _data['tab'] ?? 0, vsync: this, length: 4);
      _controller.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (!_controller.indexIsChanging) {
      _data['tab'] = _controller.index;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_data != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Persistent Tab Example'),
          bottom: TabBar(
            controller: _controller,
            tabs: [
              Tab(text: 'First'),
              Tab(text: 'Second'),
              Tab(text: 'Third'),
              Tab(text: 'Forth'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _controller,
          children: [
            Center(child: Text('Tab 1')),
            Center(child: Text('Tab 2')),
            Center(child: Text('Tab 3')),
            Center(child: Text('Tab 4')),
          ],
        ),
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }
}
