import 'dart:convert';
import 'package:locator/Data/user_details.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse(
        'https://www.jsonkeeper.com/b/HHPD'));
    print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((user) => User.fromJson(user)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

}