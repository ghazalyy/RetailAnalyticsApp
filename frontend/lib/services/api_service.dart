import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';

class ApiService {
  static String get baseUrl {
    return "https://retail-analytics-app-ghazalys-projects-cf68bf23.vercel.app/api";
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
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
        
        await prefs.setString('auth_token', data['token'] ?? "");
        await prefs.setString('user_role', data['user']['role'] ?? "staff");
        await prefs.setString('user_name', data['user']['name'] ?? "User");
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
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  static Future<void> downloadReport() async {
    final url = Uri.parse('$baseUrl/reports/monthly');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<List<Product>> fetchProducts({int page = 1, String search = ""}) async {
    final url = Uri.parse('$baseUrl/products?page=$page&limit=20&search=$search');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<bool> addProduct(String name, String category, double price, int stock, File? image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
      final headers = await _getHeaders();
      request.headers['Authorization'] = headers['Authorization']!;

      request.fields['name'] = name;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateProduct(String id, String name, String category, double price, int stock, File? image) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/products/$id'));
      final headers = await _getHeaders();
      request.headers['Authorization'] = headers['Authorization']!;

      request.fields['name'] = name;
      request.fields['category'] = category;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> createBulkTransaction(List<Map<String, dynamic>> items) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
        body: json.encode({"items": items}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> createTransaction(String productId, int qty, double total) async {
    return createBulkTransaction([
      {
        "productId": productId,
        "quantity": qty,
        "price": (total / qty),
      }
    ]);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}