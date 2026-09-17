import 'package:flutter/material.dart';

import '../../repositories/app_repository.dart';
import '../../services/firebase_error_message.dart';
import '../extensions/context_extensions.dart';

/// Keep forms open on failed writes and consume asynchronous SDK exceptions.
Future<bool> runRepositoryAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      context.showSnackBar(
        error is RepositoryException
            ? error.message
            : firebaseErrorMessage(error),
        isError: true,
      );
    }
    return false;
  }
}
