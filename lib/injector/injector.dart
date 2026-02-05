import 'package:injectable/injectable.dart';

import 'package:get_it/get_it.dart';

import 'injector.config.dart';

final injector = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
void configureDependencies() => init(injector);
