import { IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({
    example: 'Admin',
    description: 'Username or email address'
  })
  @IsString()
  username: string;

  @ApiProperty({ example: 'AdminAdmin@123' })
  @IsString()
  @MinLength(6)
  password: string;
}
