import 'package:flutter/material.dart';

import 'package:flutter_app/job.dart';
import 'package:flutter_app/api_service.dart';
import 'package:flutter_app/auth_screen.dart';
import 'package:flutter_app/company_dashboard_screen.dart';
import 'package:flutter_app/job_detail_screen.dart';

class PublicBoardScreen extends StatefulWidget {
  final ApiService api;

  const PublicBoardScreen({
    super.key,
    required this.api,
  });

  @override
  State<PublicBoardScreen> createState() => _PublicBoardScreenState();
}

class _PublicBoardScreenState extends State<PublicBoardScreen> {
  late Future<List<Job>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _jobsFuture = widget.api.fetchJobs();
  }

  void _reloadJobs() {
    if (!mounted) return;

    setState(() {
      _jobsFuture = widget.api.fetchJobs();
    });
  }

  Future<void> _openCompanyArea() async {
    if (widget.api.isLoggedIn) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompanyDashboardScreen(api: widget.api),
        ),
      );

      if (!mounted) return;

      _reloadJobs();
      return;
    }

    final loggedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(api: widget.api),
      ),
    );

    if (!mounted) return;

    if (loggedIn == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompanyDashboardScreen(api: widget.api),
        ),
      );

      if (!mounted) return;

      _reloadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Annunci'),
        actions: [
          TextButton.icon(
            onPressed: _openCompanyArea,
            icon: const Icon(Icons.business),
            label: Text(
              widget.api.isLoggedIn ? 'Area Azienda' : 'Aziende',
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Job>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Errore: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reloadJobs,
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              ),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return const Center(
              child: Text(
                'Nessun annuncio pubblicato al momento.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reloadJobs();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(job.companyName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(
                            api: widget.api,
                            job: job,
                          ),
                        ),
                      );

                      if (!mounted) return;

                      _reloadJobs();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}