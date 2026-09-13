import '../network/dio_client.dart';

class ApiClient {
  static dynamic _data(dynamic body) =>
      body is Map && body.containsKey('data') ? body['data'] : body;
  static Future<dynamic> get(String endpoint) async =>
      _data((await dioClient.get(endpoint)).data);
  static Future<dynamic> post(
          String endpoint, Map<String, dynamic> body) async =>
      _data((await dioClient.post(endpoint, data: body)).data);
  static Future<dynamic> put(
          String endpoint, Map<String, dynamic> body) async =>
      _data((await dioClient.put(endpoint, data: body)).data);
  static Future<dynamic> delete(String endpoint) async =>
      _data((await dioClient.delete(endpoint)).data);
}
