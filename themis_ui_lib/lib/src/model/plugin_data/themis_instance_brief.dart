/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2026-03-08 11:53:40
 * @LastEditTime: 2026-03-08 11:53:41
 * @Description: 
 */
/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2026-03-08 07:20:22
 * @LastEditTime: 2026-03-08 07:29:21
 * @Description: 
 */

import 'package:equatable/equatable.dart';

/// Brief textual information about the plugin.
class ThemisInstanceBrief extends Equatable {
  /// Plugin identifier.
  final String instanceId;

  /// Title to display on the main tab.
  final String name;

  /// Subtitle to display on the main tab.
  final String notes;

  /// Index of the group the instance belongs to.
  /// Used for positioning in ui.
  final int? groupNumber;

  /// XY position of the instance in the group.
  /// Used for positioning in ui.
  /// Must be unique in group (except null).
  final (int, int)? position;

  const ThemisInstanceBrief({
    required this.instanceId,
    required this.name,
    this.notes = "",
    this.groupNumber,
    this.position,
  });

  @override
  List<Object?> get props => [instanceId, name, notes, groupNumber, position];
}
