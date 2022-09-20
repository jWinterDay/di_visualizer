import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:di_visualizer/di_visualizer_cli.dart';

Future<void> main(List<String> args) async {
  try {
    final CommandRunner<void> runner = CommandRunner<void>(
      'di_visualizer_cli',
      'di visualizer cli',
    )..addCommand(BuildDependenciesCommand());

    await runner.run(args);
  } on UsageException catch (exc) {
    stderr.writeln('$exc');
    exit(64);
  } on Exception catch (exc) {
    stderr.writeln('Uunexpected error: $exc');
    exit(1);
  }
}
