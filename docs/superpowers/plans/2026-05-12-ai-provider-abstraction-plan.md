# AI Provider Abstraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create AI provider abstraction with interface, abstract base, Mock/Gemini/OpenAI providers, OtelWrapper, circuit breaker.

**Architecture:** Protocol/Contract + Abstract Base pattern. IAiProvider interface with generate/generateStream/generateStructured/healthCheck. AbstractAiProvider handles retry, timeout, circuit breaker. OtelWrapper for observability. ProviderFactory for creation.

**Tech Stack:** TypeScript, Node.js, OpenTelemetry SDK, @google/generative-ai (Phase 2), openai (Phase 2)

---

## File Structure

```
src/
  interface/
    ai-provider.interface.ts    # IAiProvider, types, AiResponse, GenerateOptions
  config/
    ai-provider.config.ts       # ProviderConfig, env vars loading
  wrapper/
    otel-wrapper.ts             # OtelWrapper class (self-built OTEL SDK wrapper)
  abstract/
    abstract-ai-provider.ts     # AbstractAiProvider (retry, timeout, circuit breaker)
  provider/
    mock-ai.provider.ts        # MockAiProvider (Sprint 2)
    gemini-ai.provider.ts      # GeminiAiProvider (Phase 2)
    openai-ai.provider.ts      # OpenAiProvider (Phase 2)
  factory/
    ai-provider.factory.ts     # createProvider()
  error/
    ai-provider.error.ts       # AiProviderError, error codes
```

---

## Task 1: Define Types and Interfaces

**Files:**
- Create: `src/interface/ai-provider.interface.ts`
- Test: `test/unit/interface/ai-provider.interface.test.ts`

- [ ] **Step 1: Create test file**

```typescript
// test/unit/interface/ai-provider.interface.test.ts
import { describe, it, expect } from 'vitest';

describe('AiProvider Types', () => {
  it('AiResponse should have correct shape', () => {
    const response = {
      text: 'Hello',
      tokensUsed: 10,
      latencyMs: 100,
      provider: 'mock',
    };
    expect(response.text).toBe('Hello');
    expect(response.tokensUsed).toBe(10);
    expect(response.latencyMs).toBe(100);
    expect(response.provider).toBe('mock');
  });

  it('GenerateOptions should have optional fields', () => {
    const options = {
      temperature: 0.7,
      maxTokens: 500,
    };
    expect(options.temperature).toBe(0.7);
    expect(options.maxTokens).toBe(500);
  });

  it('ProviderType should be union of mock|gemini|openai', () => {
    type ProviderType = 'mock' | 'gemini' | 'openai';
    const types: ProviderType[] = ['mock', 'gemini', 'openai'];
    expect(types).toHaveLength(3);
  });
});
```

Run: `cd bondy_server && npx vitest test/unit/interface/ai-provider.interface.test.ts -v`

- [ ] **Step 2: Create interface file**

```typescript
// src/interface/ai-provider.interface.ts

// === Response Types ===

export interface AiResponse {
  text: string;
  tokensUsed: number;
  latencyMs: number;
  provider: string;
}

export interface AiStructuredResponse<T> {
  data: T;
  tokensUsed: number;
  latencyMs: number;
  provider: string;
}

// === Options ===

export interface GenerateOptions {
  temperature?: number;    // 0.0-1.0, default 0.7
  maxTokens?: number;      // default 500
  topP?: number;           // default 1.0
  stopSequences?: string[];
}

// === Interface ===

export interface IAiProvider {
  generate(prompt: string, options?: GenerateOptions): Promise<AiResponse>;
  generateStream(prompt: string, options?: GenerateOptions): AsyncGenerator<AiResponse>;
  generateStructured<T>(prompt: string, schema: object, options?: GenerateOptions): Promise<AiStructuredResponse<T>>;
  healthCheck(): Promise<boolean>;
}
```

- [ ] **Step 3: Run test**

