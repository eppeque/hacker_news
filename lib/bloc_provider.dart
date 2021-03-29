import 'package:flutter/widgets.dart';

import 'hn_bloc.dart';

/// This is an [InheritedWidget] to be able to access to the [HackerNewsBloc] everywhere in the app with a simple call to the `of()` function.
/// For example :
/// ```dart
/// final bloc = BlocProvider.of(context).bloc;
/// ```
class BlocProvider extends InheritedWidget {
  final HackerNewsBloc bloc;

  /// Creates a provider to access to the [HackerNewsBloc] everywhere in the app using `bloc`
  const BlocProvider({Key? key, required Widget child, required this.bloc}) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant BlocProvider oldWidget) => bloc != oldWidget.bloc;

  static BlocProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }
}