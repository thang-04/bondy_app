# AI Provider Abstraction Design

**Issue:** bondy-711  
**Status:** Approved  
**Date:** 2026-05-12

---

## 1. Overview

Tạo service AI có interface provider abstraction. Sprint này dùng MockAiProvider, phase sau đổi Gemini/OpenAI. API AI chạy được không phụ thuộc provider thật. Tránh hard-code prompt/provider trong route handler.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     API Route Layer                         │
│              POST /api/ai/conversation-suggest             │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                  AiService                                  │
│  - calls checkFeature(userId) before generate               │
│  - calls consumeFeature(userId) after success               │
│  - builds context                                           │
│  - saves AiSuggestion record                                │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│              IAiProvider (interface)                        │
├─────────────────────────────────────────────────────────────┤
│  AbstractAiProvider (base)                                 │
│    - Retry logic (1-2 retries)                              │
│    - Timeout (30s default)                                 │
│    - Circuit breaker pattern                                │
│    - OtelWrapper for observability                          │
└──────┬──────────────────┬──────────────────┬───────────────┘
       │                  │                  │
┌──────▼──────┐   ┌───────▼───────┐  ┌──────▼──────┐
│ MockAI      │   │ GeminiAI      │  │ OpenAI      │
│ Provider    │   │ Provider      │  │ Provider    │
│ (Sprint 2)  │   │ (Phase 2)     │  │ (Phase 2)   │
└─────────────┘   └───────────────┘  └─────────────┘
```

---

## 3. Interface Contract

### IAiProvider

```typescript
interface AiResponse {
  text: string;
  tokensUsed: number;
  latencyMs: number;
  provider: string;
}

interface AiStructuredResponse<T> {
  data: T;
  tokensUsed: number;
  latencyMs: number;
  provider: string;
}

interface GenerateOptions {
  temperature?: number;    // 0.0-1.0, default 0.7
  maxTokens?: number;      // default 500
  topP?: number;           // default 1.0
  stopSequences?: string[];
}

interface IAiProvider {
  // Core generate
  generate(prompt: string, options?: GenerateOptions): Promise<AiResponse>;
  
  // Streaming (for UX)
  generateStream(prompt: string, options?: GenerateOptions): AsyncGenerator<AiResponse>;
  
  // Structured output (for suggestions)
  generateStructured<T>(
    prompt: string, 
    schema: object, 
    options?: GenerateOptions
  ): Promise<AiStructuredResponse<T>>;
  
  // Health check
  healthCheck(): Promise<boolean>;
}
```

### Provider Factory

```typescript
type ProviderType = 'mock' | 'gemini' | 'openai';

interface ProviderConfig {
  apiKey?: string;
  model?: string;
  timeoutMs?: number;
  maxRetries?: number;
}

function createProvider(type: ProviderType, config: ProviderConfig): IAiProvider;
```

---

## 4. Error Handling Strategy

```
Request → 
  Try 1 (timeout 30s) → Fail?
    → Try 2 (timeout 30s) → Fail?
      → Circuit breaker check
        → If OPEN: throw FeatureGatedError(LIMIT_REACHED)
        → If CLOSED: Circuit breaker increments, throw error
```

### Circuit Breaker Config
- **Failure threshold:** 5 failures within 1 minute → OPEN
- **Recovery timeout:** 30 seconds → HALF_OPEN
- **Half-open:** Allow 1 request to test

### Error Types
```typescript
class AiProviderError extends Error {
  provider: string;
  retryable: boolean;
  code: 'TIMEOUT' | 'RATE_LIMIT' | 'INVALID_API_KEY' | 'CIRCUIT_OPEN' | 'UNKNOWN';
}
```

---

## 5. Observability (OtelWrapper)

All providers use OtelWrapper for consistent observability.

```typescript
interface IObservabilityService {
  // Span management
  startSpan(name: string, attrs?: Record<string, string>): Span;
  endSpan(span: Span): void;
  recordException(span: Span, error: Error): void;
  