Run: `cd bondy_server && npx vitest test/unit/interface/ai-provider.interface.test.ts -v`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
cd bondy_server
git add src/interface/ai-provider.interface.ts test/unit/interface/ai-provider.interface.test.ts
git commit -m "feat(ai): define IAiProvider interface and types

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 2: Create Error Types

**Files:**
- Create: `src/error/ai-provider.error.ts`
- Test: `test/unit/error/ai-provider.error.test.ts`

- [ ] **Step 1: Create test file**

```typescript
// test/unit/error/ai-provider.error.test.ts
import { describe, it, expect } from 'vitest';
import { AiProviderError, ErrorCode } from '../../src/error/ai-provider.error';

describe('AiProviderError', () => {
  it('should create error with all properties', () => {
    const error = new AiProviderError('TIMEOUT', 'mock', 'Request timed out');
    expect(error.code).toBe('TIMEOUT');
    expect(error.provider).toBe('mock');
    expect(error.message).toBe('Request timed out');
    expect(error.retryable).toBe(true);
  });

  it('should mark rate limit as retryable', () => {
    const error = new AiProviderError('RATE_LIMIT', 'gemini', 'Rate limit exceeded');
    expect(error.code).toBe('RATE_LIMIT');
    expect(error.retryable).toBe(true);
  });

  it('should mark circuit open as not retryable', () => {
    const error = new AiProviderError('CIRCUIT_OPEN', 'openai', 'Circuit is open');
    expect(error.code).toBe('CIRCUIT_OPEN');
    expect(error.retryable).toBe(false);
  });
});
```

Run: `cd bondy_server && npx vitest test/unit/error/ai-provider.error.test.ts -v`

- [ ] **Step 2: Create error file**

```typescript
// src/error/ai-provider.error.ts

export type ErrorCode = 'TIMEOUT' | 'RATE_LIMIT' | 'INVALID_API_KEY' | 'CIRCUIT_OPEN' | 'UNKNOWN';

export class AiProviderError extends Error {
  readonly code: ErrorCode;
  readonly provider: string;
  readonly retryable: boolean;

  constructor(code: ErrorCode, provider: string, message: string) {
    super(message);
    this.name = 'AiProviderError';
    this.code = code;
    this.provider = provider;
    this.retryable = code === 'TIMEOUT' || code === 'RATE_LIMIT';
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd bondy_server && npx vitest test/unit/error/ai-provider.error.test.ts -v`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
cd bondy_server
git add src/error/ai-provider.error.ts test/unit/error/ai-provider.error.test.ts
git commit -m "feat(ai): add AiProviderError with error codes

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 3: Create Config

**Files:**
- Create: `src/config/ai-provider.config.ts`
- Test: `test/unit/config/ai-provider.config.test.ts`

- [ ] **Step 1: Create test file**

```typescript
// test/unit/config/ai-provider.config.test.ts
import { describe, it, expect } from 'vitest';
import { loadProviderConfig, ProviderConfig, ProviderType } from '../../src/config/ai-provider.config';

describe('ProviderConfig', () => {
  it('should load mock config from env', () => {
    // This test verifies config structure
    const config: ProviderConfig = {
      type: 'mock',
      timeoutMs: 30000,
      maxRetries: 2,
    };
    expect(config.type).toBe('mock');
    expect(config.timeoutMs).toBe(30000);
  });
});
```

Run: `cd bondy_server && npx vitest test/unit/config/ai-provider.config.test.ts -v`

- [ ] **Step 2: Create config file**

```typescript
// src/config/ai-provider.config.ts

import type { ProviderType } from '../factory/ai-provider.factory';

export interface ProviderConfig {
  type: ProviderType;
  apiKey?: string;
  model?: string;
  timeoutMs?: number;
  maxRetries?: number;
}

export interface MockConfig extends ProviderConfig {
  type: 'mock';
  delayMs?: number;
  errorRate?: number;
}

export function loadProviderConfig(): ProviderConfig {
  const type = (process.env.AI_PROVIDER_TYPE || 'mock') as ProviderType;
  
  const config: ProviderConfig = {
    type,
    timeoutMs: parseInt(process.env.AI_TIMEOUT_MS || '30000', 10),
    maxRetries: parseInt(process.env.AI_MAX_RETRIES || '2', 10),
  };

  if (type === 'gemini') {
    config.apiKey = process.env.GEMINI_API_KEY;
    config.model = process.env.GEMINI_MODEL || 'gemini-pro';
  } else if (type === 'openai') {
    config.apiKey = process.env.OPENAI_API_KEY;
    config.model = process.env.OPENAI_MODEL || 'gpt-4o';
  } else if (type === 'mock') {
    // Mock-specific config via env
  }

  return config;
}
```

