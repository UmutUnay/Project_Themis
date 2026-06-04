import 'package:collection/collection.dart';
import 'package:nocterm/nocterm.dart';

import 'provider.dart';

class NavigableFlex extends StatefulComponent {
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<Component> children;

  final bool Function(int selected) onSelected;
  final bool Function(int focused)? onFocused;
  final bool isFocused;
  final double spacing;

  const NavigableFlex({
    required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.children = const [],
    required this.onSelected,
    this.onFocused,
    required this.isFocused,
    this.spacing = 0,
    super.key,
  });

  @override
  State<NavigableFlex> createState() => _NavigableFlexState();
}

class _NavigableFlexState extends State<NavigableFlex> {
  int focusedIndex = 0;

  bool focusPrevious() {
    if (focusedIndex == 0) {
      return false;
    } else {
      focusedIndex--;
      component.onFocused?.call(focusedIndex);
      setState(() {});
      return true;
    }
  }

  bool focusNext() {
    if (focusedIndex == component.children.length - 1) {
      return false;
    } else {
      focusedIndex++;
      component.onFocused?.call(focusedIndex);
      setState(() {});
      return true;
    }
  }

  bool keyEventListener(KeyboardEvent event) =>
      component.isFocused &&
      switch ((component.direction, event)) {
        (.horizontal, KeyboardEvent(logicalKey: .arrowLeft)) => focusPrevious(),
        (.horizontal, KeyboardEvent(logicalKey: .arrowRight)) => focusNext(),
        (.vertical, KeyboardEvent(logicalKey: .arrowUp)) => focusPrevious(),
        (.vertical, KeyboardEvent(logicalKey: .arrowDown)) => focusNext(),
        (_, KeyboardEvent(logicalKey: .tab, isShiftPressed: true)) =>
          focusPrevious(),
        (_, KeyboardEvent(logicalKey: .arrowDown, isShiftPressed: false)) =>
          focusNext(),
        (_, KeyboardEvent(logicalKey: .enter)) => component.onSelected(
          focusedIndex,
        ),
        _ => false,
      };

