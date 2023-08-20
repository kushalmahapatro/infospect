part of 'desktop_theme_cubit.dart';

sealed class DesktopThemeState extends Equatable {
  const DesktopThemeState({required this.isDarkTheme});

  final bool isDarkTheme;

  @override
  List<Object> get props => [isDarkTheme];
}

final class DarkDesktopTheme extends DesktopThemeState {
  const DarkDesktopTheme({super.isDarkTheme = true});
}

final class LightDesktopTheme extends DesktopThemeState {
  const LightDesktopTheme({super.isDarkTheme = false});
}
