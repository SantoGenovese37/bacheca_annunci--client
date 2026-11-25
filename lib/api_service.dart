import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_app/application.dart';
import 'package:flutter_app/job.dart';

class ApiService {
  final String baseUrl;
  String? token;
  String? companyName;

  ApiService({this.baseUrl = 'http://10.168.125.49:8080'});

  bool get isLoggedIn => token != null;

  void logout() {
    token = null;
    companyName = null;
  }

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<void> registerCompany({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (res.statusCode != 201) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Errore durante la registrazione.');
    }
  }

  Future<void> loginCompany({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Credenziali non valide.');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    token = data['token'] as String;
    companyName = data['companyName'] as String;
  }

  Future<void> deleteJob(String jobId) async {
    final url = Uri.parse('$baseUrl/jobs/$jobId');

    print('DELETE URL: $url');

    final res = await http.delete(
      url,
      headers: _headers(),
    );

    print('DELETE STATUS: ${res.statusCode}');
    print('DELETE BODY: ${res.body}');

    if (res.statusCode != 200) {
      String message = res.body;

      try {
        final data = jsonDecode(res.body);

        if (data is Map<String, dynamic>) {
          message = data['error']?.toString() ?? res.body;
        }
      } catch (_) {
      }

      throw Exception(message);
    }
  }

  Future<List<Job>> fetchJobs() async {
    final res = await http.get(Uri.parse('$baseUrl/jobs'));
    if (res.statusCode != 200) {
      throw Exception('Impossibile caricare gli annunci.');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createJob({
    required String title,
    required String description,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/jobs'),
      headers: _headers(),
      body: jsonEncode({'title': title, 'description': description}),
    );
    if (res.statusCode != 201) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Errore nella pubblicazione.');
    }
  }

  Future<List<Job>> fetchMyJobs() async {
    final res = await http.get(
      Uri.parse('$baseUrl/my-jobs'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Impossibile caricare i tuoi annunci.');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> submitApplication({
    required String jobId,
    required String firstName,
    required String lastName,
    required String email,
    required File cvFile,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/jobs/$jobId/apply'),
    );
    req.fields['firstName'] = firstName;
    req.fields['lastName'] = lastName;
    req.fields['email'] = email;
    req.files.add(await http.MultipartFile.fromPath('cv', cvFile.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 201) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Errore nell\'invio della candidatura.');
    }
  }

  Future<List<ApplicationItem>> fetchApplications(String jobId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/my-jobs/$jobId/applications'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Impossibile caricare le candidature.');
    }
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => ApplicationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String cvDownloadUrl(String cvFileName) => '$baseUrl/cv/$cvFileName';


}

