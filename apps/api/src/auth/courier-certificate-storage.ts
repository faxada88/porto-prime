import { BadRequestException } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

type UploadedPdf = {
  originalname?: string;
  size?: number;
  buffer?: Buffer;
};

export class CourierCertificateStorage {
  static readonly maxBytes = 5 * 1024 * 1024;

  private static root() {
    return resolve(
      process.env.PRIVATE_UPLOAD_DIR ??
        join(process.cwd(), 'storage', 'private'),
    );
  }

  private static certificateDir() {
    return join(this.root(), 'courier-certificates');
  }

  private static validPdf(buffer: Buffer) {
    return (
      buffer.length >= 5 &&
      buffer.subarray(0, 5).toString('ascii') === '%PDF-'
    );
  }

  static async stage(file?: UploadedPdf) {
    const bytes = file?.buffer;
    const size = Number(file?.size ?? bytes?.length ?? 0);
    const originalName = String(file?.originalname ?? '').trim();

    if (!bytes?.length) {
      throw new BadRequestException(
        'Selecione a certidão em PDF',
      );
    }

    if (size > this.maxBytes) {
      throw new BadRequestException(
        'A certidão deve ter no máximo 5 MB',
      );
    }

    if (
      !originalName.toLowerCase().endsWith('.pdf') ||
      !this.validPdf(bytes)
    ) {
      throw new BadRequestException(
        'Envie um arquivo PDF válido',
      );
    }

    await mkdir(this.certificateDir(), { recursive: true });

    const token = randomBytes(32).toString('hex');
    const storageName = token + '.pdf';
    const absolutePath = join(
      this.certificateDir(),
      storageName,
    );

    await writeFile(absolutePath, bytes, { flag: 'wx' });

    return {
      token,
      fileName: 'antecedentes-criminais.pdf',
      size,
      storageKey: 'courier-certificates/' + storageName,
      uploadedAt: new Date().toISOString(),
    };
  }
}
