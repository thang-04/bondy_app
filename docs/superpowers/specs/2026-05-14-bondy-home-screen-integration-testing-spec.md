# Bondy Home Screen - Integration and Testing Specification

**Version:** 1.0
**Date:** 2026-05-14
**Project:** Bondy App Home Screen Rebuild
**Design System:** "The Digital Sanctuary" (DESIGN.md)

---

## 1. Overview

This document specifies the integration points, API contracts, testing strategy, and verification procedures for the Bondy Home Screen full-stack rebuild.

### Scope

| Layer | Component | Status |
|-------|-----------|--------|
| Flutter | HomeService + HomeViewModel | Implemented |
| Flutter | 5 Widget Renderers | Implemented |
| Backend | `/api/home/content` Route | Implemented |
| Backend | HomeService Rule Engine | Implemented |
| Backend | HomeRepository | Partial (gaps) |
| Database | Prisma Schema | Missing Relationship/Checkin/Milestone models |

---

## 2. Integration Points

### 2.1 API Endpoint

**Endpoint:** `GET /api/home/content?userId=<userId>`

**Flutter Caller:** `Bondy_App/lib/services/home_service.dart`

```dart
// Line 15-31: fetchHomeContent
Future<List<HomeWidget>> fetchHomeContent(String userId) async {
  final body = await _apiClient.get('/home/content?userId=$userId');
  if (body['success'] != true) {
    throw Exception(body['error']?.toString() ?? 'Lỗi không xác định');
  }
  final widgetsJson = (body['data']?['widgets'] as List<dynamic>?) ?? [];
  final widgets = widgetsJson.map((w) => HomeWidget.fromJson(w as Map<String, dynamic>)).toList();
  widgets.sort((a, b) => a.priority.compareTo(b.priority));
  return widgets;
}
```

**Backend Handler:** `bondy_server/src/app/api/home/content/route.ts`

```typescript
// Lines 8-31
export async function GET(req: NextRequest) {
    const { searchParams } = new URL(req.url);
    const userId = searchParams.get('userId');
    if (!userId || userId.trim() === '') {
        return NextResponse.json({ success: false, error: 'Thiếu userId.' }, { status: 400 });
    }
    const result = await homeService.buildHomeContent(userId.trim());
    return NextResponse.json({ success: true, data: result });
}
```

### 2.2 Data Flow

```
┌─────────────┐    GET /home/content?userId=xxx    ┌──────────────────┐
│ Flutter     │ ─────────────────────────────────► │ bondy_server      │
│ HomeService │                                    │ HomeService      │
│             │ ◄─────────────────────────────────  │ (rule engine)    │
└─────────────┘         { success: true, data: }    └────────┬─────────┘
                                                             │
                    ┌────────────────────────────────────────┴────────┐
                    ▼                                                    ▼
          ┌─────────────────────┐                      ┌─────────────────────┐
          │ HomeRepository      │                      │ Prisma DB           │
          │ (5 rule queries)     │                      │ (User, Profile,     │
          │ HAS GAPS: returns    │                      │  Survey, Swipe,     │
          │ null for Rule 2, 3   │                      │  Match)             │
          └─────────────────────┘                      └─────────────────────┘
```

### 2.3 Widget Type Enum Mapping

| Widget Type | Flutter Renderer | Backend widget_type | Priority Rule |
|-------------|------------------|---------------------|---------------|
| BannerWidget | `lib/widgets/home/banner_widget.dart` | `BANNER` | 1 (if no survey) |
| EmotionCheckinWidget | `lib/widgets/home/emotion_checkin_widget.dart` | `EMOTION_CHECKIN` | 2 (if relationship) |
| MilestoneReminderWidget | `lib/widgets/home/milestone_reminder_widget.dart` | `MILESTONE_REMINDER` | 3 (if milestone) |
| DiscoveryCardWidget | `lib/widgets/home/discovery_card_widget.dart` | `DISCOVERY_CARD` | 4 (if solo/no match) |
| SuggestionCardWidget | `lib/widgets/home/suggestion_card_widget.dart` | `SUGGESTION_CARD` | 5 (always last) |

---

## 3. API Contract

### 3.1 Request

```
GET /api/home/content?userId=<string>
Headers:
  content-type: application/json
  [authorization: Bearer <token>]  // Optional, endpoint does NOT require auth currently
```

### 3.2 Success Response (200)

