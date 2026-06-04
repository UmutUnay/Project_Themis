/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-20 00:41:41
 * @LastEditTime: 2025-12-17 23:46:13
 * @Description: 
 */

extension StringToRegex on String? {
  /// Turns nullable [String] into nullable [RegExp]
  RegExp? toRegex() => this == null ? null : RegExp(this!);
}

extension CallMaybe<R, T> on R Function(T t) {
  R? callMaybe(T? t) => switch (t) {
    null => null,
    T t => this(t),
  };
}

extension ComplexNullable<T, R> on T? {
  R? nullOr(R Function(T e) transform) => transform.callMaybe(this);
}