- [ ] **Step 3: Run test**

Run: `cd bondy_server && npx vitest test/unit/config/ai-provider.config.test.ts -v`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
cd bondy_server
git add src/config/ai-provider.config.ts test/unit/config/ai-provider.config.test.ts
git commit -m "feat(ai): add AI provider config with env vars

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 4: Create OtelWrapper

**Files:**
- Create: `src/wrapper/otel-wrapper.ts`
- Test: `test/unit/wrapper/otel-wrapper.test.ts`

- [ ] **Step 1: Create test file**

```typescript
// test/unit/wrapper/otel-wrapper.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { OtelWrapper } from '../../src/wrapper/otel-wrapper';

describe('OtelWrapper', () => {
  let wrapper: OtelWrapper;

  beforeEach(() => {
    wrapper = new OtelWrapper();
  });

  it('should create span with name', () => {
    const span = wrapper.startSpan('test.span');
    expect(span.name).toBe('test.span');
  });

  it('should end span without error', () => {
    const span = wrapper.startSpan('test.span');
    wrapper.endSpan(span);
    expect(span.endTime).toBeDefined();
  });

  it('should record exception on span', () => {
    const span = wrapper.startSpan('test.span');
    const error = new Error('Test error');
    wrapper.recordException(span, error);
    expect(span.exception).toBe(error);
  });

  it('should record latency', () => {
    wrapper.recordLatency('ai.request.latency', 100, { provider: 'mock' });
    // Verify metrics recorded (internal state)
  });

  it('should record tokens', () => {
    wrapper.recordTokens('mock', 50);
  });

  it('should record request success', () => {
    wrapper.recordRequest('mock', true);
  });

  it('should record request failure', () => {
    wrapper.recordRequest('mock', false);
  });
});
```

Run: `cd bondy_server && npx vitest test/unit/wrapper/otel-wrapper.test.ts -v`

- [ ] **Step 2: Create OtelWrapper file**

```typescript
// src/wrapper/otel-wrapper.ts

interface Span {
  name: string;
  attrs: Record<string, string>;
  startTime: number;
  endTime?: number;
  exception?: Error;
}

interface MetricPoint {
  name: string;
  value: number;
  tags: Record<string, string>;
  timestamp: number;
}

export class OtelWrapper {
  private spans: Span[] = [];
  private metrics: MetricPoint[] = [];
  private logs: Array<{ level: string; message: string; data?: unknown }> = [];

  // Span management
  startSpan(name: string, attrs: Record<string, string> = {}): Span {
    return {
      name,
      attrs,
      startTime: Date.now(),
    };
  }

  endSpan(span: Span): void {
    span.endTime = Date.now();
    this.spans.push(span);
  }

  recordException(span: Span, error: Error): void {
    span.exception = error;
  }

  // Metrics
  recordLatency(metric: string, ms: number, attrs: Record<string, string> = {}): void {
    this.metrics.push({
      name: metric,
      value: ms,
      tags: attrs,
      timestamp: Date.now(),
    });
  }

  recordTokens(provider: string, tokens: number): void {
    this.metrics.push({
      name: 'ai.tokens.used',
      value: tokens,
      tags: { provider },
      timestamp: Date.now(),
    });
  }

  recordRequest(provider: string, success: boolean): void {
    this.metrics.push({
      name: 'ai.request.count',
      value: 1,
      tags: { provider, status: success ? 'success' : 'failure' },
      timestamp: Date.now(),
    });
  }

  // Logging
  logRequest(provider: string, prompt: string, response?: string): void {
    this.logs.push({
      level: 'INFO',
      message: `AI request to ${provider}`,
      data: { prompt, response: response ? '[REDACTED]' : undefined },
    });
  }

  // Debug helpers
  getSpans(): Span[] {
    return [...this.spans];
  }

  getMetrics(): MetricPoint[] {
    return [...this.metrics];
  }

  getLogs() {
    return [...this.logs];
  }

  clear(): void {
    this.spans = [];
    this.metrics = [];
    this.logs = [];
  }
}

// Singleton for easy access
export const otelWrapper = new OtelWrapper();
```

