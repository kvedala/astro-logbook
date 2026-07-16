import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ErrorHandler {
  static void handleError(dynamic error, {String? context}) {
    String message = 'An error occurred';

    if (error is FirebaseException) {
      message = _getFirebaseErrorMessage(error);
    } else if (error is PlatformException) {
      message = error.message ?? 'Platform error occurred';
    }

    // Log error
    FirebaseCrashlytics.instance.recordError(
      error,
      StackTrace.current,
      reason: context,
    );

    // Show user-friendly message
    Get.snackbar('Error', message, backgroundColor: Colors.red);
  }

  static String _getFirebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return error.message ?? 'Firebase error occurred';
    }
  }
}
