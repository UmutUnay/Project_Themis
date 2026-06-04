/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-24 13:30:13
 * @LastEditTime: 2025-12-16 23:02:13
 * @Description: 
 */

import 'package:go_router/go_router.dart';

import '../../feature/config_page/screen/plugins_page.dart';
import '../../feature/settings/screen/settings_screen.dart';

GoRouter getRouter(bool setupDone) => GoRouter(
  initialLocation: setupDone ? "/" : "/settings",
  routes: [
    GoRoute(
      name: "Root",
      path: "/",
      redirect: (_, state) =>
          state.fullPath == "/" ? "/plugins" : state.fullPath,
      routes: [
        GoRoute(
          name: "Settings",
          path: "/settings",
          builder: (context, state) => GuiSettings(),
          routes: [
            GoRoute(
              name: "Account Settings",
              path: "/account",
              builder: (context, state) =>
                  GuiSettings(initialPageId: "account"),
            ),
            GoRoute(
              name: "About Settings",
              path: "/about",
              builder: (context, state) => GuiSettings(initialPageId: "about"),
            ),
          ],
        ),
        GoRoute(
          name: "Plugins",
          path: "/plugins",
          builder: (context, state) => ThemisPluginsPage(),
        ),
      ],
    ),
  ],
);
