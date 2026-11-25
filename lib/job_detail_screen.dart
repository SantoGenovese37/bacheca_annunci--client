import 'package:flutter/material.dart';
import 'package:flutter_app/job.dart';
import 'package:flutter_app/api_service.dart';
import 'package:flutter_app/apply_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final ApiService api;
  final Job job;

  const JobDetailScreen({
    super.key,
    required this.api,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Azienda: ${job.companyName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Descrizione',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(job.description),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Candidati'),
                onPressed: () async {
                  final submitted = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApplyScreen(api: api, job: job),
                    ),
                  );
                  if (submitted == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}