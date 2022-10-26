import 'package:analyzer/dart/element/type.dart';

///  @startuml
///
///  node DbUtil
///  node DbService
///
///  node AppBloc
///  node HomeBloc
///  node LoginBloc
///  node NavBloc
///  node RestService
///
///  node BiometricAuthService
///
///  DbService -up->DbUtil
///
///  DbUtil -up->AppBloc
///
///  BiometricAuthService -up->AppBloc
///
///  AppBloc -up-> HomeBloc
///  AppBloc -up-> LoginBloc
///  AppBloc -up-> NavBloc
///  BiometricAuthService -up->NavBloc
///
///  @enduml
String generateUmlFile(Map<String, Iterable<DartType>> serviceInfo) {
  final StringBuffer sb = StringBuffer();

  sb.writeln('@startuml\n');

  // nodes
  for (final String serviceName in serviceInfo.keys) {
    sb.writeln('node $serviceName');
  }

  // relations
  serviceInfo.forEach((String serviceName, Iterable<DartType> fieldList) {
    final Iterable<String> namedFieldList = fieldList.map((DartType e) => e.getDisplayString(withNullability: false));

    for (final String field in namedFieldList) {
      sb.writeln('$field -up-> $serviceName');
    }

    // final String fmt = namedFieldList.join(';');

    // sb
    //   ..write(serviceName)
    //   ..writeln('($fmt)');
  });

  sb.writeln('\n@enduml');

  return sb.toString();
}
