/*
 * @Author: TUNA DEMIRDOGEN
 * @Date: 2025-11-07 20:36:07
 * @LastEditTime: 2025-12-18 00:55:43
 * @Description: 
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';

import 'core/misc/hydrated_encryption.dart';
import 'core/misc/router.dart';
import 'core/misc/theme_transform.dart';
import 'feature/settings/cubit/settings_data.dart';

Future<void> main() async {
  await YaruWindowTitleBar.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  GoRouter.optionURLReflectsImperativeAPIs = true;

  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(minimumSize: Size(500, 600));
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationSupportDirectory()).path,
          ),
    encryptionCipher: await getHydratedStorageCypher(),
  );
  final settings = SavedSettingsCubit();
  await settings.initDone;

  runApp(
    BlocProvider.value(
      value: settings,
      child: ThemisGui(getRouter(settings.state.clientData.type != .none)),
    ),
  );
}

class ThemisGui extends StatelessWidget {
  final GoRouter router;
  const ThemisGui(this.router, {super.key});
  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      data: YaruThemeData(variant: YaruVariant.viridian),
      builder: (context, yaru, child) => ColoredBox(
        color: (yaru.themeMode == ThemeMode.light ? yaru.theme : yaru.darkTheme)
            .canvasColor,
        child: MaterialApp.router(
          title: 'Themis',
          debugShowCheckedModeBanner: false,
          theme: transformTheme(yaru.theme),
          themeMode: ThemeMode.system,
          darkTheme: transformTheme(yaru.darkTheme),
          highContrastTheme: yaruHighContrastLight,
          highContrastDarkTheme: yaruHighContrastDark,
          routerConfig: router,
        ),
      ),
    );
  }
}