  // Metrics
  recordLatency(metric: string, ms: number, attrs?: Record<string, string>): void;
  recordTokens(provider: string, tokens: number): void;
  recordRequest(provider: string, success: boolean): void;
  
  // Logging
  logRequest(provider: string, prompt: string, response?: string): void;
}
```

### Metrics Tracked
| Metric | Type | Tags |
|--------|------|------|
| `ai.request.count` | Counter | provider, status |
| `ai.request.latency` | Histogram | provider |
| `ai.tokens.used` | Counter | provider |
| `ai.circuitbreaker.state` | Gauge | provider |

### Logs
- Structured JSON logs
- Request/response correlation via traceId
- Log levels: ERROR, WARN, INFO, DEBUG

---

## 6. Provider Implementations

### MockAiProvider (Sprint 2)
- Returns predefined suggestions per intent
- Configurable delay via `MOCK_AI_DELAY_MS`
- Configurable error rate via `MOCK_AI_ERROR_RATE`
- No real API calls, fast for testing

### GeminiAiProvider (Phase 2)
- Uses `@google/generative-ai` SDK
- Maps `generate()` → `model.generateContent()`
- Maps `generateStructured()` → `model.generateContent()` + JSON parsing
- Streaming: `model.generateContentStream()`

### OpenAiProvider (Phase 2)
- Uses `openai` SDK
- Maps `generate()` → `openai.chat.completions.create()`
- Maps `generateStructured()` → function calling or JSON mode
- Streaming: `stream` parameter

---

## 7. File Structure

```
src/
  service/
    ai.service.ts              # AiService (orchestration)
  interface/
    ai-provider.interface.ts   # IAiProvider, types
  abstract/
    abstract-ai-provider.ts     # AbstractAiProvider (retry, timeout, circuit breaker)
  provider/
    mock-ai.provider.ts        # MockAiProvider (Sprint 2)
    gemini-ai.provider.ts      # GeminiAiProvider (Phase 2)
    openai-ai.provider.ts      # OpenAiProvider (Phase 2)
  factory/
    ai-provider.factory.ts     # createProvider()
  wrapper/
    otel-wrapper.ts            # OtelWrapper (self-built, OTEL SDK)
  config/
    ai-provider.config.ts      # ProviderConfig, env vars
```

---

## 8. Environment Variables

```bash
# Provider selection
AI_PROVIDER_TYPE=mock|gemini|openai

# Mock config
MOCK_AI_DELAY_MS=500
MOCK_AI_ERROR_RATE=0

# Gemini config
GEMINI_API_KEY=your_key
GEMINI_MODEL=gemini-pro

# OpenAI config
OPENAI_API_KEY=your_key
OPENAI_MODEL=gpt-4o

# Shared config
AI_TIMEOUT_MS=30000
AI_MAX_RETRIES=2
```

---

## 9. Testing Strategy

### Unit Tests
- MockAiProvider: deterministic responses
- Circuit breaker state transitions
- Retry logic

### Integration Tests
- Each provider with real API (when API key available)
- Mock for CI/CD

### Contract Tests
- All providers implement IAiProvider contract
- Same test cases for all providers

---

## 10. Dependencies

```json
{
  "@google/generative-ai": "latest",  // Gemini
  "openai": "latest",                // OpenAI
  "@opentelemetry/sdk-node": "latest",
  "@opentelemetry/api": "latest",
  "@opentelemetry/exporter-trace-otlp-http": "latest",
  "@opentelemetry/exporter-metrics-otlp-http": "latest"
}
```

**Note:** Dependencies added only when implementing real providers. Sprint 2 uses MockAiProvider only.

---

## 11. Success Criteria

- [ ] IAiProvider interface defined
- [ ] AbstractAiProvider with retry, timeout, circuit breaker
- [ ] MockAiProvider working (Sprint 2)
- [ ] OtelWrapper implemented
- [ ] Factory creates correct provider
- [ ] API route uses provider abstraction (not hard-coded)
- [ ] Unit tests pass