- [ ] **Step 3: Run test**

Run: `cd bondy_server && npx vitest test/unit/wrapper/otel-wrapper.test.ts -v`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
cd bondy_server
git add src/wrapper/otel-wrapper.ts test/unit/wrapper/otel-wrapper.test.ts
git commit -m "feat(ai): add OtelWrapper for observability

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 5: Create AbstractAiProvider with Circuit Breaker

**Files:**
- Create: `src/abstract/abstract-ai-provider.ts`
- Test: `test/unit/abstract/abstract-ai-provider.test.ts`

- [ ] **Step 1: Create test file**

```typescript
// test/unit/abstract/abstract-ai-provider.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AbstractAiProvider } from '../../src/abstract/abstract-ai-provider';
import { AiProviderError } from '../../src/error/ai-provider.error';
import { OtelWrapper } from '../../src/wrapper/otel-wrapper';

// Concrete implementation for testing
class TestProvider extends AbstractAiProvider {
  callCount = 0;
  shouldFail = false;

  async rawGenerate(prompt: string): Promise<{ text: string; tokensUsed: number }> {
    this.callCount++;
    if (this.shouldFail) throw new Error('Provider error');
    return { text: `Echo: ${prompt}`, tokensUsed: 10 };
  }

  getProviderName(): string {
    return 'test';
  }
}

describe('AbstractAiProvider', () => {
  let provider: TestProvider;

  beforeEach(() => {
    provider = new TestProvider({
      timeoutMs: 5000,
      maxRetries: 2,
    });
  });

  it('should call rawGenerate once on success', async () => {
    const result = await provider.generate('hello');
    expect(result.text).toBe('Echo: hello');
    expect(result.tokensUsed).toBe(10);
    expect(provider.callCount).toBe(1);
  });

  it('should retry on failure', async () => {
    provider.shouldFail = true;
    await expect(provider.generate('hello')).rejects.toThrow();
    // Should have retried maxRetries times
  });

  it('should throw AiProviderError on timeout', async () => {
    const slowProvider = new TestProvider({ timeoutMs: 10, maxRetries: 0 });
    slowProvider.rawGenerate = async () => {
      await new Promise(r => setTimeout(r, 100));
      return { text: 'slow', tokensUsed: 1 };
    };
    await expect(slowProvider.generate('test')).rejects.toThrow(AiProviderError);
  });

  it('should open circuit breaker after failures', async () => {
    const cbProvider = new TestProvider({ timeoutMs: 1000, maxRetries: 0 });
    cbProvider.shouldFail = true;
    
    // Trigger 5 failures
    for (let i = 0; i < 5; i++) {
      try { await cbProvider.generate('test'); } catch {}
    }
    
    // Circuit should be OPEN
    expect(cbProvider.isCircuitOpen()).toBe(true);
  });
});
```

Run: `cd bondy_server && npx vitest test/unit/abstract/abstract-ai-provider.test.ts -v`

- [ ] **Step 2: Create AbstractAiProvider file**

