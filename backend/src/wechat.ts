import type { AppConfig } from './config.js';
import { badRequest, unauthorized } from './errors.js';

export type WechatLoginResult = {
  openId: string;
  unionId?: string | null;
};

export type WechatClient = {
  loginMiniProgram(code: string): Promise<WechatLoginResult>;
};

export class WechatApiClient implements WechatClient {
  constructor(private readonly config: AppConfig) {}

  async loginMiniProgram(code: string): Promise<WechatLoginResult> {
    if (!this.config.wechatMiniProgramAppId || !this.config.wechatMiniProgramAppSecret) {
      throw badRequest('微信小程序登录尚未配置。', 'wechat_not_configured');
    }
    const url = new URL('https://api.weixin.qq.com/sns/jscode2session');
    url.searchParams.set('appid', this.config.wechatMiniProgramAppId);
    url.searchParams.set('secret', this.config.wechatMiniProgramAppSecret);
    url.searchParams.set('js_code', code);
    url.searchParams.set('grant_type', 'authorization_code');

    const response = await fetch(url);
    const body = (await response.json()) as {
      openid?: string;
      unionid?: string;
      errcode?: number;
      errmsg?: string;
    };
    if (!response.ok || body.errcode || !body.openid) {
      throw unauthorized(
        body.errmsg ?? '微信登录失败，请重试。',
        'wechat_login_failed',
      );
    }
    return { openId: body.openid, unionId: body.unionid ?? null };
  }
}