```json
{
  "success": true,
  "data": {
    "widgets": [
      {
        "widget_type": "BANNER",
        "priority": 1,
        "data": {
          "action": "COMPLETE_SURVEY",
          "title": "Hoàn thành khảo sát để Bondy hiểu bạn hơn 💬",
          "cta": "Bắt đầu ngay"
        }
      },
      {
        "widget_type": "EMOTION_CHECKIN",
        "priority": 2,
        "data": {
          "relationship_id": "<uuid>",
          "partner_name": "Người ấy"
        }
      },
      {
        "widget_type": "MILESTONE_REMINDER",
        "priority": 3,
        "data": {
          "title": "Kỷ niệm 1 năm",
          "date": "2026-05-20",
          "days_left": 6
        }
      },
      {
        "widget_type": "DISCOVERY_CARD",
        "priority": 4,
        "data": {
          "profiles": [
            {
              "user_id": "<uuid>",
              "name": "Minh",
              "city": "TP.HCM",
              "common_interests": ["Du lịch", "Nấu ăn"]
            }
          ]
        }
      },
      {
        "widget_type": "SUGGESTION_CARD",
        "priority": 5,
        "data": {
          "dating_goal": "serious",
          "title": "Xây dựng tình yêu bền vững 💑",
          "content": "Hãy thử chia sẻ điều bạn trân trọng nhất trong một mối quan hệ."
        }
      }
    ]
  }
}
```

### 3.3 Error Response (400/500)

```json
{
  "success": false,
  "error": "Thiếu userId."
}
```

### 3.4 Widget Data Schemas

#### BANNER
```typescript
{
  action: "COMPLETE_SURVEY" | string,
  title: string,
  cta: string
}
```

#### EMOTION_CHECKIN
```typescript
{
  relationship_id: string,
  partner_name: string
}
```

#### MILESTONE_REMINDER
```typescript
{
  title: string,
  date: string,       // ISO date "2026-05-20"
  days_left: number   // 0 = today, 1 = tomorrow, etc.
}
```

#### DISCOVERY_CARD
```typescript
{
  profiles: Array<{
    user_id: string,
    name: string | null,
    city: string | null,
    common_interests: string[]
  }>
}
```

#### SUGGESTION_CARD
```typescript
{
  dating_goal: "serious" | "casual" | "friendship" | "general",
  title: string,
  content: string
}
```

---

## 4. Testing Strategy

### 4.1 Flutter Testing

#### 4.1.1 Unit Tests - HomeService

**File to create:** `Bondy_App/test/services/home_service_test.dart`

```dart
import 'package:bondy/services/home_service.dart';
import 'package:bondy/models/home/home_widget_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HomeService', () {
    test('parse widgets from successful response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/home/content');
        expect(request.url.queryParameters['userId'], 'user-123');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'widgets': [
                {
                  'widget_type': 'BANNER',
                  'priority': 1,
                  'data': {'action': 'COMPLETE_SURVEY', 'title': 'Test', 'cta': 'Go'}
                },
                {
                  'widget_type': 'SUGGESTION_CARD',
                  'priority': 5,
                  'data': {'dating_goal': 'serious', 'title': 'Test Card', 'content': 'Content'}
                }
              ]
            }
          }),
          200,
        );
      });

      final service = HomeService(apiClient: ApiClient(client: mockClient));
      final widgets = await service.fetchHomeContent('user-123');

      expect(widgets.length, 2);
      expect(widgets[0].widgetType, 'BANNER');
      expect(widgets[1].widgetType, 'SUGGESTION_CARD');
    });

    test('sort widgets by priority ascending', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'widgets': [
                {'widget_type': 'SUGGESTION_CARD', 'priority': 5, 'data': {}},
                {'widget_type': 'BANNER', 'priority': 1, 'data': {}},
                {'widget_type': 'DISCOVERY_CARD', 'priority': 4, 'data': {}}
              ]
            }
          }),
          200,
        );
      });

      final service = HomeService(apiClient: ApiClient(client: mockClient));
      final widgets = await service.fetchHomeContent('user-123');

      expect(widgets[0].priority, 1);
      expect(widgets[1].priority, 4);
      expect(widgets[2].priority, 5);
    });

    test('throw on success=false response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'success': false, 'error': 'Server error'}), 500);
      });

      final service = HomeService(apiClient: ApiClient(client: mockClient));
      expect(() => service.fetchHomeContent('user-123'), throwsException);
    });

    test('handle empty widgets array', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': {'widgets': []}}), 200);
      });

      final service = HomeService(apiClient: ApiClient(client: mockClient));
      final widgets = await service.fetchHomeContent('user-123');
      expect(widgets, isEmpty);
    });

    test('handle missing widgets key in response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      });

      final service = HomeService(apiClient: ApiClient(client: mockClient));
      final widgets = await service.fetchHomeContent('user-123');
      expect(widgets, isEmpty);
    });
  });
}
```

