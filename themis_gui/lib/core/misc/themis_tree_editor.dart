import 'package:themis_ui_lib/themis_ui_lib.dart';

/// Helper class to recursively edit a [ThemisItem] tree.
class ThemisTreeEditor<T extends ThemisItem> {
  T root;
  ThemisTreeEditor(this.root);

  /// Replaces the item with [item.id] with [item]. Returns success.
  bool replaceItem(ThemisItem item) {
    bool result = false;
    switch (root) {
      case var other when other.id == item.id && item is T:
        root = item;
        result = true;
      case NestedItem nested:
        final items = nested.items.toList();
        for (var (i, it) in items.indexed) {
          final editor = ThemisTreeEditor(it);
          result |= editor.replaceItem(item);
          if (result) {
            items[i] = editor.root;
            break;
          }
        }
        if (result) root = nested.copyWithItems(items);
      default:
    }

    return result;
  }

  /// Adds [item] as a child of the [NestedItem] at [id]. Returns success.
  bool addItem(String id, ThemisItem item, [int index = -1]) {
    bool result = false;
    switch (root) {
      case NestedItem nested when nested.id == id:
        final items = nested.items.toList();
        if (index < 0) {
          index += items.length + 1;
        } else if (index > items.length) {
          index = items.length;
        }
        items.insert(index, item);
        result = true;
        root = nested.copyWithItems(items);
      case NestedItem nested:
        final items = nested.items.toList();
        for (var (i, it) in items.indexed) {
          final editor = ThemisTreeEditor(it);
          result |= editor.addItem(id, item, index);
          if (result) {
            items[i] = editor.root;
            break;
          }
        }
        if (result) root = nested.copyWithItems(items);
      default:
    }
    return result;
  }

  /// Remove item with [id] from the tree. Returns success.
  bool removeItem(String id) {
    bool result = false;
    switch (root) {
      case NestedItem nested:
        final items = nested.items.toList();
        for (var (i, it) in items.indexed) {
          if (it.id == id) {
            items.removeAt(i);
            result = true;
            break;
          }
          final editor = ThemisTreeEditor(it);
          result |= editor.removeItem(id);
          if (result) {
            items[i] = editor.root;
            break;
          }
        }
        if (result) root = nested.copyWithItems(items);
      default:
    }
    return result;
  }
}
