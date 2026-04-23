export enum RegisterRoleDto {
  ADMIN = 'ADMIN',
  USER = 'USER',
}

export class RegisterDto {
  username!: string;

  email!: string;

  password!: string;

  role?: RegisterRoleDto;
}
