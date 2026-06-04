import { Global, Module } from '@nestjs/common';
import { SensitiveWordFilter } from './filters/sensitive-word.filter';

@Global()
@Module({
  providers: [SensitiveWordFilter],
  exports: [SensitiveWordFilter],
})
export class CommonModule {}
