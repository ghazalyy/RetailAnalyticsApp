import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:3000/api";
    return "http://10.0.2.2:3000/api";
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setString('user_name', data['user']['name']);
        await prefs.setBool('is_logged_in', true);
        
        return data['user'];
      } else {
        throw Exception(data['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  static Future<List<Product>> fetchProducts({int page = 1, String search = ""}) async {
    final url = Uri.parse('$baseUrl/products?page=$page&limit=20&search=$search');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<bool> addProduct(String name, String category, double price, int stock) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": name,
          "category": category,
          "price": price,
          "stock": stock,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateProduct(String id, String name, String category, double price, int stock) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": name,
          "category": category,
          "price": price,
          "stock": stock,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/products/$id'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> createTransaction(String productId, int qty, double total) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "productId": productId,
          "quantity": qty,
          "totalParam": total, 
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}