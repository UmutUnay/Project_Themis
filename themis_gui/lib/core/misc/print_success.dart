import 'package:flutter/widgets.dart';
import 'package:toastification/toastification.dart';

void notifySuccess(
  BuildContext context,
  bool success, {
  required String successText,
  required String failureText,
  bool indefinite = false,
}) {
  if (success) {
    toastification.show(
      context: context,
      alignment: .bottomRight,
      style: .flatColored,
      type: .success,
      autoCloseDuration: indefinite ? null : const Duration(seconds: 5),
      showProgressBar: true,
      title: Text(successText),
      closeButton: ToastCloseButton(showType: indefinite ? .none : .always),
      dragToClose: !indefinite,
    );
  } else {
    toastification.show(
      context: context,
      alignment: .bottomRight,
      style: .flatColored,
      type: .error,
      autoCloseDuration: indefinite ? null : const Duration(seconds: 5),
      showProgressBar: true,
      title: Text(failureText),
      closeButton: ToastCloseButton(showType: indefinite ? .none : .always),
      dragToClose: !indefinite,
    );
  }
}
