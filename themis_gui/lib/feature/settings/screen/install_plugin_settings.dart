/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-24 13:45:41
 * @LastEditTime: 2026-03-08 09:18:47
 * @Description: 
 */

import 'package:flutter/material.dart';

import '../widgets/connection.dart';
import '../widgets/login.dart';
import '../widgets/select_plugin_file.dart';

/// Settings page for client connection.
class InstallPluginSettings extends StatelessWidget {
  const InstallPluginSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10000,
      child: SingleChildScrollView(
        child: Wrap(
          direction: .horizontal,
          alignment: .center,
          crossAxisAlignment: .center,
          children: [SelectPluginFile()],
        ),
      ),
    );
  }
}
