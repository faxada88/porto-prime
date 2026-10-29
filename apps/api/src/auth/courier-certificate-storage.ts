import { BadRequestException } from '@nestjs/common';
import { createHash, randomBytes } from 'node:crypto';
import {
  mkdir,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from 'node:fs/promises';
import { join, resolve } from 'node:path';

type UploadedPdf = {
  originalname?: string;
  size?: number;
  buffer?: Buffer;
};

export type StoredCourierCertificate = {
  metadata: {
    fileName: string;
    storageKey: string;
    mimeType: 'application/pdf';
    size: number;
    uploadedAt: string;
  };
  absolutePath: string;
};

export class CourierCertificateStorage {
  static readonly maxBytes = 5 * 1024 * 1024;
  static readonly stageTtlMs = 24 * 60 * 60 * 1000;

  private static tokenHash(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  private static root() {
    return resolve(
      process.env.PRIVATE_UPLOAD_DIR ??
        join(process.cwd(), 'storage', 'private'),
    );
  }

  private static stagedDir() {
    return join(this.root(), 'staged-courier-certificates');
  }

  private static finalDir() {
    return join(this.root(), 'courier-certificates');
  }

  private static validPdf(buffer: Buffer) {
    return (
      buffer.length >= 5 &&
      buffer.subarray(0, 5).toString('ascii') === '%PDF-'
    );
  }

  private static async cleanupExpiredStaged() {
    await mkdir(this.stagedDir(), { recursive: true });
    const names = await readdir(this.stagedDir()).catch(() => []);
    const cutoff = Date.now() - this.stageTtlMs;

    await Promise.all(
      names
        .filter((name) => name.endsWith('.pdf'))
        .map(async (name) => {
          const path = join(this.stagedDir(), name);
          try {
            const info = await stat(path);
            if (info.mtimeMs < cutoff) {
              await rm(path, { force: true });
            }
          } catch {
            // Arquivo temporario desapareceu durante a limpeza.
          }
        }),
    );
  }

  static async stage(file?: UploadedPdf) {
    const bytes = file?.buffer;
    const size = Number(file?.size ?? bytes?.length ?? 0);
    const name = String(file?.originalname ?? '').trim();

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
      !name.toLowerCase().endsWith('.pdf') ||
      !this.validPdf(bytes)
    ) {
      throw new BadRequestException(
        'Envie um arquivo PDF válido',
      );
    }

    await this.cleanupExpiredStaged();

    const issuedAt = Date.now();
    const token =
      String(issuedAt) +
      '.' +
      randomBytes(32).toString('base64url');
    const stagedPath = join(
      this.stagedDir(),
      this.tokenHash(token) + '.pdf',
    );

    await writeFile(stagedPath, bytes, { flag: 'wx' });

    return {
      token,
      fileName: 'antecedentes-criminais.pdf',
      size,
      expiresAt: new Date(
        issuedAt + this.stageTtlMs,
      ).toISOString(),
    };
  }

  static async consume(
    rawToken: unknown,
  ): Promise<StoredCourierCertificate> {
    const token = String(rawToken ?? '').trim();
    const issuedAt = Number(token.split('.', 1)[0]);

    if (
      !token ||
      !Number.isFinite(issuedAt) ||
      Date.now() - issuedAt < 0 ||
      Date.now() - issuedAt > this.stageTtlMs
    ) {
      throw new BadRequestException(
        'O anexo da certidão expirou. Selecione o PDF novamente.',
      );
    }

    const stagedPath = join(
      this.stagedDir(),
      this.tokenHash(token) + '.pdf',
    );

    let info;
    try {
      info = await stat(stagedPath);
    } catch {
      throw new BadRequestException(
        'O anexo da certidão não foi encontrado. Selecione o PDF novamente.',
      );
    }

    await mkdir(this.finalDir(), { recursive: true });

    const finalName =
      randomBytes(24).toString('hex') + '.pdf';
    const finalPath = join(this.finalDir(), finalName);

    try {
      await rename(stagedPath, finalPath);
    } catch {
      throw new BadRequestException(
        'Não foi possível vincular a certidão ao cadastro. Tente anexar novamente.',
      );
    }

    return {
      absolutePath: finalPath,
      metadata: {
        fileName: 'antecedentes-criminais.pdf',
        storageKey: 'courier-certificates/' + finalName,
        mimeType: 'application/pdf',
        size: Number(info.size),
        uploadedAt: new Date().toISOString(),
      },
    };
  }

  static async rollback(absolutePath?: string) {
    if (!absolutePath) return;
    await rm(absolutePath, { force: true }).catch(() => {});
  }
}
