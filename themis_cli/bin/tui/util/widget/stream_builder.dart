import 'dart:async';

import 'package:nocterm/nocterm.dart';

class StreamBuilder<T> extends StatefulComponent {
  final Stream<T> stream;
  final Component Function(BuildContext context, T? data) builder;
  final T initialData;

  StreamBuilder({
    required this.stream,
    required this.builder,
    required this.initialData,
    super.key,
  });
  @override
  State<StreamBuilder<T>> createState() => _StreamBuilderState<T>();
}

class _StreamBuilderState<T> extends State<StreamBuilder<T>> {
  late StreamSubscription subscription;
  late T data = component.initialData;

  @override
  Future<void> initState() async {
    super.initState();
    subscription = component.stream.listen(onData);
  }

  @override
  void didUpdateComponent(covariant StreamBuilder<T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.stream != component.stream) {
      subscription.cancel();
      subscription = component.stream.listen(onData);
    }
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Future<void> onData(T d) async => setState(() => data = d);

  @override
  Component build(BuildContext context) {
    return component.builder(context, data);
  }
}
