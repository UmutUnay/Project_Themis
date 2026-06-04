import 'package:nocterm/nocterm.dart';

class FutureBuilder<T> extends StatefulComponent {
  final Future<T> future;
  final T? initialData;
  final Component Function(BuildContext context, T? data) builder;

  FutureBuilder({
    required this.future,
    this.initialData,
    required this.builder,
    super.key,
  });
  @override
  State<FutureBuilder<T>> createState() => _FutureBuilderState<T>();
}

class _FutureBuilderState<T> extends State<FutureBuilder<T>> {
  late T? data = component.initialData;

  @override
  void initState() {
    super.initState();
    component.future.then(awaitFuture);
  }

  @override
  void didUpdateComponent(covariant FutureBuilder<T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.future != component.future) {
      component.future.then(awaitFuture);
    }
  }

  void awaitFuture(T d) => setState(() => data = d);

  @override
  Component build(BuildContext context) {
    return component.builder(context, data);
  }
}
