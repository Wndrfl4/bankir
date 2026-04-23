import { createParamDecorator, ExecutionContext } from '@nestjs/common';

type AuthenticatedRequest = {
  user?: {
    id: string;
  };
};

export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): string | undefined => {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    return request.user?.id;
  },
);
