import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/project.dart';
import '../models/task.dart';

class ProjectService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<Project>> getProjects() async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/projects/');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List body = jsonDecode(response.body);
      return body.map((item) => Project.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<Task>> getTasks(int projectId) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/tasks/project/$projectId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List body = jsonDecode(response.body);
      return body.map((item) => Task.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> createTask({
    required String title,
    required String description,
    required String status,
    required String priority,
    String? dueDate,
    required int projectId,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/tasks/');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'due_date': dueDate,
        'project_id': projectId,
      }),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> updateTaskStatus(int taskId, String newStatus) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/tasks/$taskId');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': newStatus}),
    );

    return response.statusCode == 200;
  }

  Future<bool> updateTask({
    required int taskId,
    required String title,
    required String description,
    required String status,
    required String priority,
    String? dueDate,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/tasks/$taskId');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'due_date': dueDate ?? '',
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteTask(int taskId) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/tasks/$taskId');

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<bool> createProject({
    required String name,
    required String description,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/projects/');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> updateProject(int projectId, String name, String description) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/projects/$projectId');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteProject(int projectId) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/projects/$projectId');

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }
}