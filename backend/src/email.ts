export type EmailSender = {
  sendLoginCode(email: string, code: string): Promise<void>;
};

export class ConsoleEmailSender implements EmailSender {
  async sendLoginCode(email: string, code: string): Promise<void> {
    console.info(`[AIMemo] login code for ${email}: ${code}`);
  }
}
