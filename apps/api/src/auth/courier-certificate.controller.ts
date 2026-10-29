import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CourierCertificateStorage } from './courier-certificate-storage.js';

@Controller('auth')
export class CourierCertificateController {
  @Post('courier-certificate')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: CourierCertificateStorage.maxBytes },
    }),
  )
  stageCourierCertificate(@UploadedFile() file?: any) {
    return CourierCertificateStorage.stage(file);
  }
}
