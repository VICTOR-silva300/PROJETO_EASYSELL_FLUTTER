import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
} from '@nestjs/common';
import { CompanyService } from './company.service.js';
import { CreateCompanyDto } from './dto/create-company.dto.js';
import { UpdateCompanyDto } from './dto/update-company.dto.js';
import { CreateEmployeeDto } from './dto/create-employee.dto.js';

@Controller('company')
export class CompanyController {
  constructor(private readonly companyService: CompanyService) {}

  @Post()
  create(@Body() createCompanyDto: CreateCompanyDto) {
    return this.companyService.create(createCompanyDto);
  }

  @Post('bootstrap/:userId')
  bootstrap(@Param('userId') userId: string, @Body('name') name: string) {
    return this.companyService.bootstrapForUser(userId, name);
  }

  @Post('employees')
  createEmployee(@Body() dto: CreateEmployeeDto) {
    return this.companyService.createEmployee(dto);
  }

  @Patch('employees/:id')
  updateEmployee(@Param('id') id: string, @Body() dto: Partial<CreateEmployeeDto>) {
    return this.companyService.updateEmployee(id, dto);
  }

  @Delete('employees/:id')
  removeEmployee(@Param('id') id: string) {
    return this.companyService.removeEmployee(id);
  }

  @Get('employees/by-company/:companyId')
  findEmployeesByCompanyId(@Param('companyId') companyId: string) {
    return this.companyService.findEmployeesByCompanyId(companyId);
  }

  @Get('employees/by-name')
  findEmployeesByName(@Query('name') name: string) {
    return this.companyService.findEmployeesByName(name);
  }

  @Get()
  findAll() {
    return this.companyService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.companyService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateCompanyDto: UpdateCompanyDto) {
    return this.companyService.update(id, updateCompanyDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.companyService.remove(id);
  }
}