#### 4.1.2 Unit Tests - HomeViewModel

**File:** `Bondy_App/test/viewmodels/home_viewmodel_test.dart`

```dart
// EXISTING test already covers error state
// ADD these tests:

test('HomeLoaded state contains sorted widgets', () async {
  final mockService = _MockHomeService(mockWidgets: [
    HomeWidget(widgetType: 'SUGGESTION_CARD', priority: 5, data: {}),
    HomeWidget(widgetType: 'BANNER', priority: 1, data: {}),
  ]);
  final viewModel = HomeViewModel(service: mockService);

  await viewModel.loadContent('user-123');

  expect(viewModel.state, isA<HomeLoaded>());
  final loaded = viewModel.state as HomeLoaded;
  expect(loaded.widgets[0].priority, 1);
  expect(loaded.widgets[1].priority, 5);
});

test('refresh reloads content', () async {
  final mockService = _MockHomeService();
  var loadCount = 0;
  mockService.fetchHomeContentCallback = () {
    loadCount++;
    return Future.value([
      HomeWidget(widgetType: 'BANNER', priority: 1, data: {}),
    ]);
  };
  final viewModel = HomeViewModel(service: mockService);

  await viewModel.loadContent('user-123');
  await viewModel.refresh('user-123');

  expect(loadCount, 2);
});
```

#### 4.1.3 Widget Tests - Individual Widget Renderers

**File to create:** `Bondy_App/test/widgets/home/widgets_test.dart`

```dart
import 'package:bondy/widgets/home/banner_widget.dart';
import 'package:bondy/widgets/home/suggestion_card_widget.dart';
import 'package:bondy/widgets/home/emotion_checkin_widget.dart';
import 'package:bondy/widgets/home/milestone_reminder_widget.dart';
import 'package:bondy/widgets/home/discovery_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BannerWidget', () {
    testWidgets('renders title and CTA from data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerWidget(data: {
              'action': 'COMPLETE_SURVEY',
              'title': 'Complete your survey',
              'cta': 'Start now',
            }),
          ),
        ),
      );

      expect(find.text('Complete your survey'), findsOneWidget);
      expect(find.text('Start now'), findsOneWidget);
    });

    testWidgets('navigates to survey on CTA tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: BannerWidget(data: {
              'action': 'COMPLETE_SURVEY',
              'title': 'Test',
              'cta': 'Go',
            }),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(navigatorKey.currentState?.currentRoute, '/survey/intro');
    });
  });

  group('SuggestionCardWidget', () {
    testWidgets('renders title and content from data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCardWidget(data: {
              'dating_goal': 'serious',
              'title': 'Build lasting love',
              'content': 'Share what you appreciate most.',
            }),
          ),
        ),
      );

      expect(find.text('Build lasting love'), findsOneWidget);
      expect(find.text('Share what you appreciate most.'), findsOneWidget);
    });

    testWidgets('shows DAILY INSPIRATION label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCardWidget(data: {
              'title': 'Title',
              'content': 'Content',
            }),
          ),
        ),
      );

      expect(find.text('DAILY INSPIRATION'), findsOneWidget);
    });
  });

  group('EmotionCheckinWidget', () {
    testWidgets('renders partner name from data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionCheckinWidget(data: {
              'relationship_id': 'rel-123',
              'partner_name': 'Minh',
            }),
          ),
        ),
      );

      expect(find.text('Bạn đang cảm thấy thế nào với Minh?'), findsOneWidget);
    });

    testWidgets('renders 4 mood options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmotionCheckinWidget(data: {
              'relationship_id': 'rel-123',
              'partner_name': 'Partner',
            }),
          ),
        ),
      );

      expect(find.text('Vui'), findsOneWidget);
      expect(find.text('Bình yên'), findsOneWidget);
      expect(find.text('Buồn'), findsOneWidget);
      expect(find.text('Lo lắng'), findsOneWidget);
    });
  });

  group('MilestoneReminderWidget', () {
    testWidgets('renders days_left badge correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneReminderWidget(data: {
              'title': 'Anniversary',
              'date': '2026-05-20',
              'days_left': 3,
            }),
          ),
        ),
      );

      expect(find.text('Còn 3 ngày'), findsOneWidget);
    });

    testWidgets('renders "Hôm nay!" for days_left=0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneReminderWidget(data: {
              'title': 'Today',
              'date': '2026-05-14',
              'days_left': 0,
            }),
          ),
        ),
      );

      expect(find.text('Hôm nay!'), findsOneWidget);
    });
  });

  group('DiscoveryCardWidget', () {
    testWidgets('renders profiles from data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryCardWidget(data: {
              'profiles': [
                {'user_id': 'u1', 'name': 'Alice', 'city': 'Hanoi', 'common_interests': ['Music']},
                {'user_id': 'u2', 'name': 'Bob', 'city': 'HCMC', 'common_interests': ['Travel']},
              ]
            }),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('renders empty state when no profiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryCardWidget(data: {'profiles': []}),
          ),
        ),
      );

      expect(find.text('Thêm sở thích vào profile để Bondy gợi ý tốt hơn 🎯'), findsOneWidget);
    });
  });
}
```

