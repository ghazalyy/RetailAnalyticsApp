import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product_model.dart';

class ApiService {
  static const String _baseUrl =
      'https://retail-analytics-app-ghazalys-projects-cf68bf23.vercel.app/api';

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token'] ?? '');
        await prefs.setString('user_role', data['user']['role'] ?? 'staff');
        await prefs.setString('user_name', data['user']['name'] ?? 'User');
        await prefs.setBool('is_logged_in', true);
        return data['user'];
      } else {
        throw Exception(data['error'] ?? 'Login gagal');
      }
    } else {
      throw Exception('Server error (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> fetchDashboard() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Gagal memuat dashboard');
    }
  }

  static Future<void> downloadReport() async {
    final url = Uri.parse('$_baseUrl/reports/monthly');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<List<Product>> fetchProducts({
    int page = 1,
    String search = '',
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/products?page=$page&limit=20&search=$search',
      ),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat produk');
    }
  }

  static Future<bool> addProduct(
    String name,
    String category,
    double price,
    int stock,
    File? image,
  ) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/products'));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    request.fields['category'] = category;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();

    if (image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', image.path));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  static Future<bool> updateProduct(
    String id,
    String name,
    String category,
    double price,
    int stock,
    File? image,
  ) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$_baseUrl/products/$id'),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    request.fields['category'] = category;
    request.fields['price'] = price.toString();
    request.fields['stock'] = stock.toString();

    if (image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('image', image.path));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  static Future<bool> deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$id'),
      headers: await _headers(),
    );
    return response.statusCode == 200;
  }

  static Future<bool> createBulkTransaction(
    List<Map<String, dynamic>> items,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: await _headers(),
      body: jsonEncode({'items': items}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> createTransaction(
    String productId,
    int qty,
    double total,
  ) async {
    return createBulkTransaction([
      {
        'productId': productId,
        'quantity': qty,
        'price': total / qty,
      }
    ]);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
