import '../../domain/entities/catalog_item.dart';

class CatalogItemModel extends CatalogItem {
  CatalogItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.description,
    super.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory CatalogItemModel.fromMap(Map<String, dynamic> map, String id) {
    return CatalogItemModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
