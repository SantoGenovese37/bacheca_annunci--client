import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_app/job.dart';
import 'package:flutter_app/api_service.dart';
import 'package:flutter_app/public_board_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final ApiService api;

  const CompanyDashboardScreen({
    super.key,
    required this.api,
  });

  @override
  State<CompanyDashboardScreen> createState() =>
      _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState
    extends State<CompanyDashboardScreen> {
  late Future<List<Job>> _myJobsFuture;

  @override
  void initState() {
    super.initState();
    _myJobsFuture = widget.api.fetchMyJobs();
  }

  void _reloadMyJobs() {
    if (!mounted) return;

    setState(() {
      _myJobsFuture = widget.api.fetchMyJobs();
    });
  }

  Future<void> _deleteJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare annuncio?'),
        content: Text(
          'Vuoi davvero eliminare "${job.title}"?\n\n'
              'Le candidature e i CV associati verranno eliminati definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.api.deleteJob(job.id);

      if (!mounted) return;

      _reloadMyJobs();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annuncio eliminato correttamente.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _showCreateJobDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _CreateJobDialog(api: widget.api);
      },
    );

    if (!mounted) return;

    if (created == true) {
      _reloadMyJobs();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annuncio pubblicato!'),
        ),
      );
    }
  }

  Future<void> _openApplicationsForJob(Job job) async {
    try {
      final apps = await widget.api.fetchApplications(job.id);

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        builder: (sheetCtx) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.isEmpty ? 1 : apps.length,
            itemBuilder: (context, index) {
              if (apps.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nessuna candidatura ricevuta per questo annuncio.',
                    ),
                  ),
                );
              }

              final app = apps[index];

              return Card(
                child: ListTile(
                  title: Text(app.fullName),
                  subtitle: Text(app.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Apri CV',
                    onPressed: () async {
                      final uri = Uri.parse(
                        widget.api.cvDownloadUrl(app.cvFileName),
                      );

                      final opened = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );

                      if (!opened && mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossibile aprire il CV.'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  void _logout() {
    widget.api.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PublicBoardScreen(api: widget.api),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.api.companyName ?? 'Area Azienda',
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateJobDialog,
        icon: const Icon(Icons.add),
        label: const Text('Pubblica'),
      ),
      body: FutureBuilder<List<Job>>(
        future: _myJobsFuture,
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
                      onPressed: _reloadMyJobs,
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
                'Non hai ancora pubblicato annunci.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(job.title),
                  subtitle: Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Elimina annuncio',
                        onPressed: () => _deleteJob(job),
                      ),
                    ],
                  ),
                  onTap: () => _openApplicationsForJob(job),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CreateJobDialog extends StatefulWidget {
  final ApiService api;

  const _CreateJobDialog({
    required this.api,
  });

  @override
  State<_CreateJobDialog> createState() =>
      _CreateJobDialogState();
}

class _CreateJobDialogState extends State<_CreateJobDialog> {
  final TextEditingController _titleCtrl =
  TextEditingController();

  final TextEditingController _descCtrl =
  TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inserisci sia il titolo sia la descrizione.',
          ),
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.api.createJob(
        title: title,
        description: description,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Errore durante la pubblicazione: $e',
          ),
        ),
      );

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Nuovo annuncio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Titolo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            enabled: !_isSubmitting,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descrizione',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _publish,
          child: _isSubmitting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text('Pubblica'),
        ),
      ],
    );
  }
}

