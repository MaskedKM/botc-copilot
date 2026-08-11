import 'package:botc_copilot/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App 入口：Riverpod 作用域 + 根 Widget。
void main() {
  runApp(const ProviderScope(child: BotcApp()));
}
