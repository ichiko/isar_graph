import 'dart:io';

import 'package:args/args.dart';
import 'package:isar_graph/src/analyzer.dart';
import 'package:isar_graph/src/writer.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  final parser = ArgParser();
  parser
    ..addFlag('showAllFields', abbr: 'a', defaultsTo: false)
    ..addFlag('showEmbeddedObjects', abbr: 'e', defaultsTo: false);

  final parsedArgs = parser.parse(args);
  final rootDirectory = parsedArgs.arguments.isNotEmpty
      ? path.normalize(path.absolute(parsedArgs.arguments.first))
      : Directory.current.absolute.path;

  final options = WriterOptions(
    showAllFields: parsedArgs['showAllFields'],
    showEmbeddedObjects:
        parsedArgs['showAllFields'] || parsedArgs['showEmbeddedObjects'],
  );

  final analyzer = IsarGraphAnalyzer();
  final graph = await analyzer.analyze(rootDirectory);
  final writer = MermaidWriter(stdout, options: options);
  writer.writeln(graph);
}