#### 4.1.4 Integration Test - Full Home Screen Flow

**File to create:** `Bondy_App/test/integration/home_screen_test.dart`

```dart
import 'package:bondy/services/api_client.dart';
import 'package:bondy/services/home_service.dart';
import 'package:bondy/viewmodels/home/home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('HomeViewModel loads widgets and exposes sorted list', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'widgets': [
              {'widget_type': 'BANNER', 'priority': 1, 'data': {'action': 'COMPLETE_SURVEY', 'title': 'Title', 'cta': 'CTA'}},
              {'widget_type': 'SUGGESTION_CARD', 'priority': 5, 'data': {'dating_goal': 'serious', 'title': 'Card', 'content': 'Content'}},
            ]
          }
        }),
        200,
      );
    });

    final apiClient = ApiClient(client: mockClient);
    final service = HomeService(apiClient: apiClient);
    final viewModel = HomeViewModel(service: service);

    await viewModel.loadContent('user-123');

    expect(viewModel.state, isA<HomeLoaded>());
    final loaded = viewModel.state as HomeLoaded;
    expect(loaded.widgets.length, 2);
    expect(loaded.widgets[0].widgetType, 'BANNER');
    expect(loaded.widgets[1].widgetType, 'SUGGESTION_CARD');
  });
}
```

### 4.2 Backend Testing

#### 4.2.1 Unit Tests - HomeService

**File to create:** `bondy_server/src/__tests__/home.service.test.ts`

