import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Organization } from '../entities/organization.entity';
import { CreateOrganizationDto } from '../dto/create-organization.dto';
import { UpdateOrganizationDto } from '../dto/update-organization.dto';

@Injectable()
export class OrganizationsService {
  constructor(@InjectRepository(Organization) private repo: Repository<Organization>) {}

  async create(dto: CreateOrganizationDto): Promise<Organization> {
    const organization = this.repo.create(dto);
    return this.repo.save(organization);
  }

  async findAll(): Promise<Organization[]> {
    return this.repo.find({
      relations: ['parentOrganization'],
      order: { createdAt: 'DESC' }
    });
  }

  async findOne(id: string): Promise<Organization> {
    const item = await this.repo.findOne({
      where: { id },
      relations: ['parentOrganization', 'contacts']
    });
    if (!item) {
      throw new NotFoundException(`Organization #${id} not found`);
    }
    return item;
  }

  async update(id: string, dto: UpdateOrganizationDto): Promise<Organization> {
    const item = await this.findOne(id);
    return this.repo.save({ ...item, ...dto });
  }

  async remove(id: string): Promise<void> {
    const item = await this.findOne(id);
    await this.repo.remove(item);
  }
}
