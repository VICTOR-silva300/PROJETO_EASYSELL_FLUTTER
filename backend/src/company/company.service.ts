import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { Company, CompanyDocument } from './schemas/company.schema.js';
import { Employee, EmployeeDocument } from './schemas/employee.schema.js';
import { CreateCompanyDto } from './dto/create-company.dto.js';
import { UpdateCompanyDto } from './dto/update-company.dto.js';
import { CreateEmployeeDto } from './dto/create-employee.dto.js';
import { UsersService } from '../users/users.service.js';

@Injectable()
export class CompanyService {
  constructor(
    @InjectModel(Company.name)
    private readonly companyModel: Model<CompanyDocument>,
    @InjectModel(Employee.name)
    private readonly employeeModel: Model<EmployeeDocument>,
    private readonly usersService: UsersService,
  ) {}


  async createEmployee(createEmployeeDto: CreateEmployeeDto): Promise<EmployeeDocument> {
    const employee = new this.employeeModel(createEmployeeDto);
    const saved = await employee.save();
    await this.companyModel.findByIdAndUpdate(
      createEmployeeDto.companyId,
      { $addToSet: { employeeIds: saved._id } },
    ).exec();
    return saved;
  }

  async updateEmployee(id: string, data: Partial<CreateEmployeeDto>): Promise<EmployeeDocument> {
    const employee = await this.employeeModel.findByIdAndUpdate(id, data, { new: true, runValidators: true }).exec();
    if (!employee) throw new NotFoundException(`Funcionário com id ${id} não encontrado`);
    return employee;
  }

  async removeEmployee(id: string): Promise<EmployeeDocument> {
    const employee = await this.employeeModel.findByIdAndDelete(id).exec();
    if (!employee) throw new NotFoundException(`Funcionário com id ${id} não encontrado`);
    await this.companyModel.updateMany({ employeeIds: id }, { $pull: { employeeIds: id } }).exec();
    return employee;
  }

  async bootstrapForUser(userId: string, name: string) {
    const existing = await this.companyModel.findOne({ responsavelId: userId }).exec();
    if (existing) return existing;
    const suffix = userId.replace(/[^a-fA-F0-9]/g, '').slice(-11).padStart(11, '0');
    const cnpj = ('000000' + suffix).slice(-14);
    const cpf = suffix;
    const company = await this.companyModel.create({
      name: name || 'Minha Empresa',
      categoria: 'Comércio',
      cnpj,
      cpfResponsavel: cpf,
      responsavelId: userId,
      employeeIds: [],
    });
    await this.usersService.update(userId, { company: company._id.toString() });
    return company;
  }

  async create(createCompanyDto: CreateCompanyDto): Promise<CompanyDocument> {
    const company = new this.companyModel(createCompanyDto);
    return company.save();
  }

  async addEmployeeToCompany(
    companyId: string,
    employeeId: string,
  ): Promise<CompanyDocument> {
    const company = await this.companyModel
      .findByIdAndUpdate(
        companyId,
        { $addToSet: { employeeIds: employeeId } },
        { new: true, runValidators: true },
      )
      .exec();

    if (!company) {
      throw new NotFoundException(`Empresa com id ${companyId} não encontrada`);
    }

    return company;
  }

  async findEmployeesByCompanyId(
    companyId: string,
  ): Promise<EmployeeDocument[]> {
    return this.employeeModel.find({ companyId }).exec();
  }

  async findEmployeesByName(name: string): Promise<EmployeeDocument[]> {
    const normalizedName = name?.trim();
    if (!normalizedName) {
      throw new BadRequestException('Informe o nome do funcionário');
    }

    const escapedName = normalizedName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return this.employeeModel
      .find({ name: { $regex: escapedName, $options: 'i' } })
      .exec();
  }

  async findAll(): Promise<CompanyDocument[]> {
    return this.companyModel.find().exec();
  }

  async findOne(id: string): Promise<CompanyDocument> {
    const company = await this.companyModel.findById(id).exec();
    if (!company) {
      throw new NotFoundException(`Empresa com id ${id} não encontrada`);
    }
    return company;
  }

  async update(
    id: string,
    updateCompanyDto: UpdateCompanyDto,
  ): Promise<CompanyDocument> {
    const company = await this.companyModel
      .findByIdAndUpdate(id, updateCompanyDto, {
        new: true,
        runValidators: true,
      })
      .exec();
    if (!company) {
      throw new NotFoundException(`Empresa com id ${id} não encontrada`);
    }
    return company;
  }

  async remove(id: string): Promise<CompanyDocument> {
    const company = await this.companyModel.findByIdAndDelete(id).exec();
    if (!company) {
      throw new NotFoundException(`Empresa com id ${id} não encontrada`);
    }
    return company;
  }
}