```typescript
import { HomeService } from '../service/home.service';
import { HomeRepository } from '../repository/home.repository';

// Mock the repository
jest.mock('../repository/home.repository');

describe('HomeService', () => {
  let homeService: HomeService;
  let mockRepo: jest.Mocked<HomeRepository>;

  beforeEach(() => {
    mockRepo = new HomeRepository() as jest.Mocked<HomeRepository>;
    homeService = new HomeService();
    (homeService as any).repository = mockRepo;
  });

  describe('Rule 1: No onboarding survey', () => {
    it('should return BANNER widget when survey not completed', async () => {
      mockRepo.checkOnboardingSurveyCompleted = jest.fn().mockResolvedValue(false);

      const result = await homeService.buildHomeContent('user-123');

      expect(result.widgets).toContainEqual(
        expect.objectContaining({
          widget_type: 'BANNER',
          priority: 1,
          data: expect.objectContaining({
            action: 'COMPLETE_SURVEY',
          }),
        })
      );
    });

    it('should NOT return BANNER when survey completed', async () => {
      mockRepo.checkOnboardingSurveyCompleted = jest.fn().mockResolvedValue(true);

      const result = await homeService.buildHomeContent('user-123');

      const bannerWidget = result.widgets.find(w => w.widget_type === 'BANNER');
      expect(bannerWidget).toBeUndefined();
    });
  });

  describe('Rule 2: Emotion checkin for active relationship', () => {
    it('should return EMOTION_CHECKIN when relationship exists and no checkin today', async () => {
      mockRepo.checkOnboardingSurveyCompleted = jest.fn().mockResolvedValue(true);
      mockRepo.getActiveRelationship = jest.fn().mockResolvedValue({
        id: 'rel-123',
        partnerId: 'partner-456',
        partnerName: 'Minh',
      });
      mockRepo.hasTodayCheckin = jest.fn().mockResolvedValue(false);

      const result = await homeService.buildHomeContent('user-123');

      expect(result.widgets).toContainEqual(
        expect.objectContaining({
          widget_type: 'EMOTION_CHECKIN',
          data: expect.objectContaining({
            relationship_id: 'rel-123',
            partner_name: 'Minh',
          }),
        })
      );
    });

    it('should NOT return EMOTION_CHECKIN when already checked in today', async () => {
      mockRepo.checkOnboardingSurveyCompleted = jest.fn().mockResolvedValue(true);
      mockRepo.getActiveRelationship = jest.fn().mockResolvedValue({
        id: 'rel-123',
        partnerId: 'partner-456',
        partnerName: 'Minh',
      });
      mockRepo.hasTodayCheckin = jest.fn().mockResolvedValue(true);

      const result = await homeService.buildHomeContent('user-123');

      const checkinWidget = result.widgets.find(w => w.widget_type === 'EMOTION_CHECKIN');
      expect(checkinWidget).toBeUndefined();
    });
  });

  describe('Rule 4: Discovery card for solo mode', () => {
    it('should return DISCOVERY_CARD when mode=solo', async () => {
      mockRepo.checkOnboardingSurveyCompleted = jest.fn().mockResolvedValue(true);
      mockRepo.getActiveRelationship = jest.fn().mockResolvedValue(null);
      mockRepo.getLatestSurveyModeCode = jest.fn().mockResolvedValue('solo');
      mockRepo.getMatchCount = jest.fn().mockResolvedValue(0);
      mockRepo.getDiscoveryProfiles = jest.fn().mockResolvedValue([
        { id: 'u1', name: 'Alice', city: 'Hanoi', commonInterests: ['Music'] },
      ]);

      const result = await homeService.buildHomeContent('user-123');

      expect(result.widgets).toContainEqual(
        expect.objectContaining({
          widget_type: 'DISCOVERY_CARD',
          data: expect.objectContaining({
            profiles: expect.arrayContaining([
              expect.objectContaining({ name: 'Alice' }),
            ]),
          }),
        })
      );
    });
  });

  describe('Rule 5: Suggestion card (always present)', () => {
    it('should always return SUGGESTION_CARD as last widget', async () => {
      mockRepo.checkOnboardingSurveyCompleted = jest.fn().mockResolvedValue(true);
      mockRepo.getActiveRelationship = jest.fn().mockResolvedValue(null);
      mockRepo.getLatestSurveyModeCode = jest.fn().mockResolvedValue('couple');
      mockRepo.getMatchCount = jest.fn().mockResolvedValue(5);
      mockRepo.getDatingGoal = jest.fn().mockResolvedValue('serious');

      const result = await homeService.buildHomeContent('user-123');

      const suggestionWidget = result.widgets.find(w => w.widget_type === 'SUGGESTION_CARD');
      expect(suggestionWidget).toBeDefined();
      expect(suggestionWidget?.priority).toBe(result.widgets.length);
    });

    it('should use dating_goal to set title and content', async () => {
      mockRepo.checkOnboardingSurveyCompleted = jest.fn().mockResolvedValue(true);
      mockRepo.getActiveRelationship = jest.fn().mockResolvedValue(null);
      mockRepo.getLatestSurveyModeCode = jest.fn().mockResolvedValue('couple');
      mockRepo.getMatchCount = jest.fn().mockResolvedValue(5);
      mockRepo.getDatingGoal = jest.fn().mockResolvedValue('serious');

      const result = await homeService.buildHomeContent('user-123');

      const suggestionWidget = result.widgets.find(w => w.widget_type === 'SUGGESTION_CARD');
      expect(suggestionWidget?.data).toMatchObject({
        dating_goal: 'serious',
        title: 'Xây dựng tình yêu bền vững 💑',
      });
    });
  });
});
```

#### 4.2.2 Integration Tests - API Route

**File to create:** `bondy_server/src/__tests__/home.content.route.test.ts`

