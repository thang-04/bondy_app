import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_conversation.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AiSuggestRequest {
  final String conversationId;
  final String userId;
  final String intent;
  final String tone;
  final String language;

  AiSuggestRequest({
    required this.conversationId,
    required this.userId,
    required this.intent,
    this.tone = 'casual',
    this.language = 'vi',
  });

  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'userId': userId,
    'intent': intent,
    'tone': tone,
    'language': language,
  };
}

class AiSuggestData {
  final List<String> suggestions;
  final AiUsage usage;

  AiSuggestData({required this.suggestions, required this.usage});

  factory AiSuggestData.fromJson(Map<String, dynamic> json) => AiSuggestData(
    suggestions: List<String>.from(json['suggestions'] ?? const []),
    usage: AiUsage.fromJson(
      (json['usage'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );
}

class AiUsage {
  final int tokensUsed;
  final int latencyMs;
  final String provider;

  AiUsage({
    required this.tokensUsed,
    required this.latencyMs,
    required this.provider,
  });

  factory AiUsage.fromJson(Map<String, dynamic> json) => AiUsage(
    tokensUsed: json['tokensUsed'] ?? 0,
    latencyMs: json['latencyMs'] ?? 0,
    provider: json['provider'] ?? 'unknown',
  );
}

class AiSuggestResponse {
  final bool success;
  final AiSuggestData? data;
  final String? error;

  AiSuggestResponse({required this.success, this.data, this.error});

  factory AiSuggestResponse.fromJson(Map<String, dynamic> json) =>
      AiSuggestResponse(
        success: json['success'] ?? false,
        data: json['data'] != null
            ? AiSuggestData.fromJson(
                (json['data'] as Map).cast<String, dynamic>(),
              )
            : null,
        error: json['error']?.toString(),
      );

  bool get isLimitReached => error?.contains('LIMIT_REACHED') ?? false;
}

class AiChatRequest {
  final String chatId;
  final String message;
  final String matchId;
  final String intent;
  final String tone;
  final int count;
  final String language;

  AiChatRequest({
    required this.chatId,
    required this.message,
    required this.matchId,
    this.intent = 'continue',
    this.tone = 'casual',
    this.count = 3,
    this.language = 'vi',
  });

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'matchId': matchId,
    'message': message,
    'intent': intent,
    'tone': tone,
    'count': count,
    'language': language,
  };
}

enum AiChatMode {
  defaultMode,
  healing,
  coach,
  plan,
  aiTuVi,
  tarot;

  static AiChatMode fromJson(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'coach':
        return AiChatMode.coach;
      case 'healing':
        return AiChatMode.healing;
      case 'plan':
        return AiChatMode.plan;
      case 'ai-tu-vi':
        return AiChatMode.aiTuVi;
      case 'tarot':
        return AiChatMode.tarot;
      case 'default':
      default:
        return AiChatMode.defaultMode;
    }
  }

  String get apiValue {
    switch (this) {
      case AiChatMode.healing:
        return 'healing';
      case AiChatMode.coach:
        return 'coach';
      case AiChatMode.plan:
        return 'plan';
      case AiChatMode.aiTuVi:
        return 'ai-tu-vi';
      case AiChatMode.tarot:
        return 'tarot';
      case AiChatMode.defaultMode:
        return 'default';
    }
  }
}

enum AiChatMessageRole {
  user,
  assistant;

  static AiChatMessageRole fromJson(Object? value) {
    switch (value?.toString().toLowerCase()) {
      case 'assistant':
        return AiChatMessageRole.assistant;
      case 'user':
      default:
        return AiChatMessageRole.user;
    }
  }

  String get apiValue {
    switch (this) {
      case AiChatMessageRole.assistant:
        return 'assistant';
      case AiChatMessageRole.user:
        return 'user';
    }
  }
}

class AiChatMessage {
  final AiChatMessageRole role;
  final String content;

  const AiChatMessage({required this.role, required this.content});

  const AiChatMessage.user(String content)
    : this(role: AiChatMessageRole.user, content: content);

  const AiChatMessage.assistant(String content)
    : this(role: AiChatMessageRole.assistant, content: content);

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      role: AiChatMessageRole.fromJson(json['role']),
      content: json['content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'role': role.apiValue, 'content': content};
}

class AiModeQuota {
  final AiChatMode mode;
  final String feature;
  final String label;
  final String tier;
  final int limit;
  final int used;
  final int remaining;
  final String? resetsAt;
  final String? source;
  final AiQuotaPass? pass;

