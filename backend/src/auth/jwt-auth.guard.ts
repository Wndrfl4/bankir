import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

type AuthenticatedRequest = {
  headers: {
    authorization?: string;
  };
  user?: {
    id: string;
  };
};

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = this.extractBearerToken(request);

    if (!token) {
      throw new UnauthorizedException('Access token is missing');
    }

    try {
      const payload = await this.jwtService.verifyAsync<{ sub: string }>(token, {
        secret: process.env.JWT_ACCESS_SECRET ?? 'dev-access-secret',
      });

      request.user = {
        id: payload.sub,
      };

      return true;
    } catch {
      throw new UnauthorizedException('Access token is invalid or expired');
    }
  }

  private extractBearerToken(request: AuthenticatedRequest): string | null {
    const authorization = request.headers.authorization;

    if (!authorization) {
      return null;
    }

    const [type, token] = authorization.split(' ');
    if (type !== 'Bearer' || !token) {
      return null;
    }

    return token;
  }
}
