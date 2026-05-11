export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
    public readonly code: string,
  ) {
    super(message);
  }
}

export const badRequest = (message: string, code = 'bad_request') =>
  new AppError(400, message, code);

export const unauthorized = (message = '请先登录。', code = 'unauthorized') =>
  new AppError(401, message, code);

export const forbidden = (message: string, code = 'forbidden') =>
  new AppError(403, message, code);

export const notFound = (message: string, code = 'not_found') =>
  new AppError(404, message, code);

export const quotaExceeded = () =>
  new AppError(429, '本月免费总结次数已用完。', 'quota_exceeded');
