import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'desktop_theme_state.dart';

class DesktopThemeCubit extends Cubit<DesktopThemeState> {
  DesktopThemeCubit() : super(const DarkDesktopTheme());

  void setTheme(bool isDark) {
    if (isDark) {
      emit(const DarkDesktopTheme());
    } else {
      emit(const LightDesktopTheme());
    }
  }
}