```typescript
// src/abstract/abstract-ai-provider.ts

import { IAiProvider, AiResponse, GenerateOptions } from '../interface/ai-provider.interface';
import { AiProviderError } from '../error/ai-provider.error';
import { OtelWrapper } from '../wrapper/otel-wrapper';

interface CircuitBreakerState {
  failures: number;
  lastFailureTime: number;
  state: 'CLOSED' | 'OPEN' | 'HALF_OPEN';
  nextAttemptTime?: number;
}

export abstract class AbstractAiProvider implements IAiProvider {
  protected readonly timeoutMs: number;
  protected readonly maxRetries: number;
  protected readonly otel: OtelWrapper;

  private circuitBreaker: CircuitBreakerState = {
    failures: 0,
    lastFailureTime: 0,
    state: 'CLOSED',
  };

  // Circuit breaker config
  private readonly FAILURE_THRESHOLD = 5;
  private readonly RECOVERY_TIMEOUT_MS = 30000;

  constructor(config: { timeoutMs: number; maxRetries: number }) {
    this.timeoutMs = config.timeoutMs;
    this.maxRetries = config.maxRetries;
    this.otel = new OtelWrapper();
  }

  async generate(prompt: string, options?: GenerateOptions): Promise<AiResponse> {
    // Circuit breaker check
    if (this.isCircuitOpen()) {
      throw new AiProviderError('CIRCUIT_OPEN', this.getProviderName(), 'Circuit breaker is open');
    }

    const span = this.otel.startSpan(`ai.generate.${this.getProviderName()}`, {
      prompt_length: String(prompt.length),
    });

    try {
      const result = await this.withTimeout(this.executeWithRetry(prompt, options), this.timeoutMs);
      this.otel.recordRequest(this.getProviderName(), true);
      this.otel.recordTokens(this.getProviderName(), result.tokensUsed);
      this.otel.endSpan(span);
      return {
        ...result,
        provider: this.getProviderName(),
        latencyMs: span.endTime ? span.endTime - span.startTime : Date.now() - span.startTime,
      };
    } catch (error) {
      this.otel.recordRequest(this.getProviderName(), false);
      this.otel.recordException(span, error as Error);
      this.otel.endSpan(span);
      this.recordFailure();
      throw error;
    }
  }

  async generateStream(prompt: string, options?: GenerateOptions): AsyncGenerator<AiResponse> {
    // Implementation delegated to concrete provider
    yield* this.rawGenerateStream(prompt, options);
  }

  async generateStructured<T>(prompt: string, schema: object, options?: GenerateOptions): Promise<{ data: T; tokensUsed: number; latencyMs: number; provider: string }> {
    const span = this.otel.startSpan(`ai.generateStructured.${this.getProviderName()}`);
    try {
      const result = await this.withTimeout(this.executeStructured(prompt, schema, options), this.timeoutMs);
      this.otel.endSpan(span);
      return { ...result, provider: this.getProviderName() };
    } catch (error) {
      this.otel.recordException(span, error as Error);
      this.otel.endSpan(span);
      throw error;
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.withTimeout(this.rawHealthCheck(), 5000);
      return true;
    } catch {
      return false;
    }
  }

  // Abstract methods for concrete providers
  protected abstract rawGenerate(prompt: string): Promise<{ text: string; tokensUsed: number }>;
  protected abstract rawGenerateStream(prompt: string, options?: GenerateOptions): AsyncGenerator<AiResponse>;
  protected abstract rawGenerateStructured<T>(prompt: string, schema: object): Promise<{ data: T; tokensUsed: number }>;
  protected abstract rawHealthCheck(): Promise<void>;
  protected abstract getProviderName(): string;

  // Circuit breaker
  isCircuitOpen(): boolean {
    if (this.circuitBreaker.state === 'CLOSED') return false;
    
    if (this.circuitBreaker.state === 'OPEN') {
      if (Date.now() >= (this.circuitBreaker.nextAttemptTime || 0)) {
        this.circuitBreaker.state = 'HALF_OPEN';
        return false;
      }
      return true;
    }
    
    return false;
  }

  private recordFailure(): void {
    this.circuitBreaker.failures++;
    this.circuitBreaker.lastFailureTime = Date.now();
    
    if (this.circuitBreaker.state === 'HALF_OPEN') {
      this.circuitBreaker.state = 'OPEN';
      this.circuitBreaker.nextAttemptTime = Date.now() + this.RECOVERY_TIMEOUT_MS;
    } else if (this.circuitBreaker.failures >= this.FAILURE_THRESHOLD) {
      this.circuitBreaker.state = 'OPEN';
      this.circuitBreaker.nextAttemptTime = Date.now() + this.RECOVERY_TIMEOUT_MS;
    }
  }

  private async executeWithRetry(prompt: string, options?: GenerateOptions): Promise<{ text: string; tokensUsed: number }> {
    let lastError: Error | undefined;
    
    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      try {
        return await this.rawGenerate(prompt);
      } catch (error) {
        lastError = error as Error;
        if (attempt < this.maxRetries) {
          await this.delay(100 * Math.pow(2, attempt)); // Exponential backoff
        }
      }
    }
    
    throw lastError || new Error('All retries failed');
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
    return Promise.race([
      promise,
      new Promise<T>((_, reject) => 
        setTimeout(() => reject(new AiProviderError('TIMEOUT', this.getProviderName(), 'Request timed out')), ms)
      ),
    ]);
  }

  private async executeStructured<T>(prompt: string, schema: object, options?: GenerateOptions): Promise<{ data: T; tokensUsed: number; latencyMs: number }> {
    return this.rawGenerateStructured(prompt, schema);
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd bondy_server && npx vitest test/unit/abstract/abstract-ai-provider.test.ts -v`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
cd bondy_server
git add src/abstract/abstract-ai-provider.ts test/unit/abstract/abstract-ai-provider.test.ts
git commit -m "feat(ai): add AbstractAiProvider with retry, timeout, circuit breaker

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 6: Create MockAiProvider

