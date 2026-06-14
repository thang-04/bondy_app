import 'api_client.dart';

class BlockResult {
  final String blockId;
  final String blockedAt;

  const BlockResult({required this.blockId, required this.blockedAt});

  factory BlockResult.fromJson(Map<String, dynamic> json) {
    return BlockResult(
      blockId: json['blockId'] as String,
      blockedAt: json['blockedAt'] as String,
    );
  }
}

class BlockedUser {
  final String blockId;
  final String userId;
  final String name;
  final String? photo;
  final DateTime? blockedAt;

  const BlockedUser({
    required this.blockId,
    required this.userId,
    required this.name,
    this.photo,
    this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final user = json['blockedUser'] as Map<String, dynamic>? ?? const {};
    final at = json['blockedAt']?.toString();
    return BlockedUser(
      blockId: json['blockId']?.toString() ?? '',
      userId: user['id']?.toString() ?? json['blockedUserId']?.toString() ?? '',
      name: user['name']?.toString() ?? 'Người dùng',
      photo: user['photo']?.toString(),
      blockedAt: at == null ? null : DateTime.tryParse(at),
    );
  }
}

class BlockService {
  final ApiClient _apiClient;

  BlockService(this._apiClient);

  Future<BlockResult> createBlock({required String blockedUserId}) async {
    final response = await _apiClient.post(
      '/blocks',
      body: {'blockedUserId': blockedUserId},
      authenticated: true,
    );
    return BlockResult.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<BlockedUser>> listBlocks() async {
    final response = await _apiClient.get('/blocks', authenticated: true);
    final data = (response['data'] as List<dynamic>?) ?? const [];
    return data
        .map((item) => BlockedUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteBlock(String blockId) async {
    await _apiClient.delete('/blocks/$blockId', authenticated: true);
  }
}