```typescript
import { NextRequest } from 'next/server';

// Mock home service
jest.mock('../service/home.service', () => ({
  homeService: {
    buildHomeContent: jest.fn().mockResolvedValue({
      widgets: [
        { widget_type: 'BANNER', priority: 1, data: { action: 'COMPLETE_SURVEY', title: 'Test', cta: 'Go' } },
      ],
    }),
  },
}));

describe('GET /api/home/content', () => {
  it('returns 400 when userId is missing', async () => {
    const req = new NextRequest('http://localhost:3000/api/home/content');
    const response = await GET(req);

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body.success).toBe(false);
    expect(body.error).toBe('Thiếu userId.');
  });

  it('returns 400 when userId is empty', async () => {
    const req = new NextRequest('http://localhost:3000/api/home/content?userId=');
    const response = await GET(req);

    expect(response.status).toBe(400);
  });

  it('returns 200 with widgets for valid userId', async () => {
    const req = new NextRequest('http://localhost:3000/api/home/content?userId=user-123');
    const response = await GET(req);

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.success).toBe(true);
    expect(body.data.widgets).toBeDefined();
    expect(Array.isArray(body.data.widgets)).toBe(true);
  });

  it('returns 500 on service error', async () => {
    const { homeService } = require('../service/home.service');
    homeService.buildHomeContent = jest.fn().mockRejectedValue(new Error('DB error'));

    const req = new NextRequest('http://localhost:3000/api/home/content?userId=user-123');
    const response = await GET(req);

    expect(response.status).toBe(500);
    const body = await response.json();
    expect(body.success).toBe(false);
  });
});
```

#### 4.2.3 Repository Tests with Prisma Mock

**File to create:** `bondy_server/src/__tests__/home.repository.test.ts`

```typescript
import { HomeRepository } from '../repository/home.repository';
import prisma from '../lib/prisma';

jest.mock('../lib/prisma');

describe('HomeRepository', () => {
  let repo: HomeRepository;

  beforeEach(() => {
    repo = new HomeRepository();
    jest.clearAllMocks();
  });

  describe('checkOnboardingSurveyCompleted', () => {
    it('returns true when completed submission exists', async () => {
      (prisma.userSurveySubmission.findFirst as jest.Mock).mockResolvedValue({
        id: 'sub-123',
        status: 'SUBMITTED',
      });

      const result = await repo.checkOnboardingSurveyCompleted('user-123');

      expect(result).toBe(true);
    });

    it('returns false when no submission exists', async () => {
      (prisma.userSurveySubmission.findFirst as jest.Mock).mockResolvedValue(null);

      const result = await repo.checkOnboardingSurveyCompleted('user-123');

      expect(result).toBe(false);
    });
  });

  describe('getMatchCount', () => {
    it('returns count of matches for user', async () => {
      (prisma.match.count as jest.Mock).mockResolvedValue(5);

      const result = await repo.getMatchCount('user-123');

      expect(result).toBe(5);
    });
  });

  describe('getLatestSurveyModeCode', () => {
    it('returns finalModeCode from most recent submission', async () => {
      (prisma.userSurveySubmission.findFirst as jest.Mock).mockResolvedValue({
        finalModeCode: 'solo',
      });

      const result = await repo.getLatestSurveyModeCode('user-123');

      expect(result).toBe('solo');
    });

    it('returns null when no submission exists', async () => {
      (prisma.userSurveySubmission.findFirst as jest.Mock).mockResolvedValue(null);

      const result = await repo.getLatestSurveyModeCode('user-123');

      expect(result).toBeNull();
    });
  });
});
```

---

## 5. Mock Data Approach for Flutter Testing

### 5.1 Mock Data Files

Create `Bondy_App/test/fixtures/home_widgets.dart`:

```dart
class HomeWidgetFixtures {
  static List<Map<String, dynamic>> bannerWidget() => [
    {
      'widget_type': 'BANNER',
      'priority': 1,
      'data': {
        'action': 'COMPLETE_SURVEY',
        'title': 'Hoàn thành khảo sát để Bondy hiểu bạn hơn 💬',
        'cta': 'Bắt đầu ngay',
      }
    },
  ];

  static List<Map<String, dynamic>> allWidgetsNoSurvey() => [
    ...bannerWidget(),
    {
      'widget_type': 'SUGGESTION_CARD',
      'priority': 5,
      'data': {
        'dating_goal': 'serious',
        'title': 'Xây dựng tình yêu bền vững 💑',
        'content': 'Hãy thử chia sẻ điều bạn trân trọng nhất.',
      }
    },
  ];

  static List<Map<String, dynamic>> allWidgetsWithRelationship() => [
    {
      'widget_type': 'EMOTION_CHECKIN',
      'priority': 2,
      'data': {
        'relationship_id': 'rel-456',
        'partner_name': 'Minh',
      }
    },
    {
      'widget_type': 'MILESTONE_REMINDER',
      'priority': 3,
      'data': {
        'title': 'Kỷ niệm 1 năm',
        'date': '2026-05-20',
        'days_left': 6,
      }
    },
    {
      'widget_type': 'DISCOVERY_CARD',
      'priority': 4,
      'data': {
        'profiles': [
          {'user_id': 'u1', 'name': 'Alice', 'city': 'TP.HCM', 'common_interests': ['Du lịch', 'Nấu ăn']},
        ]
      }
    },
    {
      'widget_type': 'SUGGESTION_CARD',
      'priority': 5,
      'data': {
        'dating_goal': 'casual',
        'title': 'Khám phá kết nối mới ✨',
        'content': 'Đừng ngại thử những điều mới.',
      }
    },
  ];

  static List<Map<String, dynamic>> emptyState() => [
    {
      'widget_type': 'SUGGESTION_CARD',
      'priority': 1,
      'data': {
        'dating_goal': 'general',
        'title': 'Dành riêng cho bạn hôm nay 🌸',
        'content': 'Hành trình cảm xúc của bạn quan trọng.',
      }
    },
  ];
}
```