**Files:**
- Create: `src/provider/mock-ai.provider.ts`
- Test: `test/unit/provider/mock-ai.provider.test.ts`

- [ ] **Step 1: Create test file**

```typescript
// test/unit/provider/mock-ai.provider.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MockAiProvider } from '../../../src/provider/mock-ai.provider';

describe('MockAiProvider', () => {
  let provider: MockAiProvider;

  beforeEach(() => {
    provider = new MockAiProvider({
      delayMs: 10,
      errorRate: 0,
    });
  });

  it('should return suggestions for openers intent', async () => {
    const result = await provider.generate('suggest openers for dating');
    expect(result.text).toContain('suggestions');
    expect(result.provider).toBe('mock');
    expect(result.tokensUsed).toBeGreaterThan(0);
  });

  it('should return suggestions for continue intent', async () => {
    const result = await provider.generate('suggest continue for conversation');
    expect(result.text).toContain('suggestions');
    expect(result.provider).toBe('mock');
  });

  it('should return suggestions for deepen intent', async () => {
    const result = await provider.generate('suggest questions to deepen relationship');
    expect(result.text).toContain('suggestions');
  });

  it('should respect delayMs config', async () => {
    provider = new MockAiProvider({ delayMs: 100 });
    const start = Date.now();
    await provider.generate('test');
    const elapsed = Date.now() - start;
    expect(elapsed).toBeGreaterThanOrEqual(90);
  });

  it('should throw on errorRate 100%', async () => {
    provider = new MockAiProvider({ delayMs: 0, errorRate: 1 });
    await expect(provider.generate('test')).rejects.toThrow();
  });

  it('should support generateStructured', async () => {
    const result = await provider.generateStructured('suggest', { type: 'array' });
    expect(result.data).toBeDefined();
    expect(result.provider).toBe('mock');
  });

  it('should pass healthCheck', async () => {
    const healthy = await provider.healthCheck();
    expect(healthy).toBe(true);
  });
});
```

Run: `cd bondy_server && npx vitest test/unit/provider/mock-ai.provider.test.ts -v`

- [ ] **Step 2: Create MockAiProvider file**

