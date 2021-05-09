import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shopapp/models/http_exception.dart';
import 'package:shopapp/providers/product.dart';
import 'package:http/http.dart' as http;

class Products with ChangeNotifier {
  List<Product> _items = [];

  //var _showFavoritesOnly = false;

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  List<Product> get items {
    // if (_showFavoritesOnly) {
    // return _items.where((i) => i.isFavorite).toList();
    //}
    return [..._items];
  }

  Product findById(String id) {
    return _items.firstWhere((element) => element.id == id);
  }

  Future<void> addProduct(Product product) async {
    const url =
        'https://shop-app-c386f-default-rtdb.europe-west1.firebasedatabase.app/products.json';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'isFavorite': product.isFavorite,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((element) => element.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://shop-app-c386f-default-rtdb.europe-west1.firebasedatabase.app/products/$id.json';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          }));
      _items[prodIndex] = newProduct;
    } else {
      //  never happens in this app.
    }
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://shop-app-c386f-default-rtdb.europe-west1.firebasedatabase.app/products/$id.json';
    final existingProductIndex =
        _items.indexWhere((element) => element.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    // optimistic updating -> rollback if delete fails
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      throw HttpException('Could not delete product.');
    } else {
      existingProduct = null;
    }
  }

  Future<void> fetchAndSetProducts() async {
    const url =
        'https://shop-app-c386f-default-rtdb.europe-west1.firebasedatabase.app/products.json';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      final List<Product> loadedProducts = [];
      extractedData.forEach((productId, productData) {
        loadedProducts.add(Product(
          id: productId,
          title: productData['title'],
          description: productData['description'],
          price: productData['price'],
          imageUrl: productData['imageUrl'],
          isFavorite: productData['isFavorite'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }
  //void showFavoritesOnly() {
  // _showFavoritesOnly = true;
  // notifyListeners();
  //}

  //void showAll() {
  //_showFavoritesOnly = false;
  //notifyListeners();
  // }
}
