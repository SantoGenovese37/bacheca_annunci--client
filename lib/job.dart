class Job {
  final String id;
  final String companyId;
  final String companyName;
  final String title;
  final String description;

  Job({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: (json['id'] ?? '').toString(),
      companyId: (json['companyId'] ?? '').toString(),
      companyName: (json['companyName'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}