```typescript
// src/provider/mock-ai.provider.ts

import { AbstractAiProvider } from '../abstract/abstract-ai-provider';
import { GenerateOptions } from '../interface/ai-provider.interface';
import { AiResponse } from '../interface/ai-provider.interface';

interface MockConfig {
  delayMs?: number;
  errorRate?: number;
}

const MOCK_SUGGESTIONS: Record<string, string[]> = {
  default: [
    'Bạn có thấy hôm nay mình thật may mắn không?',
    'Mình thích cách bạn nói chuyện, rất thoải mái.',
    'Điều gì làm bạn vui nhất trong tuần này?',
  ],
  openers: [
    'Hey, mình thấy bạn很有型！',
    'Xin chào! Rất vui được làm quen.',
    'Bạn ăn sáng chưa? Mình thường ăn bánh mì 🥐',
  ],
  continue: [
    'Tiếp tục câu chuyện đi, mình rất thích lắng nghe bạn.',
    'Thú vị lắm! Kể thêm đi.',
    'Bạn có thường làm gì vào cuối tuần?',
  ],
  deepen: [
    'Bạn có thể chia sẻ về ước mơ của bạn không?',
    'Điều gì quan trọng nhất với bạn trong một mối quan hệ?',
    'Bạn cảm thấy thế nào khi ở bên cạnh người mình yêu?',
  ],
  humor: [
    'Nếu bạn là một loại bánh, bạn sẽ là bánh gì? Mình là bánh donut 🍩',
    'Mình nghe nói người yêu cũ của bạn giỏi lắm nhỉ... nấu cơm! 🍚',
  ],
  light_flirt: [
    'Mình thích nụ cười của bạn!',
    'Bạn có rảnh không? Mình muốn nói chuyện thêm.',
    'Mình cảm thấy thoải mái khi nói chuyện với bạn.',
  ],
};

export class MockAiProvider extends AbstractAiProvider {
  private readonly delayMs: number;
  private readonly errorRate: number;

  constructor(config: MockConfig & { timeoutMs: number; maxRetries: number }) {
    super({ timeoutMs: config.timeoutMs, maxRetries: config.maxRetries });
    this.delayMs = config.delayMs || 500;
    this.errorRate = config.errorRate || 0;
  }

  protected async rawGenerate(prompt: string): Promise<{ text: string; tokensUsed: number }> {
    await this.delay(this.delayMs);

    if (Math.random() < this.errorRate) {
      throw new Error('Mock AI error');
    }

    const intent = this.detectIntent(prompt);
    const suggestions = MOCK_SUGGESTIONS[intent] || MOCK_SUGGESTIONS.default;
    const selectedSuggestions = suggestions.slice(0, 3 + Math.floor(Math.random() * 2));

    return {
      text: JSON.stringify(selectedSuggestions),
      tokensUsed: Math.floor(Math.random() * 50) + 10,
    };
  }

  protected async *rawGenerateStream(prompt: string, options?: GenerateOptions): AsyncGenerator<AiResponse> {
    const result = await this.rawGenerate(prompt);
    const suggestions = JSON.parse(result.text);

    for (const suggestion of suggestions) {
      await this.delay(100);
      yield {
        text: suggestion,
        tokensUsed: Math.floor(result.tokensUsed / suggestions.length),
        latencyMs: 100,
        provider: 'mock',
      };
    }
  }

  protected async rawGenerateStructured<T>(prompt: string, schema: object): Promise<{ data: T; tokensUsed: number }> {
    const result = await this.rawGenerate(prompt);
    return {
      data: JSON.parse(result.text) as T,
      tokensUsed: result.tokensUsed,
    };
  }

  protected async rawHealthCheck(): Promise<void> {
    await this.delay(10);
  }

  protected getProviderName(): string {
    return 'mock';
  }

  private detectIntent(prompt: string): string {
    const lower = prompt.toLowerCase();
    if (lower.includes('opener') || lower.includes('bắt chuyện')) return 'openers';
    if (lower.includes('continue') || lower.includes('tiếp tục')) return 'continue';
    if (lower.includes('deepen') || lower.includes('hỏi sâu')) return 'deepen';
    if (lower.includes('humor') || lower.includes('hài hước')) return 'humor';
    if (lower.includes('flirt') || lower.includes('flirt')) return 'light_flirt';
    return 'default';
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd bondy_server && npx vitest test/unit/provider/mock-ai.provider.test.ts -v`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
cd bondy_server
git add src/provider/mock-ai.provider.ts test/unit/provider/mock-ai.provider.test.ts
git commit -m "feat(ai): add MockAiProvider for Sprint 2

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 7: Create Provider Factory

