import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'entities.dart';

class IsarGraphAnalyzer {
  Future<CollectionGraph> analyze(String rootDirectory) async {
    final graph = CollectionGraph();

    final collection = AnalysisContextCollection(
      includedPaths: [rootDirectory],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    _verifyRootDirectoryExists(rootDirectory);

    for (final context in collection.contexts) {
      // stdout.writeln('Analyzing ${context.contextRoot.root.path}');

      for (final filePath in context.contextRoot.analyzedFiles()) {
        if (!filePath.endsWith('.dart')) {
          continue;
        }
        // stdout.writeln('Analyzing $filePath');

        final unit = await context.currentSession.getResolvedLibrary(filePath);
        if (unit is! ResolvedLibraryResult) continue;

        final isarObjects = unit.element.topLevelElements
            .whereType<ClassElement>()
            .where((e) => e.metadata.any((m) =>
                _matchCollectionAnnotation(m) || _matchEmbeddedAnnotation(m)))
            .map((e) => _parseIsarObject(e));

        for (final node in isarObjects) {
          graph.appendIfAbsent(node);
        }
      }
    }

    graph.updateRef();
    return graph;
  }

  ///
  /// Throws an exception if the directory doesn't exist
  ///
  bool _verifyRootDirectoryExists(String rootDirectory) {
    if (!Directory(rootDirectory).existsSync()) {
      throw FileSystemException(
        'Requested scanning target directory does not exist $rootDirectory',
      );
    }
    return true;
  }

  bool _matchCollectionAnnotation(ElementAnnotation annotation) =>
      annotation.element?.displayName.toLowerCase().startsWith('collection') ??
      false;

  bool _matchEmbeddedAnnotation(ElementAnnotation annotation) =>
      annotation.element?.displayName.toLowerCase().startsWith('embedded') ??
      false;

  CollectionType _parseCollectionType(List<ElementAnnotation> metadata) {
    final isCollection = metadata.any((m) => _matchCollectionAnnotation(m));
    final isEmbedded = metadata.any((m) => _matchEmbeddedAnnotation(m));
    if (isCollection) {
      return CollectionType.collection;
    } else if (isEmbedded) {
      return CollectionType.embedded;
    } else {
      throw Exception('Unknown collection type: ${metadata.join(',')}');
    }
  }

  CollectionNode _parseIsarObject(ClassElement classElement) {
    final fields = classElement.fields
        .map((e) => CollectionNodeField(
              name: e.name,
              type: e.type.getDisplayString(withNullability: false),
              isIndexed:
                  e.metadata.any((m) => m.element?.displayName == 'Index'),
              isEnumerated:
                  e.metadata.any((m) => m.element?.displayName == 'Enumerated'),
              isIsarLink: e.type
                  .getDisplayString(withNullability: false)
                  .startsWith('IsarLink'),
            ))
        .toList();

    return CollectionNode(
      name: classElement.name,
      description:
          _formatDocumentation(classElement.documentationComment ?? ''),
      collectionType: _parseCollectionType(classElement.metadata),
      fields: fields,
    );
  }

  String _formatDocumentation(String documentation) {
    return documentation
        .split('\n')
        .map((e) => e.replaceFirst(RegExp(r'^/// *'), ''))
        .join('\\n')
        .trimRight();
  }
}
