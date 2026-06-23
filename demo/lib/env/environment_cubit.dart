import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'environment_state.dart';

class EnvironmentCubit extends Cubit<EnvironmentState> {
  EnvironmentCubit()
      : super(const EnvironmentState(
          domain: '',
          clientId: '',
          redirectUri: '',
          apiToken: '',
        ));

  void load() {
    emit(EnvironmentState(
      domain: dotenv.env['OKTA_DOMAIN'] ?? '',
      clientId: dotenv.env['OKTA_CLIENT_ID'] ?? '',
      redirectUri: dotenv.env['OKTA_REDIRECT_URI'] ?? '',
      apiToken: dotenv.env['OKTA_API_TOKEN'] ?? '',
    ));
  }
}
