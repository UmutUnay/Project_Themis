import 'dart:math';

import 'package:nocterm/nocterm.dart';

import 'provider.dart';
import 'scaffold.dart';

/// Double pane layout with size propogation.
class DoublePanePage extends StatelessComponent {
  /// Ratio of the left pane to the whole.
  final double leftPaneRatio;

  /// Max width of the left pane.
  final double maxLeftPaneWidth;

  /// Left pane.
  final Pane leftPane;

  /// Right pane.
  final Pane rightPane;

  DoublePanePage({
    required this.leftPaneRatio,
    required this.maxLeftPaneWidth,
    required this.leftPane,
    required this.rightPane,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final size = InheritedProvider.of<Size>(context)!;
    final pageTitle = InheritedProvider.of<PageTitle>(context, listen: false)!;
    var leftPaneWidth = min(size.width * leftPaneRatio, maxLeftPaneWidth);
    var rightPaneWidth = size.width - leftPaneWidth;
    leftPaneWidth -= 2;
    rightPaneWidth -= 2;
    var paneHeight = size.height - 3;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: BoxBorder(bottom: BorderSide(style: .solid)),
          ),
          child: Row(
            mainAxisSize: .max,
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                pageTitle.title,
                style: TextStyle(
                  color: TuiTheme.of(context).primary,
                  fontWeight: .bold,
                ),
              ),
              Text(
                pageTitle.helpWidth(context) > 48
                    ? "🠜🠞🠝🠟 to navigate|⮐ to enter|␛ to exit|q to quit"
                    : "h to help",
                style: TextStyle(color: TuiTheme.of(context).secondary),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: .spaceEvenly,
          children: [
            leftPane.buildPane(context, leftPaneWidth, paneHeight),
            rightPane.buildPane(context, rightPaneWidth, paneHeight),
          ],
        ),
      ],
    );
  }
}

class Pane {
  final String? title;
  final Component body;
  final bool selected;

  Pane({this.title, required this.body, this.selected = false});

  Component buildPane(BuildContext context, [double? width, double? height]) {
    return Container(
      constraints: BoxConstraints(
        minWidth: width == null ? 0 : width * 0.5,
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      ),
      padding: .symmetric(horizontal: 1),
      margin: .symmetric(horizontal: 1),
      decoration: BoxDecoration(
        border: BoxBorder.all(style: selected ? .solid : .dashed),
        title: title == null
            ? null
            : BorderTitle(
                text: title!,
                alignment: .center,
                style: TextStyle(color: TuiTheme.of(context).outlineVariant),
              ),
      ),
      child: width == null || height == null
          ? body
          : InheritedProvider(value: Size(width - 2, height - 2), child: body),
    );
  }
}
