class CollectionGraph {
  final Map<String, CollectionNode> collections = {};

  final genericsTypeMatcher = RegExp(r'<.*>');

  void appendIfAbsent(CollectionNode collectionNode) {
    if (!collections.containsKey(collectionNode.name)) {
      collections[collectionNode.name] = collectionNode;
    }
  }

  void updateRef() {
    for (final node in collections.values) {
      for (final field in node.fields) {
        if (collections.containsKey(field.type)) {
          field.typeRef = collections[field.type];
        } else if (field.type.startsWith('IsarLink') &&
            field.type.contains(genericsTypeMatcher)) {
          final match = genericsTypeMatcher.firstMatch(field.type);
          if (match != null) {
            final type = field.type.substring(match.start + 1, match.end - 1);
            if (collections.containsKey(type)) {
              field.typeRef = collections[type];
            }
          }
        }
      }
    }
  }
}

enum CollectionType {
  collection,
  embedded,
}

class CollectionNode {
  CollectionNode({
    required this.name,
    required this.description,
    required this.collectionType,
    required this.fields,
  });

  final String name;
  final String description;
  final CollectionType collectionType;
  final List<CollectionNodeField> fields;

  @override
  String toString() {
    return 'CollectionNode{name: $name, '
        'collectionType: $collectionType, fields: $fields}';
  }
}

class CollectionNodeField {
  CollectionNodeField({
    required this.name,
    required this.type,
    required this.isIndexed,
    required this.isEnumerated,
    required this.isIsarLink,
    this.typeRef,
  });

  final String name;
  final String type;
  final bool isIndexed;
  final bool isEnumerated;
  final bool isIsarLink;
  CollectionNode? typeRef;

  @override
  String toString() {
    return 'CollectionNodeField{name: $name, type: $type, isIndexed: $isIndexed, '
        'isEnumerated: $isEnumerated}, typeRef: ${typeRef?.name}}';
  }
}
