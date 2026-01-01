import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  private sanitizeBody(body: any): string {
    if (!body) return '';

    // Create a copy to avoid modifying the original
    const sanitized = { ...body };

    // List of sensitive fields to redact
    const sensitiveFields = ['password', 'token', 'secret', 'apiKey', 'refreshToken'];

    sensitiveFields.forEach(field => {
      if (sanitized[field]) {
        sanitized[field] = '[REDACTED]';
      }
    });

    return JSON.stringify(sanitized);
  }

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, body } = request;
    const userAgent = request.get('user-agent') || '';
    const now = Date.now();

    // Only log sanitized request body in development
    const sanitizedBody = process.env.NODE_ENV === 'development'
      ? this.sanitizeBody(body)
      : '';

    if (sanitizedBody) {
      this.logger.log(
        `${method} ${url} - ${userAgent} - Body: ${sanitizedBody}`,
      );
    } else {
      this.logger.log(`${method} ${url} - ${userAgent}`);
    }

    return next.handle().pipe(
      tap(() => {
        const response = context.switchToHttp().getResponse();
        const { statusCode } = response;
        const duration = Date.now() - now;

        this.logger.log(
          `${method} ${url} - ${statusCode} - ${duration}ms`,
        );
      }),
    );
  }
}