  @override
  Component build(BuildContext context) {
    return Flex(
      direction: component.direction,
      mainAxisAlignment: component.mainAxisAlignment,
      mainAxisSize: component.mainAxisSize,
      crossAxisAlignment: component.crossAxisAlignment,
      textDirection: component.textDirection,
      verticalDirection: component.verticalDirection,
      textBaseline: component.textBaseline,
      children: component.children.mapIndexed((i, child) {
        var childFocused = component.isFocused && focusedIndex == i;
        return Padding(
          padding: i == 0 ? .zero : .only(top: component.spacing),
          child: Focusable(
            focused: childFocused,
            onKeyEvent: keyEventListener,
            child: ColoredBox(
              color: childFocused
                  ? TuiTheme.of(context).selectionColor
                  : TuiTheme.of(context).background,
              child: child,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class NavigableRow extends NavigableFlex {
  const NavigableRow({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.children,
    required super.onSelected,
    super.onFocused,
    required super.isFocused,
    super.spacing,
  }) : super(direction: Axis.horizontal);
}

/// Display children in a vertical array
class NavigableColumn extends NavigableFlex {
  const NavigableColumn({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.children,
    required super.onSelected,
    super.onFocused,
    required super.isFocused,
    super.spacing,
  }) : super(direction: Axis.vertical);
}

class NavigableGrid extends StatefulComponent {
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<Component> children;

  final Axis mainAxisDirection;
  final int crossAxisCount;
  final double mainAxisExtent;

  final bool Function(int selected) onSelected;
  final bool Function(int focused)? onFocused;
  final bool isFocused;

  const NavigableGrid({
    required this.mainAxisDirection,
    required this.crossAxisCount,
    this.mainAxisExtent = double.infinity,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.children = const [],
    required this.onSelected,
    this.onFocused,
    required this.isFocused,
    super.key,
  });

  @override
  State<NavigableGrid> createState() => _NavigableGridState();
}

class _NavigableGridState extends State<NavigableGrid> {
  int mainAxisFocusedIndex = 0;
  int crossAxisFocusedIndex = 0;
  int get focusedIndex =>
      mainAxisFocusedIndex * component.crossAxisCount + crossAxisFocusedIndex;
  int get mainAxisCount =>
      (component.children.length - 1) ~/ component.crossAxisCount + 1;

  bool focusUp() {
    if (component.mainAxisDirection == .vertical) {
      if (mainAxisFocusedIndex == 0) {
        return false;
      } else {
        mainAxisFocusedIndex--;
        component.onFocused?.call(focusedIndex);
        setState(() {});
        return true;
      }
    } else {
      if (crossAxisFocusedIndex == 0) {
        return false;
      } else {
        crossAxisFocusedIndex--;
        component.onFocused?.call(focusedIndex);
        setState(() {});
        return true;
      }
    }
  }

  bool focusLeft() {
    if (component.mainAxisDirection == .horizontal) {
      if (mainAxisFocusedIndex == 0) {
        return false;
      } else {
        mainAxisFocusedIndex--;
        component.onFocused?.call(focusedIndex);
        setState(() {});
        return true;
      }
    } else {
      if (crossAxisFocusedIndex == 0) {
        return false;
      } else {
        crossAxisFocusedIndex--;
        component.onFocused?.call(focusedIndex);
        setState(() {});
        return true;
      }
    }
  }

  bool focusDown() {
    if (component.mainAxisDirection == .vertical) {
      if (mainAxisFocusedIndex == mainAxisCount - 1) {
        return false;
      } else {
        mainAxisFocusedIndex++;
        component.onFocused?.call(focusedIndex);
        setState(() {});
        return true;
      }
    } else {
      if (crossAxisFocusedIndex == component.crossAxisCount - 1) {
        return false;
      } else {
        crossAxisFocusedIndex++;
        component.onFocused?.call(focusedIndex);
        setState(() {});
        return true;
      }
    }
  }

  bool focusRight() {
    if (component.mainAxisDirection == .horizontal) {
      if (mainAxisFocusedIndex == mainAxisCount - 1) {
        return false;
      } else {
        mainAxisFocusedIndex++;
        component.onFocused?.call(focusedIndex);
        setState(() {});
        return true;
      }
    } else {
      if (crossAxisFocusedIndex == component.crossAxisCount - 1) {
        return false;
      } else {
        crossAxisFocusedIndex++;
        component.onFocused?.call(focusedIndex);
        setState(() {});
        return true;
      }
    }
  }

  bool keyEventListener(KeyboardEvent event) =>
      component.isFocused &&
      switch (event) {
        KeyboardEvent(logicalKey: .arrowLeft) => focusLeft(),
        KeyboardEvent(logicalKey: .arrowRight) => focusRight(),
        KeyboardEvent(logicalKey: .arrowUp) => focusUp(),
        KeyboardEvent(logicalKey: .arrowDown) => focusDown(),
        KeyboardEvent(logicalKey: .enter) => component.onSelected(
          mainAxisFocusedIndex,
        ),
        _ => false,
      };

  @override
  Component build(BuildContext context) {
    final height = InheritedProvider.of<Size>(context)!.height;
    return Flex(
      direction: component.mainAxisDirection,
      mainAxisAlignment: component.mainAxisAlignment,
      mainAxisSize: component.mainAxisSize,
      crossAxisAlignment: component.crossAxisAlignment,
      textDirection: component.textDirection,
      verticalDirection: component.verticalDirection,
      textBaseline: component.textBaseline,
      children: component.children.indexed
          .groupListsBy(((v) => v.$1 ~/ component.crossAxisCount))
          .values
          .mapIndexed((i, children) {
            var mainAxisFocused =
                component.isFocused && mainAxisFocusedIndex == i;
            return Flex(
              direction: component.mainAxisDirection.other,
              mainAxisAlignment: component.mainAxisAlignment,
              mainAxisSize: component.mainAxisSize,
              crossAxisAlignment: component.crossAxisAlignment,
              textDirection: component.textDirection,
              verticalDirection: component.verticalDirection,
              textBaseline: component.textBaseline,
              children: children.mapIndexed((i, child) {
                var childFocused =
                    mainAxisFocused && crossAxisFocusedIndex == i;
                return Focusable(
                  focused: childFocused,
                  onKeyEvent: keyEventListener,
                  child: Container(
                    decoration: BoxDecoration(
                      color: childFocused
                          ? TuiTheme.of(context).selectionColor
                          : TuiTheme.of(context).background,
                      // title: BorderTitle(text: item.title),
                      border: BoxBorder.all(),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: component.mainAxisExtent,
                        maxHeight: height / component.crossAxisCount - 2,
                      ),
                      child: child.$2,
                    ),
                  ),
                );
              }).toList(),
            );
          })
          .toList(),
    );
  }
}

class Tile {
  final String? title;
  final Component body;
  final double mainAxisExtent;

  Tile({this.title, required this.body, required this.mainAxisExtent});

  Component buildPane(BuildContext context, double width, double height) {
    height = title == null ? height : height - 1;
    return Column(
      children: [
        if (title != null) Text(title!),
        Container(
          constraints: BoxConstraints(
            minWidth: width * 0.5,
            maxWidth: width,
            maxHeight: height,
          ),
          padding: .symmetric(horizontal: 1),
          margin: .symmetric(horizontal: 1),
          decoration: BoxDecoration(
            // border: BoxBorder.all(style: selected ? .solid : .dashed),
          ),
          child: InheritedProvider(
            value: Size(width - 2, height - 2),
            child: body,
          ),
        ),
      ],
    );
  }
}

class NavigableScope extends StatefulComponent {
  final Component Function(
    BuildContext context,
    int? selected,
    bool Function(int? index) select,
    int focused,
    bool Function(int index) focus,
  )
  builder;
  final int? initialSelection;
  final int initialFocus;
  final bool unselectOnEscape;

  const NavigableScope({
    required this.builder,
    this.initialSelection,
    this.initialFocus = 0,
    this.unselectOnEscape = false,
    super.key,
  });
  @override
  State<NavigableScope> createState() => _NavigableScopeState();
}

class _NavigableScopeState extends State<NavigableScope> {
  late int? selected = component.initialSelection;
  late int focused = component.initialFocus;

  bool select(int? value) {
    setState(() => selected = value);
    return true;
  }

  bool focus(int value) {
    setState(() => focused = value);
    return true;
  }

  @override
  Component build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      onKeyEvent: (key) => switch (key) {
        .escape => selected == null ? false : select(null),
        _ => false,
      },
      child: component.builder(context, selected, select, focused, focus),
    );
  }
}

extension on Axis {
  Axis get other => switch (this) {
    .horizontal => .vertical,
    .vertical => .horizontal,
  };
}
