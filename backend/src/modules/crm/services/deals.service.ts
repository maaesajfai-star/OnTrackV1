import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Deal } from '../entities/deal.entity';
import { CreateDealDto } from '../dto/create-deal.dto';
import { UpdateDealDto } from '../dto/update-deal.dto';

@Injectable()
export class DealsService {
  constructor(@InjectRepository(Deal) private repo: Repository<Deal>) {}

  async create(dto: CreateDealDto): Promise<Deal> {
    const deal = this.repo.create(dto);
    return this.repo.save(deal);
  }

  async findAll(): Promise<Deal[]> {
    return this.repo.find({
      relations: ['contact', 'organization'],
      order: { createdAt: 'DESC' }
    });
  }

  async findOne(id: string): Promise<Deal> {
    const item = await this.repo.findOne({
      where: { id },
      relations: ['contact', 'organization']
    });
    if (!item) {
      throw new NotFoundException(`Deal #${id} not found`);
    }
    return item;
  }

  async update(id: string, dto: UpdateDealDto): Promise<Deal> {
    const item = await this.findOne(id);
    return this.repo.save({ ...item, ...dto });
  }

  async remove(id: string): Promise<void> {
    const item = await this.findOne(id);
    await this.repo.remove(item);
  }

  async findByStage(stage: string): Promise<Deal[]> {
    return this.repo.find({
      where: { stage: stage as any },
      relations: ['contact', 'organization']
    });
  }
}
