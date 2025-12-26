import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Activity } from '../entities/activity.entity';
import { CreateActivityDto } from '../dto/create-activity.dto';
import { UpdateActivityDto } from '../dto/update-activity.dto';

@Injectable()
export class ActivitiesService {
  constructor(@InjectRepository(Activity) private repo: Repository<Activity>) {}

  async create(dto: CreateActivityDto): Promise<Activity> {
    const activity = this.repo.create(dto);
    return this.repo.save(activity);
  }

  async findAll(): Promise<Activity[]> {
    return this.repo.find({
      relations: ['contact'],
      order: { activityDate: 'DESC' }
    });
  }

  async findOne(id: string): Promise<Activity> {
    const item = await this.repo.findOne({
      where: { id },
      relations: ['contact']
    });
    if (!item) {
      throw new NotFoundException(`Activity #${id} not found`);
    }
    return item;
  }

  async update(id: string, dto: UpdateActivityDto): Promise<Activity> {
    const item = await this.findOne(id);
    return this.repo.save({ ...item, ...dto });
  }

  async remove(id: string): Promise<void> {
    const item = await this.findOne(id);
    await this.repo.remove(item);
  }

  async findByContact(contactId: string): Promise<Activity[]> {
    return this.repo.find({
      where: { contactId },
      relations: ['contact'],
      order: { activityDate: 'DESC' }
    });
  }
}
