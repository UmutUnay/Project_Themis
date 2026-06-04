/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-24 13:50:34
 * @LastEditTime: 2025-11-24 14:48:42
 * @Description: 
 */

import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

class YaruPageItem {
  const YaruPageItem({
    required this.title,
    this.id,
    this.subtitle,
    this.leadingBuilder,
    this.titleBuilder,
    this.actionsBuilder,
    required this.pageBuilder,
    required this.iconBuilder,
    this.floatingActionButtonBuilder,
    this.supportedLayouts = const {YaruMasterDetailPage, YaruNavigationPage},
  });

  final String title;
  final String? id;
  final String? subtitle;
  final WidgetBuilder? leadingBuilder;
  final WidgetBuilder? titleBuilder;
  final List<Widget> Function(BuildContext context)? actionsBuilder;
  final WidgetBuilder pageBuilder;
  final WidgetBuilder? floatingActionButtonBuilder;
  final Widget Function(BuildContext context, bool selected) iconBuilder;
  final Set<Type> supportedLayouts;
}
