import 'dart:io';

bool askConfirmation(String prompt, bool defaultValue) {
  final values = defaultValue ? "Y/n" : "y/N";
  print("$prompt[$values]: ");
  final result = stdin.readLineSync();
  switch (result) {
    case "":
      return defaultValue;
    case "y" || "Y":
      return true;
    case "n" || "N":
      return false;
    default:
      print("Invalid answer: $result");
      return askConfirmation(prompt, defaultValue);
  }
}
