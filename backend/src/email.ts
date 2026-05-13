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
  if (config.smtpHost && config.smtpFrom) {
    return new SmtpEmailSender(config);
  }
  return new ConsoleEmailSender();
}
