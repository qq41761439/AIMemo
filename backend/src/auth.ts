import { createHash, randomBytes, randomInt } from 'node:crypto';

import jwt from 'jsonwebtoken';
import type { SignOptions } from 'jsonwebtoken';

import type { AppConfig } from './config.js';
import { badRequest, unauthorized } from './errors.js';
import type { DataStore } from './store.js';
import type { User } from './types.js';

export type AuthTokens = {
  accessToken: string;
  refreshToken: string;
};

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export function generateEmailCode(): string {
  return String(randomInt(0, 1000000)).padStart(6, '0');
}

export function hashSecret(secret: string): string {
  return createHash('sha256').update(secret).digest('hex');
}

export class AuthService {
  constructor(
    private readonly store: DataStore,
    private readonly config: AppConfig,
  ) {}

  async startEmailLogin(emailInput: string): Promise<string> {
    const email = normalizeEmail(emailInput);
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw badRequest('请输入有效邮箱地址。', 'invalid_email');
    }
    const code = generateEmailCode();
    const expiresAt = new Date(
      Date.now() + this.config.emailCodeTtlMinutes * 60 * 1000,
    );
    await this.store.saveEmailCode(email, hashSecret(code), expiresAt);
    return code;
  }

  async verifyEmailLogin(emailInput: string, code: string): Promise<User> {
    const email = normalizeEmail(emailInput);
    const record = await this.store.getEmailCode(email);
    if (!record || record.expiresAt.getTime() < Date.now()) {
      throw unauthorized('验证码已过期，请重新获取。', 'email_code_expired');
    }
    if (record.attempts >= 5) {
      await this.store.deleteEmailCode(email);
      throw unauthorized('验证码错误次数过多，请重新获取。', 'email_code_locked');
    }
    if (record.codeHash !== hashSecret(code.trim())) {
      await this.store.incrementEmailCodeAttempts(email);
      throw unauthorized('验证码不正确。', 'invalid_email_code');
    }
    await this.store.deleteEmailCode(email);
    return this.store.findOrCreateUserByEmail(email);
  }

  async issueTokens(userId: string): Promise<AuthTokens> {
    const accessTokenOptions: SignOptions = {
      expiresIn: this.config.accessTokenTtl as SignOptions['expiresIn'],
    };
    const accessToken = jwt.sign(
      { sub: userId },
      this.config.authSecret,
      accessTokenOptions,
    );
    const refreshToken = randomBytes(32).toString('base64url');
    await this.store.saveRefreshSession({
      userId,
      tokenHash: hashSecret(refreshToken),
      expiresAt: new Date(
        Date.now() + this.config.refreshTokenDays * 24 * 60 * 60 * 1000,
      ),
    });
    return { accessToken, refreshToken };
  }

  verifyAccessToken(token: string): string {
    try {
      const payload = jwt.verify(token, this.config.authSecret);
      if (typeof payload === 'object' && typeof payload.sub === 'string') {
        return payload.sub;
      }
    } catch (_) {}
    throw unauthorized('登录已过期，请重新登录。', 'invalid_access_token');
  }

  async refresh(refreshToken: string): Promise<AuthTokens> {
    const tokenHash = hashSecret(refreshToken);
    const session = await this.store.getRefreshSession(tokenHash);
    if (!session || session.expiresAt.getTime() < Date.now()) {
      throw unauthorized('登录已过期，请重新登录。', 'invalid_refresh_token');
    }
    await this.store.deleteRefreshSession(tokenHash);
    return this.issueTokens(session.userId);
  }
}
