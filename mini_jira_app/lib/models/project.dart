class Project {
  final int id;
  final String title; // Arayüzde title olarak kullanmaya devam ediyoruz
  final String description;

  Project({required this.id, required this.title, required this.description});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      // Backend'den 'name' geliyor, biz bunu Flutter içinde 'title' olarak eşliyoruz:
      title: json['name'] ?? '', 
      description: json['description'] ?? '',
    );
  }
}