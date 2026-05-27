import 'api_client.dart';

class PromptCatalogItem {
  final String id;
  final String text;
  final String category;

  const PromptCatalogItem({
    required this.id,
    required this.text,
    required this.category,
  });

  factory PromptCatalogItem.fromJson(Map<String, dynamic> json) {
    return PromptCatalogItem(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? 'fun',
    );
  }
}

class PromptAnswer {
  final String prompt;
  final String answer;

  const PromptAnswer({required this.prompt, required this.answer});

  Map<String, dynamic> toJson() => {'prompt': prompt, 'answer': answer};

  factory PromptAnswer.fromJson(Map<String, dynamic> json) {
    return PromptAnswer(
      prompt: json['prompt']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }
}

class PromptsService {
  final ApiClient _apiClient;

  PromptsService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<PromptCatalogItem>> fetchCatalog() async {
    final response = await _apiClient.get(
      '/profile/prompts/catalog',
      authenticated: true,
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PromptCatalogItem.fromJson)
        .toList();
  }

  Future<List<PromptAnswer>> fetchMyPrompts() async {
    final response = await _apiClient.get(
      '/profile/prompts',
      authenticated: true,
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PromptAnswer.fromJson)
        .toList();
  }

  Future<List<PromptAnswer>> savePrompts(List<PromptAnswer> prompts) async {
    final response = await _apiClient.put(
      '/profile/prompts',
      authenticated: true,
      body: {'prompts': prompts.map((p) => p.toJson()).toList()},
    );
    final data = (response['data'] as List<dynamic>?) ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PromptAnswer.fromJson)
        .toList();
  }
}
