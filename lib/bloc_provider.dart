import 'package:flutter/widgets.dart';

import 'hn_bloc.dart';

class BlocProvider extends InheritedWidget {
  final HackerNewsBloc bloc;

  const BlocProvider({Key key, Widget child, this.bloc}) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant BlocProvider oldWidget) => bloc != oldWidget.bloc;

  static BlocProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }
}