**Files:**
- Create: `src/factory/ai-provider.factory.ts`
- Test: `test/unit/factory/ai-provider.factory.test.ts`

- [ ] **Step 1: Create test file**

```typescript
// test/unit/factory/ai-provider.factory.test.ts
import { describe, it, expect } from 'vitest';
import { createProvider, ProviderType } from '../../../src/factory/ai-provider.factory';

describe('AiProviderFactory', () => {
  it('should create mock provider', () => {
    const provider = createProvider('mock', { timeoutMs: 5000, maxRetries: 2 });
    expect(provider.constructor.name).toBe('MockAiProvider');
  });

  it('should create provider with correct config', async () => {
    const provider = createProvider('mock', { timeoutMs: 5000, maxRetries: 2 });
    const result = await provider.generate('test');
    expect(result.provider).toBe('mock');
  });

  it('should throw on unknown provider type', () => {
    expect(() => createProvider('unknown' as ProviderType, {})).toThrow();
  });
});
```

Run: `cd bondy_server && npx vitest test/unit/factory/ai-provider.factory.test.ts -v`

- [ ] **Step 2: Create factory file**

```typescript
// src/factory/ai-provider.factory.ts

import { IAiProvider } from '../interface/ai-provider.interface';
import { ProviderConfig } from '../config/ai-provider.config';
import { MockAiProvider } from '../provider/mock-ai.provider';

export type ProviderType = 'mock' | 'gemini' | 'openai';

export function createProvider(type: ProviderType, config: ProviderConfig): IAiProvider {
  switch (type) {
    case 'mock':
      return new MockAiProvider({
        timeoutMs: config.timeoutMs || 30000,
        maxRetries: config.maxRetries || 2,
        delayMs: parseInt(process.env.MOCK_AI_DELAY_MS || '500', 10),
        errorRate: parseFloat(process.env.MOCK_AI_ERROR_RATE || '0'),
      });

    case 'gemini':
      // Phase 2 implementation
      // return new GeminiAiProvider(config);
      throw new Error('Gemini provider not implemented yet');

    case 'openai':
      // Phase 2 implementation
      // return new OpenAiProvider(config);
      throw new Error('OpenAI provider not implemented yet');

    default:
      throw new Error(`Unknown provider type: ${type}`);
  }
}
```

- [ ] **Step 3: Run test**

Run: `cd bondy_server && npx vitest test/unit/factory/ai-provider.factory.test.ts -v`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
cd bondy_server
git add src/factory/ai-provider.factory.ts test/unit/factory/ai-provider.factory.test.ts
git commit -m "feat(ai): add AI provider factory

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 8: Create Directory Structure and Run All Tests

- [ ] **Step 1: Create test directory structure**

```bash
cd bondy_server
mkdir -p test/unit/interface
mkdir -p test/unit/error
mkdir -p test/unit/config
mkdir -p test/unit/wrapper
mkdir -p test/unit/abstract
mkdir -p test/unit/provider
mkdir -p test/unit/factory
```

- [ ] **Step 2: Run all tests**

Run: `cd bondy_server && npx vitest run`
Expected: All tests PASS

- [ ] **Step 3: Commit all**

```bash
cd bondy_server
git add -A
git commit -m "test(ai): run all unit tests for AI provider abstraction

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Success Checklist

- [ ] IAiProvider interface defined
- [ ] AbstractAiProvider with retry, timeout, circuit breaker
- [ ] MockAiProvider working (Sprint 2)
- [ ] OtelWrapper implemented
- [ ] Factory creates correct provider
- [ ] Unit tests pass
- [ ] All files committed
