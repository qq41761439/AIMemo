import nodemailer from 'nodemailer';

import type { AppConfig } from './config.js';

export type EmailSender = {
  sendLoginCode(email: string, code: string): Promise<void>;
};

export class ConsoleEmailSender implements EmailSender {
  async sendLoginCode(email: string, code: string): Promise<void> {
    console.info(`[AIMemo] login code for ${email}: ${code}`);
  }
}

export class SmtpEmailSender implements EmailSender {
  private readonly transport;

  constructor(private readonly config: AppConfig) {
    this.transport = nodemailer.createTransport({
      host: config.smtpHost,
      port: config.smtpPort,
      secure: config.smtpSecure,
      auth:
        config.smtpUser && config.smtpPass
          ? {
              user: config.smtpUser,
              pass: config.smtpPass,
            }
          : undefined,
    });
  }

  async sendLoginCode(email: string, code: string): Promise<void> {
    await this.transport.sendMail({
      from: this.config.smtpFrom,
      to: email,
      subject: 'AIMemo 登录验证码',
      text:
        `你的 AIMemo 登录验证码是：${code}\n\n` +
        `验证码将在 ${this.config.emailCodeTtlMinutes} 分钟后失效。`,
      html:
        `<p>你的 AIMemo 登录验证码是：</p>` +
        `<p style="font-size:24px;font-weight:700;letter-spacing:4px;">${code}</p>` +
        `<p>验证码将在 ${this.config.emailCodeTtlMinutes} 分钟后失效。</p>`,
    });
  }
}

export function createEmailSender(config: AppConfig): EmailSender {
  if (config.resendApiKey && config.resendFrom) {
    return new ResendEmailSender(config);
  }
  if (config.smtpHost && config.smtpFrom) {
    return new SmtpEmailSender(config);
  }
  return new ConsoleEmailSender();
}

export class ResendEmailSender implements EmailSender {
  constructor(private readonly config: AppConfig) {}

  async sendLoginCode(email: string, code: string): Promise<void> {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${this.config.resendApiKey}`,
        'content-type': 'application/json',
        'user-agent': 'aimemo-backend/0.1.0',
      },
      body: JSON.stringify({
        from: this.config.resendFrom,
        to: [email],
        subject: 'AIMemo 登录验证码',
        text:
          `你的 AIMemo 登录验证码是：${code}\n\n` +
          `验证码将在 ${this.config.emailCodeTtlMinutes} 分钟后失效。`,
        html:
          `<p>你的 AIMemo 登录验证码是：</p>` +
          `<p style="font-size:24px;font-weight:700;letter-spacing:4px;">${code}</p>` +
          `<p>验证码将在 ${this.config.emailCodeTtlMinutes} 分钟后失效。</p>`,
      }),
    });

    if (response.ok) {
      return;
    }

    let message = `Resend email failed with status ${response.status}.`;
    try {
      const body = (await response.json()) as {
        message?: string;
        error?: string;
      };
      message = body.message ?? body.error ?? message;
    } catch (_) {}
    throw new Error(message);
  }
}
