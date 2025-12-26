import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Contact } from '../entities/contact.entity';
import { CreateContactDto } from '../dto/create-contact.dto';
import { UpdateContactDto } from '../dto/update-contact.dto';

@Injectable()
export class ContactsService {
  constructor(@InjectRepository(Contact) private repo: Repository<Contact>) {}

  async create(dto: CreateContactDto): Promise<Contact> {
    const contact = this.repo.create(dto);
    return this.repo.save(contact);
  }

  async findAll(): Promise<Contact[]> {
    return this.repo.find({
      relations: ['organization'],
      order: { createdAt: 'DESC' }
    });
  }

  async findOne(id: string): Promise<Contact> {
    const item = await this.repo.findOne({
      where: { id },
      relations: ['organization']
    });
    if (!item) {
      throw new NotFoundException(`Contact #${id} not found`);
    }
    return item;
  }

  async update(id: string, dto: UpdateContactDto): Promise<Contact> {
    const item = await this.findOne(id);
    return this.repo.save({ ...item, ...dto });
  }

  async remove(id: string): Promise<void> {
    const item = await this.findOne(id);
    await this.repo.remove(item);
  }
}
