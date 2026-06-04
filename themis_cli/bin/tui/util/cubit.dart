import 'package:nocterm/nocterm.dart';

class Cubit<T> extends ChangeNotifier {
  T _state;
  T get state => _state;
  Cubit(T initialState) : _state = initialState;

  void emit(T state) {
    _state = state;
    notifyListeners();
  }
}
