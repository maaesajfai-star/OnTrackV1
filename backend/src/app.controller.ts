import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('health')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  @ApiOperation({ summary: 'Health check endpoint' })
  getHealth() {
    return this.appService.getHealth();
  }

  @Get('/')
  @ApiOperation({ summary: 'Root endpoint' })
  getRoot() {
    return {
      message: 'OnTrack API v1.0.0',
      documentation: '/api/docs',
      health: '/api/v1/health',
    };
  }
}
