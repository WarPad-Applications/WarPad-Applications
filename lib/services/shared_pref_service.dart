import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SharedPrefService extends GetxService {
  late SharedPreferences _prefs;
  final isDarkMode = false.obs;

  Future<SharedPrefService> init() async {
    _prefs = await SharedPreferences.getInstance();
    isDarkMode.value = _prefs.getBool('isDarkMode') ?? false;
    ever(isDarkMode, (_) => _applyTheme());
    return this;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _prefs.setBool('isDarkMode', isDarkMode.value);
  }

  void setTheme(bool v) {
    isDarkMode.value = v;
    _prefs.setBool('isDarkMode', v);
  }

  void _applyTheme() {
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}
