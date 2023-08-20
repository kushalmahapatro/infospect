part of 'desktop_theme_cubit.dart';

/// A `sealed class` (in other languages) or abstract class in Dart representing different theme states
/// for a desktop application. This class makes it easy to distinguish between dark and light themes.
abstract class DesktopThemeState extends Equatable {
  /// Constructs a `DesktopThemeState` with the provided theme information.
  ///
  /// - `isDarkTheme`: A boolean value indicating whether the theme is dark.
  const DesktopThemeState({required this.isDarkTheme});

  final bool isDarkTheme;

  @override
  List<Object> get props => [isDarkTheme];
}

/// Represents the dark theme state.
///
/// This class extends `DesktopThemeState` and sets `isDarkTheme` to `true`.
final class DarkDesktopTheme extends DesktopThemeState {
  const DarkDesktopTheme({super.isDarkTheme = true});
}

/// Represents the light theme state.
///
/// This class extends `DesktopThemeState` and sets `isDarkTheme` to `false`.
final class LightDesktopTheme extends DesktopThemeState {
  const LightDesktopTheme({super.isDarkTheme = false});
}
