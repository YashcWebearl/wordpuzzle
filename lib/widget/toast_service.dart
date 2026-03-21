import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastService {
  static final FToast _fToast = FToast();
  static bool _isInitialized = false;

  // Initialize once from root
  static void init(BuildContext context) {
    _fToast.init(context);
    _isInitialized = true;
  }

  // 🔥 Normal Toast
  static void show(String message) {
    if (!_isInitialized) {
      debugPrint("❌ Toast not initialized yet");
      return;
    }

    _fToast.showToast(
      child: _toastUI(message),
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }

  // 🔥 Success Toast
  static void success(String message) {
    if (!_isInitialized) return;

    _fToast.showToast(
      child: _toastUI(message, color: Colors.green),
      gravity: ToastGravity.BOTTOM,
    );
  }

  // 🔥 Error Toast
  static void error(String message) {
    if (!_isInitialized) return;

    _fToast.showToast(
      child: _toastUI(message, color: Colors.red),
      gravity: ToastGravity.BOTTOM,
    );
  }

  // 🎨 UI Design
  static Widget _toastUI(String message, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icon/icon.png',
            width: 22,
            height: 22,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}