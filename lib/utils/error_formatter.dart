import 'dart:developer';

String? formatGraphqlError(dynamic exception) {
  log('result exception ${exception.toString()}');

  try {
    final String str = exception.graphqlErrors.map((e) => e.message).join('\n');

    if (str.isEmpty) {
      try {
        //Sometimes we get response and errors together
        final String serverError = exception.linkException.parsedResponse.errors
            .map((e) => e.message)
            .join('\n');

        if (serverError.isNotEmpty) {
          log('serverError: $serverError');
          //Because we have response
          return null;
        }
      } catch (_) {}
    }

    if (str.isEmpty) {
      throw exception;
    }

    return str;
  } catch (e) {
    log('Error to be formatter exception: ${e.toString()}');
    //If we can't extract messages above then it could be internet error.
    return 'Please make sure you are connected to the internet and try again';
  }
}
