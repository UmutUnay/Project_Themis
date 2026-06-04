import 'package:nocterm/nocterm.dart';

// class ChangeNotifierProvider<T extends ChangeNotifier> extends InheritedProvider<T> {

//   ChangeNotifierProvider({
//     required super.value,
//     required super.child,
//     super.key,
//   }) {
//     value.addListener(listener);
//   }

//   void listener() {

//     element?.notifyClients(element.component);
//   }

//   @override
//   InheritedElement createElement() {
//     // TODO: implement createElement
//     return super.createElement();
//   }
// }

class InheritedProvider<T> extends InheritedComponent {
  final T value;

  const InheritedProvider({
    required this.value,
    required super.child,
    super.key,
  });

  static T? of<T>(BuildContext context, {bool listen = true}) {
    final element = context
        .getElementForInheritedComponentOfExactType<InheritedProvider<T>>();
    final value = element == null
        ? null
        : (element.component as InheritedProvider<T>).value;
    if (listen) {
      context.dependOnInheritedComponentOfExactType<InheritedProvider<T>>();
    }
    return value;
  }

  @override
  bool updateShouldNotify(covariant InheritedProvider<T> oldComponent) {
    return value != oldComponent.value;
  }
}

class ChangeNotifierProvider<T extends ChangeNotifier>
    extends StatefulComponent {
  final T changeNotifier;
  final Component child;
  const ChangeNotifierProvider({
    required this.changeNotifier,
    required this.child,
    super.key,
  });
  @override
  State<ChangeNotifierProvider<T>> createState() =>
      _ChangeNotifierProviderState<T>();
}

class _ChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<ChangeNotifierProvider<T>> {
  @override
  void initState() {
    super.initState();
    component.changeNotifier.addListener(listen);
  }

  @override
  void dispose() {
    component.changeNotifier.removeListener(listen);
    super.dispose();
  }

  void listen() => setState(() {});

  @override
  Component build(BuildContext context) {
    return InheritedProvider(
      value: component.changeNotifier,
      child: component.child,
    );
  }
}

class Selector<P, T> extends StatefulComponent {
  final T Function(P provided) selector;
  final Component Function(BuildContext context, T value) builder;
  final P? provided;
  const Selector({
    required this.selector,
    required this.builder,
    this.provided,
    super.key,
  });
  @override
  State<Selector<P, T>> createState() => _SelectorState<P, T>();
}

class _SelectorState<P, T> extends State<Selector<P, T>> {
  Component? child;
  T? value;

  @override
  Component build(BuildContext context) {
    final newValue = component.selector(
      component.provided ?? InheritedProvider.of<P>(context) as P,
    );
    if (newValue != value || child == null) {
      child = component.builder(context, newValue);
      value = newValue;
    }
    return child!;
  }
}