### 5.2 Using Fixtures in Tests

```dart
import 'package:bondy/test/fixtures/home_widgets.dart';

// In test
final mockClient = MockClient((request) async {
  return http.Response(
    jsonEncode({
      'success': true,
      'data': {'widgets': HomeWidgetFixtures.allWidgetsNoSurvey()},
    }),
    200,
  );
});
```

---

## 6. Backend Model Gaps and Testing

### 6.1 Missing Prisma Models (Requires Implementation)

| Model | Purpose | Status |
|-------|---------|--------|
| Relationship | Active relationship between users | NOT IN SCHEMA |
| EmotionCheckin | Daily emotion checkin records | NOT IN SCHEMA |
| Milestone | Relationship milestone/reminder | NOT IN SCHEMA |

### 6.2 Repository Methods with Gaps

**File:** `bondy_server/src/repository/home.repository.ts`

| Method | Current Implementation | Gap |
|--------|------------------------|-----|
| `getActiveRelationship` | Returns `null` (line 32) | Must query Relationship table |
| `hasTodayCheckin` | Returns `false` (line 39) | Must query EmotionCheckin table |
| `getUpcomingMilestone` | Returns `null` (line 50) | Must query Milestone table |

### 6.3 Testing Gap Coverage

For each gap, create tests that verify behavior once models are implemented:

```typescript
// Example test structure for future implementation
describe('Relationship queries (TODO: after schema update)', () => {
  it('getActiveRelationship returns relationship with partner info', async () => {
    // TODO: After Relationship model is added
    // mock prisma.relationship.findFirst to return { id, partnerId, partner: { profile: { fullName } } }
  });

  it('hasTodayCheckin returns true when checkin exists for today', async () => {
    // TODO: After EmotionCheckin model is added
  });

  it('getUpcomingMilestone returns milestone within 7 days', async () => {
    // TODO: After Milestone model is added
  });
});
```

---

## 7. Design Verification Checklist

### 7.1 Visual Verification Points

| Widget | Design Element | Expected Value |
|--------|---------------|----------------|
| BannerWidget | Background | LinearGradient #FF8A65 to #E91E63 |
| BannerWidget | Border radius | 20px |
| BannerWidget | Shadow | pink-tinted, blur 16px, offset (0,6) |
| SuggestionCardWidget | Background | LinearGradient #FFB3A7 to #AE8FDB |
| SuggestionCardWidget | CTA style | gradient orange-pink, rounded 30px |
| EmotionCheckinWidget | Container | white with #FFE0E6 border |
| MilestoneReminderWidget | Background | LinearGradient #FFF3E0 to #FFE0B2 |
| DiscoveryCardWidget | Profile chip width | 130px |
| All cards | No 1px borders | Use background shifts per "No-Line Rule" |

### 7.2 Typography Verification

| Element | Font | Size | Weight |
|---------|------|------|--------|
| Banner title | Plus Jakarta Sans | 15px | w700 |
| Suggestion title | Plus Jakarta Sans | 20px | w800 |
| Widget section headers | Plus Jakarta Sans | 17px | w700 |
| Body text | Inter | 13px | regular |

### 7.3 Spacing Verification

| Context | Margin/Padding |
|---------|---------------|
| Card horizontal margin | 20px |
| Card vertical margin | 8px |
| Card internal padding | 20px |
| Between sections | spacing-6 (2rem) |

### 7.4 Animation Verification

| Element | Animation |
|---------|-----------|
| Page transitions | ease-in-out cubic-bezier (0.4, 0, 0.2, 1) |
| Mood chips | tap feedback with SnackBar |

---

## 8. Rollback Plan

### 8.1 Flutter Rollback