  const AiModeQuota({
    required this.mode,
    required this.feature,
    required this.label,
    required this.tier,
    required this.limit,
    required this.used,
    required this.remaining,
    this.resetsAt,
    this.source,
    this.pass,
  });

  factory AiModeQuota.fromJson(Map<String, dynamic> json) {
    final passJson = json['pass'];
    return AiModeQuota(
      mode: AiChatMode.fromJson(json['mode']),
      feature: json['feature']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      tier: json['tier']?.toString() ?? 'FREE',
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      used: (json['used'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      resetsAt: json['resetsAt']?.toString(),
      source: json['source']?.toString(),
      pass: passJson is Map
          ? AiQuotaPass.fromJson(passJson.cast<String, dynamic>())
          : null,
    );
  }

  AiModeQuota copyWith({
    AiChatMode? mode,
    int? used,
    int? remaining,
    String? source,
    AiQuotaPass? pass,
  }) {
    return AiModeQuota(
      mode: mode ?? this.mode,
      feature: feature,
      label: label,
      tier: tier,
      limit: limit,
      used: used ?? this.used,
      remaining: remaining ?? this.remaining,
      resetsAt: resetsAt,
      source: source ?? this.source,
      pass: pass ?? this.pass,
    );
  }
}

class AiQuotaPass {
  final String id;
  final String packageCode;
  final int remainingTurns;
  final String expiresAt;

  const AiQuotaPass({
    required this.id,
    required this.packageCode,
    required this.remainingTurns,
    required this.expiresAt,
  });

  factory AiQuotaPass.fromJson(Map<String, dynamic> json) {
    return AiQuotaPass(
      id: json['id']?.toString() ?? '',
      packageCode: json['packageCode']?.toString() ?? '',
      remainingTurns: (json['remainingTurns'] as num?)?.toInt() ?? 0,
      expiresAt: json['expiresAt']?.toString() ?? '',
    );
  }
}

class AiQuotaUpgradeModal {
  final String title;
  final String message;
  final String ctaLabel;
  final String secondaryCtaLabel;
  final String targetScreen;
  final String recommendedTier;
  final List<String> benefits;

  const AiQuotaUpgradeModal({
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.secondaryCtaLabel,
    required this.targetScreen,
    required this.recommendedTier,
    required this.benefits,
  });

  factory AiQuotaUpgradeModal.fromJson(Map<String, dynamic> json) {
    return AiQuotaUpgradeModal(
      title: json['title']?.toString() ?? 'Bạn đã hết lượt AI hôm nay',
      message:
          json['message']?.toString() ??
          'Nâng cấp subscription để có thêm lượt AI mỗi ngày.',
      ctaLabel: json['ctaLabel']?.toString() ?? 'Xem gói subscription',
      secondaryCtaLabel: json['secondaryCtaLabel']?.toString() ?? 'Để sau',
      targetScreen: json['targetScreen']?.toString() ?? 'SubscriptionScreen',
      recommendedTier: json['recommendedTier']?.toString() ?? 'PLUS',
      benefits: (json['benefits'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class AiQuotaExceededData {
  final AiChatMode mode;
  final String tier;
  final AiModeQuota? quota;
  final AiChatPassesSummary passes;
  final Map<String, int> dailyLimitsByTier;
  final AiQuotaPaywall? paywall;
  final AiQuotaUpgradeModal? upgradeModal;

  const AiQuotaExceededData({
    required this.mode,
    required this.tier,
    required this.quota,
    required this.passes,
    required this.dailyLimitsByTier,
    required this.paywall,
    required this.upgradeModal,
  });

  factory AiQuotaExceededData.fromJson(Map<String, dynamic> json) {
    final quotaJson = json['quota'];
    final modalJson = json['upgradeModal'];
    final paywallJson = json['paywall'];
    return AiQuotaExceededData(
      mode: AiChatMode.fromJson(json['mode']),
      tier: json['tier']?.toString() ?? 'FREE',
      quota: quotaJson is Map
          ? AiModeQuota.fromJson(quotaJson.cast<String, dynamic>())
          : null,
      passes: AiChatPassesSummary.fromJson(json['passes']),
      dailyLimitsByTier: _parseDailyLimits(json['dailyLimitsByTier']),
      paywall: paywallJson is Map
          ? AiQuotaPaywall.fromJson(paywallJson.cast<String, dynamic>())
          : null,
      upgradeModal: modalJson is Map
          ? AiQuotaUpgradeModal.fromJson(modalJson.cast<String, dynamic>())
          : null,
    );
  }

  int? limitForTier(String tier, AiChatMode mode) => dailyLimitsByTier[tier];
}

class AiQuotaSummary {
  final String tier;
  final String? resetsAt;
  final AiModeQuota? daily;
  final AiChatPassesSummary passes;
  final Map<AiChatMode, AiModeQuota> quotas;
  final Map<String, int> dailyLimitsByTier;

  const AiQuotaSummary({
    required this.tier,
    required this.resetsAt,
    required this.daily,
    required this.passes,
    required this.quotas,
    required this.dailyLimitsByTier,
  });

  factory AiQuotaSummary.fromJson(Map<String, dynamic> json) {
    final rawQuotas = (json['quotas'] as Map?)?.cast<String, dynamic>() ?? {};
    final quotas = <AiChatMode, AiModeQuota>{};
    for (final entry in rawQuotas.entries) {
      final value = entry.value;
      if (value is Map) {
        final quota = AiModeQuota.fromJson(value.cast<String, dynamic>());
        quotas[quota.mode] = quota;
      }
    }
    final dailyJson = json['daily'];
    final daily = dailyJson is Map
        ? AiModeQuota.fromJson(dailyJson.cast<String, dynamic>())
        : null;
    if (daily != null) {
      for (final mode in AiChatMode.values) {
        quotas.putIfAbsent(mode, () => daily.copyWith(mode: mode));
      }
    }

    return AiQuotaSummary(
      tier: json['tier']?.toString() ?? 'FREE',
      resetsAt: json['resetsAt']?.toString(),
      daily: daily,
      passes: AiChatPassesSummary.fromJson(json['passes']),
      quotas: quotas,
      dailyLimitsByTier: _parseDailyLimits(json['dailyLimitsByTier']),
    );
  }

  AiModeQuota? quotaFor(AiChatMode mode) => quotas[mode];

  int? limitForTier(String tier, AiChatMode mode) {
    return dailyLimitsByTier[tier];
  }

  AiQuotaSummary copyWithQuota(AiModeQuota quota) {
    return AiQuotaSummary(
      tier: quota.tier.isNotEmpty ? quota.tier : tier,
      resetsAt: quota.resetsAt ?? resetsAt,
      daily: quota.feature == 'daily_ai_chat' ? quota : daily,
      passes: passes,
      quotas: {...quotas, quota.mode: quota},
      dailyLimitsByTier: dailyLimitsByTier,
    );
  }
}

class AiChatPassSummary {
  final String id;
  final String packageCode;
  final int totalTurns;
  final int usedTurns;
  final int remainingTurns;
  final String startsAt;
  final String expiresAt;

  const AiChatPassSummary({
    required this.id,
    required this.packageCode,
    required this.totalTurns,
    required this.usedTurns,
    required this.remainingTurns,
    required this.startsAt,
    required this.expiresAt,
  });

  factory AiChatPassSummary.fromJson(Map<String, dynamic> json) {
    return AiChatPassSummary(
      id: json['id']?.toString() ?? '',
      packageCode: json['packageCode']?.toString() ?? '',
      totalTurns: (json['totalTurns'] as num?)?.toInt() ?? 0,
      usedTurns: (json['usedTurns'] as num?)?.toInt() ?? 0,
      remainingTurns: (json['remainingTurns'] as num?)?.toInt() ?? 0,
      startsAt: json['startsAt']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
    );
  }
}

class AiChatPassesSummary {
  final List<AiChatPassSummary> active;
  final int totalRemaining;

  const AiChatPassesSummary({
    required this.active,
    required this.totalRemaining,
  });

  const AiChatPassesSummary.empty() : active = const [], totalRemaining = 0;

  factory AiChatPassesSummary.fromJson(Object? value) {
    if (value is! Map) return const AiChatPassesSummary.empty();
    final json = value.cast<String, dynamic>();
    final active = (json['active'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => AiChatPassSummary.fromJson(item.cast<String, dynamic>()))
        .toList();
    return AiChatPassesSummary(
      active: active,
      totalRemaining:
          (json['totalRemaining'] as num?)?.toInt() ??
          active.fold<int>(0, (sum, pass) => sum + pass.remainingTurns),
    );
  }
}

class AiQuotaPaywall {
  final String reason;
  final String title;
  final String message;
  final String primaryCtaLabel;
  final String redirectScreen;
  final String? redirectTab;
  final List<String> recommendedProductTypes;

  const AiQuotaPaywall({
    required this.reason,
    required this.title,
    required this.message,
    required this.primaryCtaLabel,
    required this.redirectScreen,
    required this.redirectTab,
    required this.recommendedProductTypes,
  });

  factory AiQuotaPaywall.fromJson(Map<String, dynamic> json) {
    final params = json['redirectParams'];
    return AiQuotaPaywall(
      reason: json['reason']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Ban da het luot AI',
      message: json['message']?.toString() ?? '',
      primaryCtaLabel: json['primaryCtaLabel']?.toString() ?? 'Xem goi AI',
      redirectScreen: json['redirectScreen']?.toString() ?? '',
      redirectTab: params is Map ? params['tab']?.toString() : null,
      recommendedProductTypes:
          (json['recommendedProductTypes'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

Map<String, int> _parseDailyLimits(Object? value) {
  final raw = value is Map ? value.cast<String, dynamic>() : const {};
  return raw.map((tier, limits) {
    if (limits is num) return MapEntry(tier, limits.toInt());
    if (limits is Map) {
      final rawLimits = limits.cast<String, dynamic>();
      final preferred =
          rawLimits['default'] ??
          rawLimits['healing'] ??
          rawLimits['coach'] ??
          _firstNumericValue(rawLimits.values);
      return MapEntry(tier, (preferred as num?)?.toInt() ?? 0);
    }
    return MapEntry(tier, 0);
  });
}

num? _firstNumericValue(Iterable<dynamic> values) {
  for (final value in values) {
    if (value is num) return value;
  }
  return null;
}

class AiStreamChatRequest {
  final List<AiChatMessage> messages;
  final AiChatMode mode;
  final String? sessionId;
  final String? conversationId;

  const AiStreamChatRequest({
    required this.messages,
    this.mode = AiChatMode.defaultMode,
    this.sessionId,
    this.conversationId,
  });

  factory AiStreamChatRequest.singleUserMessage({
    required String message,
    AiChatMode mode = AiChatMode.defaultMode,
    String? sessionId,
    String? conversationId,
  }) {
    return AiStreamChatRequest(
      messages: [AiChatMessage.user(message)],
      mode: mode,
      sessionId: sessionId,
      conversationId: conversationId,
    );
  }

  Map<String, dynamic> toJson() => {
    'messages': messages.map((message) => message.toJson()).toList(),
    'mode': mode.apiValue,
    if (sessionId != null && sessionId!.isNotEmpty) 'sessionId': sessionId,
    if (conversationId != null && conversationId!.isNotEmpty)
      'conversationId': conversationId,
  };
}

enum AiStreamEventType { chunk, metadata, error }

class AiChatStreamMetadata {
  final AiChatMode mode;
  final String? sessionId;
  final AiModeQuota? quota;
  final Map<String, dynamic> raw;

  const AiChatStreamMetadata({
    required this.mode,
    this.sessionId,
    this.quota,
    required this.raw,
  });

  factory AiChatStreamMetadata.fromJson(Map<String, dynamic> json) {
    final quotaJson = json['quota'];
    return AiChatStreamMetadata(
      mode: AiChatMode.fromJson(json['mode']),
      sessionId: json['sessionId']?.toString(),
      quota: quotaJson is Map
          ? AiModeQuota.fromJson(quotaJson.cast<String, dynamic>())
          : null,
      raw: json,
    );
  }
}

class AiChatStreamEvent {
  final AiStreamEventType type;
  final String? chunk;
  final String? error;
  final AiChatStreamMetadata? metadata;

  const AiChatStreamEvent._({
    required this.type,
    this.chunk,
    this.error,
    this.metadata,
  });

  factory AiChatStreamEvent.chunk(String chunk) =>
      AiChatStreamEvent._(type: AiStreamEventType.chunk, chunk: chunk);

  factory AiChatStreamEvent.error(String error) =>
      AiChatStreamEvent._(type: AiStreamEventType.error, error: error);

  factory AiChatStreamEvent.metadata(AiChatStreamMetadata metadata) =>
      AiChatStreamEvent._(type: AiStreamEventType.metadata, metadata: metadata);
}

class AiChatMeta {
  final int tokensUsed;
  final int latencyMs;
  final bool failed;
  final List<String> suggestions;
  final AiModeQuota? quota;
  final Map<String, dynamic> raw;

  AiChatMeta({
    required this.tokensUsed,
    required this.latencyMs,
    required this.failed,
    required this.suggestions,
    this.quota,
    required this.raw,
  });

  factory AiChatMeta.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'];
    final quotaJson = json['quota'];
    return AiChatMeta(
      tokensUsed: json['tokensUsed'] as int? ?? 0,
      latencyMs: json['latencyMs'] as int? ?? 0,
      failed: json['failed'] == true,
      suggestions: rawSuggestions is List
          ? rawSuggestions.map((item) => item.toString()).toList()
          : const [],
      quota: quotaJson is Map
          ? AiModeQuota.fromJson(quotaJson.cast<String, dynamic>())
          : null,
      raw: json,
    );
  }

  bool get isHighSafety {
    final rawValue =
        raw['safetyLevel'] ??
        raw['safety'] ??
        raw['riskLevel'] ??
        raw['severity'];
    final value = rawValue?.toString().toLowerCase();
    return value == 'high' || value == 'critical' || value == 'severe';
  }
}

class AiChatData {
  final String flowVersion;
  final String chatId;
  final String matchId;
  final String partnerId;
  final String partnerName;
  final String? coachSessionId;
  final String response;
  final AiChatMode mode;
  final AiChatMeta meta;

  AiChatData({
    required this.flowVersion,
    required this.chatId,
    required this.matchId,
    required this.partnerId,
    required this.partnerName,
    required this.response,
    required this.mode,
    required this.meta,
    this.coachSessionId,
  });

  factory AiChatData.fromJson(Map<String, dynamic> json) {
    final rawMeta = Map<String, dynamic>.from(
      (json['meta'] as Map?) ?? const <String, dynamic>{},
    );
    if (json['suggestions'] is List && rawMeta['suggestions'] == null) {
      rawMeta['suggestions'] = json['suggestions'];
    }

    return AiChatData(
      flowVersion: json['flowVersion']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      partnerName: json['partnerName']?.toString() ?? '',
      coachSessionId: json['coachSessionId']?.toString(),
      response: json['response']?.toString() ?? '',
      mode: AiChatMode.fromJson(json['mode']),
      meta: AiChatMeta.fromJson(rawMeta),
    );
  }
}

class AiChatResponse {
  final bool success;
  final AiChatData? data;
  final String? error;

  AiChatResponse({required this.success, this.data, this.error});

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return AiChatResponse(
        success: json['success'] != false,
        data: AiChatData.fromJson(data.cast<String, dynamic>()),
        error: json['error']?.toString(),
      );
    }

    // Some backend handlers return the chat payload directly.
    if (json.containsKey('response')) {
      return AiChatResponse(
        success: true,
        data: AiChatData.fromJson(json),
        error: json['error']?.toString(),
      );
    }

    return AiChatResponse(
      success: json['success'] == true,
      error: json['error']?.toString(),
    );
  }
}

class AiService {
  final ApiClient _apiClient;
  final AuthService _authService;
  final http.Client _httpClient;
  final Duration coachTimeout;

  AiService(
    this._apiClient, {
    AuthService? authService,
    http.Client? httpClient,
    this.coachTimeout = const Duration(seconds: 120),
  }) : _authService = authService ?? AuthService(),
       _httpClient = httpClient ?? http.Client();

  Future<AiQuotaSummary> getQuota() async {
    final response = await _apiClient.get('/ai/quota', authenticated: true);
    return AiQuotaSummary.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<AiSuggestResponse> suggest(AiSuggestRequest request) async {
    final response = await _apiClient
        .post(
          '/ai/conversation-suggest',
          body: request.toJson(),
          authenticated: true,
        )
        .timeout(const Duration(seconds: 50));
    return AiSuggestResponse.fromJson(response);
  }

  Future<AiChatResponse> chatCoach(AiChatRequest request) async {
    final response = await _apiClient
        .post(
          '/ai/coach/suggestions',
          body: request.toJson(),
          authenticated: true,
        )
        .timeout(coachTimeout);
    return AiChatResponse.fromJson(response);
  }

  Stream<AiChatStreamEvent> streamChat(AiStreamChatRequest request) async* {
    final response = await _sendStreamRequest(request);
    yield* _parseSse(response.stream);
  }

  Future<http.StreamedResponse> _sendStreamRequest(
    AiStreamChatRequest chatRequest,
  ) async {
    final token = await _authService.requireAccessToken();
    var response = await _httpClient.send(
      _buildStreamRequest(chatRequest, token),
    );

    if (response.statusCode == 401) {
      try {
        final refreshed = await _authService.refreshAccessToken();
        response = await _httpClient.send(
          _buildStreamRequest(chatRequest, refreshed.accessToken),
        );
      } on SessionExpiredException {
        // Refresh token thật sự hết hạn / bị thu hồi → đăng xuất.
        await _authService.clearSession();
        throw const ApiClientException(
          'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
          statusCode: 401,
          code: 'UNAUTHORIZED',
        );
      }
      // Lỗi tạm thời khi refresh (mạng/timeout) lan ra ngoài, KHÔNG đăng xuất.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyText = await response.stream.bytesToString();
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(bodyText) as Map<String, dynamic>;
      } catch (_) {}
      throw ApiClientException(
        body['error']?.toString() ?? 'Đã xảy ra lỗi. Vui lòng thử lại.',
        statusCode: response.statusCode,
        code: body['code']?.toString(),
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : null,
      );
    }

    return response;
  }

  http.Request _buildStreamRequest(
    AiStreamChatRequest chatRequest,
    String token,
  ) {
    return http.Request('POST', Uri.parse('${_apiClient.baseUrl}/ai/chat'))
      ..headers.addAll({
        'content-type': 'application/json',
        'accept': 'text/event-stream',
        'authorization': 'Bearer $token',
      })
      ..body = jsonEncode(chatRequest.toJson());
  }

  Stream<AiChatStreamEvent> _parseSse(Stream<List<int>> stream) async* {
    String? eventType;
    final dataLines = <String>[];

    await for (final line
        in stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.trim().isEmpty) {
        final event = _decodeSseEvent(eventType, dataLines.join('\n'));
        if (event != null) yield event;
        eventType = null;
        dataLines.clear();
        continue;
      }

      if (line.startsWith('event:')) {
        eventType = line.substring('event:'.length).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring('data:'.length).trimLeft());
      }
    }

    if (eventType != null || dataLines.isNotEmpty) {
      final event = _decodeSseEvent(eventType, dataLines.join('\n'));
      if (event != null) yield event;
    }
  }

  AiChatStreamEvent? _decodeSseEvent(String? eventType, String dataText) {
    if (eventType == null || dataText.isEmpty) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(dataText);
    } catch (_) {
      decoded = dataText;
    }

    switch (eventType) {
      case 'chunk':
        return AiChatStreamEvent.chunk(decoded?.toString() ?? '');
      case 'metadata':
        if (decoded is Map) {
          return AiChatStreamEvent.metadata(
            AiChatStreamMetadata.fromJson(decoded.cast<String, dynamic>()),
          );
        }
        return null;
      case 'error':
        return AiChatStreamEvent.error(decoded?.toString() ?? '');
      default:
        return null;
    }
  }

  // ── Conversation History API ──────────────────────────────────────

  /// Lấy danh sách conversations của user.
  Future<AiConversationListResponse> getConversations({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/ai/conversations',
      authenticated: true,
      queryParams: {'limit': '$limit', 'offset': '$offset'},
    );
    return AiConversationListResponse.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Tạo conversation mới.
  Future<AiConversation> createConversation({
    required String mode,
    String? title,
  }) async {
    final body = <String, dynamic>{'mode': mode};
    if (title != null) {
      body['title'] = title;
    }

    final response = await _apiClient.post(
      '/ai/conversations',
      body: body,
      authenticated: true,
    );
    return AiConversation.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Lấy conversation detail + messages.
  Future<AiConversationDetail> getConversation(String conversationId) async {
    final response = await _apiClient.get(
      '/ai/conversations/$conversationId',
      authenticated: true,
    );
    return AiConversationDetail.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Xóa conversation.
  Future<void> deleteConversation(String conversationId) async {
    await _apiClient.delete(
      '/ai/conversations/$conversationId',
      authenticated: true,
    );
  }

  /// Lưu message pair (user + assistant) sau khi chat xong.
  Future<void> saveMessages(
    String conversationId, {
    required String userMessage,
    required String assistantMessage,
  }) async {
    await _apiClient.post(
      '/ai/conversations/$conversationId/messages',
      body: {'userMessage': userMessage, 'assistantMessage': assistantMessage},
      authenticated: true,
    );
  }
}
