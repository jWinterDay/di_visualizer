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
import 'package:di_visualizer/src/commands/html_generator.dart';
import 'package:di_visualizer_annotation/di_visualizer_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'uml_generator.dart';

const String _kUmlFormat = 'uml';
const String _kHtmlFormat = 'html';
const Set<String> _kFormatList = <String>{_kUmlFormat, _kHtmlFormat};

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
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: 'output file format',
        allowed: _kFormatList,
        defaultsTo: _kUmlFormat,
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

    // format
    final String format = argResults?['format'] as String;

    Utils.printCyan('$format. input dir: $absDirPath, output file: $absOutputPath');

    // generate and write to file
    final Map<String, Iterable<DartType>> genMap = await _generate(filePaths: filePaths);

    late String text;

    switch (format) {
      case _kUmlFormat:
        text = generateUmlFile(genMap);
        break;

      case _kHtmlFormat:
        text = generateHtmlFile(genMap);
        break;

      default:
        final String fmts = _kFormatList.join('; ');

        throw UsageException(
          'Unknown output format',
          'Use one of those formats: $fmts',
        );
    }

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
              final Iterable<ConstructorElement> cnstrList = c.constructors.where((ConstructorElement cnsrt) {
                return cnsrt.isPublic;
              });

              if (cnstrList.length != 1) {
                throw UsageException('Service must contain only one class', 'Service must contain only one class');
              }

              final ConstructorElement singleConstr = cnstrList.first;

              for (final ParameterElement param in singleConstr.parameters) {
                fieldsInfoList.add(param.type);
                // print('${singleConstr.displayName}   ${param.type.getDisplayString(withNullability: false)}');
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
}