**Trigger:** Home screen crashes, data fails to load, or visual regression exceeds threshold.

**Steps:**
1. Revert `Bondy_App/lib/screens/home/main_shell_screen.dart` to previous working version
2. Revert widget files if needed:
   - `lib/widgets/home/banner_widget.dart`
   - `lib/widgets/home/suggestion_card_widget.dart`
   - `lib/widgets/home/emotion_checkin_widget.dart`
   - `lib/widgets/home/milestone_reminder_widget.dart`
   - `lib/widgets/home/discovery_card_widget.dart`
3. Revert `lib/services/home_service.dart`
4. Revert `lib/viewmodels/home/home_viewmodel.dart`
5. Run `flutter test` to verify tests pass
6. Push revert commit

**Command:**
```bash
git checkout HEAD~1 -- Bondy_App/lib/screens/home/ Bondy_App/lib/widgets/home/ Bondy_App/lib/services/home_service.dart Bondy_App/lib/viewmodels/home/home_viewmodel.dart
git commit -m "revert: rollback home screen to stable version"
git push
```

### 8.2 Backend Rollback

**Trigger:** API returns errors, causes 500 on home/content endpoint.

**Steps:**
1. Revert `bondy_server/src/app/api/home/content/route.ts`
2. Revert `bondy_server/src/service/home.service.ts`
3. Revert `bondy_server/src/repository/home.repository.ts`
4. Run backend tests
5. Push revert commit

**Command:**
```bash
git checkout HEAD~1 -- bondy_server/src/app/api/home/ bondy_server/src/service/home.service.ts bondy_server/src/repository/home.repository.ts
git commit -m "revert: rollback home API to stable version"
git push
```

### 8.3 Feature Flag Approach (Recommended for Future)

Wrap new behavior in feature flags:

```typescript
// In home.service.ts
const FEATURE_NEW_HOME_LOGIC = process.env.FEATURE_NEW_HOME_LOGIC === 'true';

if (FEATURE_NEW_HOME_LOGIC) {
  // new implementation
} else {
  // old implementation / fallback
}
```

---

## 9. Test Execution Commands

### 9.1 Flutter Tests

```bash
cd Bondy_App

# Run all home-related tests
flutter test test/services/home_service_test.dart
flutter test test/viewmodels/home_viewmodel_test.dart
flutter test test/widgets/home/

# Run integration test
flutter test test/integration/home_screen_test.dart

# Run all tests
flutter test
```

### 9.2 Backend Tests

```bash
cd bondy_server

# Run home service tests
npm test -- --testPathPattern="home.service"

# Run home repository tests
npm test -- --testPathPattern="home.repository"

# Run API route tests
npm test -- --testPathPattern="home.content.route"

# Run all tests
npm test
```

---

## 10. Test File Locations Summary

| Test Type | Flutter Location | Backend Location |
|-----------|------------------|------------------|
| Unit - Service | `Bondy_App/test/services/home_service_test.dart` (new) | `bondy_server/src/__tests__/home.service.test.ts` (new) |
| Unit - ViewModel | `Bondy_App/test/viewmodels/home_viewmodel_test.dart` (exists, extend) | N/A |
| Unit - Repository | N/A | `bondy_server/src/__tests__/home.repository.test.ts` (new) |
| Widget | `Bondy_App/test/widgets/home/widgets_test.dart` (new) | N/A |
| Integration | `Bondy_App/test/integration/home_screen_test.dart` (new) | `bondy_server/src/__tests__/home.content.route.test.ts` (new) |
| Fixtures | `Bondy_App/test/fixtures/home_widgets.dart` (new) | N/A |

---

## 11. Success Criteria

- [ ] Flutter HomeService correctly parses all 5 widget types
- [ ] Widgets sorted by priority ascending
- [ ] BannerWidget renders with gradient and navigation
- [ ] EmotionCheckinWidget renders partner name and 4 moods
- [ ] MilestoneReminderWidget renders days_left badge
- [ ] DiscoveryCardWidget renders profile list or empty state
- [ ] SuggestionCardWidget renders with DAILY INSPIRATION label
- [ ] HomeViewModel state transitions: Loading -> Loaded (success) or Loading -> Error (failure)
- [ ] Backend returns 200 with correct widget structure
- [ ] Backend returns 400 for missing userId
- [ ] Backend returns 500 on internal errors
- [ ] Design matches DESIGN.md: no 1px borders, gradient backgrounds, Plus Jakarta Sans typography
- [ ] All new tests pass
- [ ] No regression in existing tests