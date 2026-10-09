import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

import { UsersService } from '../users/users.service.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.usersService.findByEmail(email);

    if (!user) {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    const passwordMatches = await bcrypt.compare(
      password,
      user.passwordHash,
    );

    if (!passwordMatches) {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    return user;
  }

  async login(email: string, password: string) {
    const user = await this.validateUser(email, password);

    const payload = {
      sub: user._id.toString(),
      name: user.name,
      email: user.email,
      senha: user.passwordHash,
      role: user.role,
      empresaId: user.company?.toString() ?? null,
    };

    return {
      accessToken: this.jwtService.sign(payload),
      sub: user._id.toString(),
      name: user.name,
      email: user.email,
      role: user.role,
      empresaId: user.company?.toString() ?? null,
    };
  }
}