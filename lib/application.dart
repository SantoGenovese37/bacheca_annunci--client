class ApplicationItem {
  final String id;
  final String jobId;
  final String firstName;
  final String lastName;
  final String email;
  final String cvFileName;

  ApplicationItem({
    required this.id,
    required this.jobId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.cvFileName,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ApplicationItem.fromJson(Map<String, dynamic> json) {
    return ApplicationItem(
      id: (json['id'] ?? '').toString(),
      jobId: (json['jobId'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      cvFileName: (json['cvFileName'] ?? '').toString(),
    );
  }
}