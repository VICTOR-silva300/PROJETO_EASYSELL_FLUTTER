import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  static String? token;
  static String? userId;
  static String? companyId;
  static Map<String, dynamic>? usuario;

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static dynamic _json(http.Response response) {
    dynamic body;

    try {
      if (response.body.isEmpty) {
        body = null;
      } else {
        body = jsonDecode(response.body);
      }
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Erro ${response.statusCode} na API.';

      if (body is Map && body['message'] != null) {
        final value = body['message'];

        if (value is List) {
          message = value.join('\n');
        } else {
          message = value.toString();
        }
      }

      throw Exception(message);
    }

    return body;
  }

  static Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  static List<Map<String, dynamic>> _list(dynamic data) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = _map(_json(response));

    token = data['accessToken']?.toString();
    userId = data['sub']?.toString();
    companyId = data['empresaId']?.toString();

    usuario = Map<String, dynamic>.from(data);

    if (companyId == null && userId != null) {
      final company = await bootstrapCompany(
        userId!,
        data['name']?.toString() ?? 'Minha Empresa',
      );

      companyId = company['_id']?.toString();

      usuario = {
        ...?usuario,
        'empresaId': companyId,
      };
    }

    return data;
  }

  static Future<Map<String, dynamic>> me() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );

    final data = _map(_json(response));

    usuario = {
      ...?usuario,
      ...data,
    };

    userId =
        data['userId']?.toString() ??
        data['_id']?.toString() ??
        data['sub']?.toString() ??
        userId;

    companyId =
        data['empresaId']?.toString() ??
        data['companyId']?.toString() ??
        data['company']?.toString() ??
        companyId;

    return data;
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': 'administrador',
      }),
    );

    final data = _map(_json(response));

    final id = data['_id']?.toString();

    if (id != null && id.isNotEmpty) {
      await bootstrapCompany(id, name);
    }

    return data;
  }

  static Future<Map<String, dynamic>> bootstrapCompany(
    String id,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/company/bootstrap/$id'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
      }),
    );

    final data = _map(_json(response));

    companyId = data['_id']?.toString();

    if (token != null &&
        token!.isNotEmpty &&
        id == userId &&
        companyId != null) {
      try {
        final updateResponse = await http.patch(
          Uri.parse('$baseUrl/user/$id'),
          headers: _headers,
          body: jsonEncode({
            'company': companyId,
          }),
        );

        if (updateResponse.statusCode >= 200 &&
            updateResponse.statusCode < 300) {
          final updatedUser = _map(_json(updateResponse));

          usuario = {
            ...?usuario,
            ...updatedUser,
            'empresaId': companyId,
          };
        }
      } catch (_) {}
    }

    return data;
  }

  static Future<Map<String, dynamic>> atualizarUsuario({
    String? nome,
    String? email,
  }) async {
    final id = userId;

    if (id == null || id.isEmpty) {
      throw Exception('Usuário não identificado.');
    }

    final body = <String, dynamic>{};

    if (nome != null && nome.trim().isNotEmpty) {
      body['name'] = nome.trim();
    }

    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }

    if (body.isEmpty) {
      return usuario ?? {};
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/user/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = _map(_json(response));

    usuario = {
      ...?usuario,
      ...data,
    };

    if (nome != null && nome.trim().isNotEmpty) {
      usuario!['name'] = nome.trim();
    }

    if (email != null && email.trim().isNotEmpty) {
      usuario!['email'] = email.trim();
    }

    return usuario ?? data;
  }

  static Future<Map<String, dynamic>> getEmpresa(
    String id,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/company/$id'),
      headers: _headers,
    );

    return _map(_json(response));
  }

  static Future<Map<String, dynamic>> atualizarEmpresa({
    String? nome,
  }) async {
    final id = companyId;

    if (id == null || id.isEmpty) {
      throw Exception('Empresa não identificada.');
    }

    final body = <String, dynamic>{};

    if (nome != null && nome.trim().isNotEmpty) {
      body['name'] = nome.trim();
    }

    if (body.isEmpty) {
      return getEmpresa(id);
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/company/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );

    final data = _map(_json(response));

    return data;
  }

  static void logout() {
    token = null;
    userId = null;
    companyId = null;
    usuario = null;
  }

  static String _requireCompany() {
    final id = companyId;

    if (id == null || id.isEmpty) {
      throw Exception(
        'Sua conta ainda não possui uma empresa vinculada.',
      );
    }

    return id;
  }

  static Future<List<Map<String, dynamic>>> produtos() async {
    final id = _requireCompany();

    final response = await http.get(
      Uri.parse('$baseUrl/produtos/company/$id'),
      headers: _headers,
    );

    return _list(_json(response));
  }

  static Future<Map<String, dynamic>> criarProduto({
    required String nome,
    required String categoria,
    required double preco,
    required int quantidade,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/produtos'),
      headers: _headers,
      body: jsonEncode({
        'name': nome,
        'categoria': categoria,
        'companyId': _requireCompany(),
        'quantidade': quantidade,
        'preco': preco,
      }),
    );

    return _map(_json(response));
  }

  static Future<Map<String, dynamic>> atualizarProduto(
    String id, {
    String? nome,
    String? categoria,
    double? preco,
    int? quantidade,
  }) async {
    final body = <String, dynamic>{
      if (nome != null) 'name': nome,
      if (categoria != null) 'categoria': categoria,
      if (preco != null) 'preco': preco,
      if (quantidade != null) 'quantidade': quantidade,
      'companyId': _requireCompany(),
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/produtos/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _map(_json(response));
  }

  static Future<void> excluirProduto(
    String id,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/produtos/$id'),
      headers: _headers,
    );

    _json(response);
  }

  static Future<List<Map<String, dynamic>>> vendas() async {
    final id = _requireCompany();

    final response = await http.get(
      Uri.parse('$baseUrl/clientes/company/$id'),
      headers: _headers,
    );

    return _list(_json(response));
  }

  static Future<Map<String, dynamic>> criarVenda({
    required String cliente,
    required String pedido,
    required String produtoId,
    required double valor,
    required int itens,
    required String status,
    String? funcionarioId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clientes'),
      headers: _headers,
      body: jsonEncode({
        'name': cliente,
        'Numero': pedido,
        'IdProduto': produtoId,
        'idcompany': _requireCompany(),
        'Preco_gasto': valor,
        'Quantidade': itens,
        'status': status,
        if (funcionarioId != null && funcionarioId.isNotEmpty)
          'funcionarioId': funcionarioId,
      }),
    );

    return _map(_json(response));
  }

  static Future<Map<String, dynamic>> atualizarVenda(
    String id,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/clientes/$id'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
      }),
    );

    return _map(_json(response));
  }

  static Future<void> excluirVenda(
    String id,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/clientes/$id'),
      headers: _headers,
    );

    _json(response);
  }

  static Future<List<Map<String, dynamic>>> funcionarios() async {
    final id = _requireCompany();

    final response = await http.get(
      Uri.parse('$baseUrl/company/employees/by-company/$id'),
      headers: _headers,
    );

    return _list(_json(response));
  }

  static Future<Map<String, dynamic>> criarFuncionario({
    required String nome,
    required String cpf,
    required String funcao,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/company/employees'),
      headers: _headers,
      body: jsonEncode({
        'name': nome,
        'cpf': cpf,
        'companyId': _requireCompany(),
        'funcao': funcao,
        'status': status,
      }),
    );

    return _map(_json(response));
  }

  static Future<Map<String, dynamic>> atualizarFuncionario(
    String id, {
    String? nome,
    String? cpf,
    String? funcao,
    String? status,
  }) async {
    final body = <String, dynamic>{
      if (nome != null) 'name': nome,
      if (cpf != null) 'cpf': cpf,
      if (funcao != null) 'funcao': funcao,
      if (status != null) 'status': status,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/company/employees/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _map(_json(response));
  }

  static Future<void> excluirFuncionario(
    String id,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/company/employees/$id'),
      headers: _headers,
    );

    _json(response);
  }
}