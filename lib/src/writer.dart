import 'dart:io';

import 'entities.dart';

class WriterOptions {
  const WriterOptions({
    this.showAllFields = true,
    this.showEmbeddedObjects = true,
  });
  final bool showAllFields;
  final bool showEmbeddedObjects;
}

class MermaidWriter {
  MermaidWriter(this.io, {this.options = const WriterOptions()});

  final IOSink io;
  final WriterOptions options;

  void writeln(CollectionGraph graph) {
    io.writeln('```mermaid');
    io.writeln('classDiagram');
    for (final node in graph.collections.values) {
      _writeClass(node);
    }
    for (final node in graph.collections.values) {
      _writeRef(node);
    }
    io.writeln('```');
  }

  void _writeClass(CollectionNode node) {
    if (!options.showEmbeddedObjects &&
        node.collectionType == CollectionType.embedded) {
      return;
    }

    io.write('  class ${node.name}');
    io.writeln('{');
    io.writeln('    <<${node.collectionType.name}>>');
    for (final field in node.fields) {
      if (options.showAllFields ||
          field.isIndexed ||
          field.typeRef != null &&
              (options.showEmbeddedObjects ||
                  field.typeRef!.collectionType == CollectionType.collection)) {
        io.writeln('    ${_normalize(field.type)} ${field.name}'
            '${field.isIndexed ? '~index~' : ''} '
            '${field.isEnumerated ? '~enum~' : ''}');
      }
    }
    io.writeln('  }');

    if (node.description.isNotEmpty) {
      io.writeln('  note for ${node.name} "${node.description}"');
    }
  }

  void _writeRef(CollectionNode node) {
    for (final field in node.fields) {
      if (field.typeRef != null &&
          (options.showEmbeddedObjects ||
              field.typeRef!.collectionType == CollectionType.collection)) {
        io.writeln('  ${node.name} --> ${field.typeRef!.name} : ${field.name}');
      }
    }
  }

  String _normalize(String string) {
    return string.replaceAll(RegExp(r'[<>]'), '~');
  }
}
