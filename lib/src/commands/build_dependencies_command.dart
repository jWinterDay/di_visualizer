import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:args/command_runner.dart';
import 'package:di_visualizer/di_visualizer_cli.dart';
import 'package:di_visualizer_annotation/di_visualizer_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

class BuildDependenciesCommand extends Command<void> {
  BuildDependenciesCommand() {
    argParser
      ..addOption(
        'directory',
        abbr: 'd',
        help: 'source directory',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'output directory path',
      );
  }

  @override
  String get description => 'di visualizer cli';

  @override
  String get name => 'di';

  @override
  String get invocation => '${runner?.executableName} $name [arguments] <directories>';

  static const List<String> _excludedExtensions = <String>[
    '.g.dart',
    '.freezed.dart',
    'l10n.dart',
    'messages_all.dart',
    'messages_en.dart',
    'messages_ru.dart',
  ];

  @override
  Future<void> run() async {
    Utils.printGreen('$name generator');

    // source directory
    final String? dir = argResults?['directory'] as String?;
    if (dir == null) {
      throw UsageException(
        'Source directory path doesn"t exist',
        'Use correct source directory file path',
      );
    }
    final String rootFolder = Directory.current.path;
    final String absDirPath = p.normalize(p.join(rootFolder, dir));
    final Set<String> filePaths = FileUtil.getDartFilesFromFolders(
      <String>[absDirPath],
      rootFolder,
      excludedExtensions: _excludedExtensions,
    );

    // output path
    if (argResults?['output'] == null) {
      throw UsageException('Output file path doesn"t exist', 'Use correct output file path');
    }
    final String outputPath = argResults?['output'] as String;
    final String absOutputPath = p.join(Directory.current.path, outputPath);
    final File outputFile = File(absOutputPath);
    final bool outputExists = outputFile.existsSync();
    if (!outputExists) {
      outputFile.createSync();
    }

    Utils.printCyan('input dir: $absDirPath, output file: $absOutputPath');

    // generate and write to file
    final Map<String, Iterable<DartType>> genMap = await _generate(filePaths: filePaths);
    final String text = _generateText(genMap);
    outputFile.writeAsStringSync(text);
  }

  Future<Map<String, Iterable<DartType>>> _generate({required Set<String> filePaths}) async {
    final Map<String, Iterable<DartType>> serviceInfo = <String, Iterable<DartType>>{};

    final AnalysisContextCollection analysisContext = AnalysisContextCollection(
      includedPaths: filePaths.toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    final Iterable<AnalysisContext> singleContextList = analysisContext.contexts.take(1);

    for (final AnalysisContext analysisContext in singleContextList) {
      for (final String path in filePaths) {
        final SomeResolvedUnitResult unit = await analysisContext.currentSession.getResolvedUnit(path);

        if (unit is! ResolvedUnitResult) {
          continue;
        }

        final LibraryElement library = unit.libraryElement;

        final Iterable<List<ClassElement>> classList = library.units.map((CompilationUnitElement e) => e.classes);

        for (final List<ClassElement> cl in classList) {
          for (final ClassElement c in cl) {
            final Set<DartType> fieldsInfoList = <DartType>{};
            final String serviceName = c.name;

            final DartObject? serviceAnnotation = const TypeChecker.fromRuntime(DIService).firstAnnotationOf(c);

            if (serviceAnnotation != null) {
              for (final FieldElement f in c.fields) {
                final DartType fType = f.type;
                fieldsInfoList.add(fType);
                // final DartObject? injectAnnotation = const TypeChecker.fromRuntime(DIInject).firstAnnotationOf(f);

                // if (injectAnnotation != null) {
                //   final DartType fType = f.type;

                //   fieldsInfoList.add(fType);
                // }
              }

              final Iterable<String> namedFieldList = fieldsInfoList.map((DartType e) {
                return e.getDisplayString(withNullability: false);
              });
              final String namedFieldStr = namedFieldList.join('; ');
              Utils.printYellow('$serviceName: ($namedFieldStr)');

              serviceInfo[serviceName] = fieldsInfoList;
            }
          }
        }
      }
    }

    return serviceInfo;
  }

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
  String _generateText(Map<String, Iterable<DartType>> serviceInfo) {
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
}
