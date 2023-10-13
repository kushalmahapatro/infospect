import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'desktop_theme_state.dart';

/// `DesktopThemeCubit` manages the theme state for a desktop application.
/// It is responsible for handling theme-related actions and updating the state accordingly.
class DesktopThemeCubit extends Cubit<DesktopThemeState> {
  /// Constructor initializes the `DesktopThemeCubit` with a default dark theme.
  DesktopThemeCubit() : super(const DarkDesktopTheme());

  /// Sets the theme state based on the provided value.
  ///
  /// - `isDark`: A boolean indicating whether the theme should be set to dark or not.
  /// If `true`, it sets the theme to dark, otherwise it sets to light.
  void setTheme(bool isDark) {
    if (isDark) {
      emit(const DarkDesktopTheme());
    } else {
      emit(const LightDesktopTheme());
    }
  }
}
