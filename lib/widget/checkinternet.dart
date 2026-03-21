import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:word_puzzle/widget/toast_service.dart';

Future<void> checkInternetAndProceed(BuildContext context, VoidCallback onOnline) async {
  final connectivityResults = await Connectivity().checkConnectivity();

  if (connectivityResults.contains(ConnectivityResult.none)) {
    // ❌ User is offline
    // ToastService.show("You're offline bro");
    Fluttertoast.showToast(msg: "You're offline");
  } else {
    // ✅ User is online — proceed
    onOnline();
  }
}
