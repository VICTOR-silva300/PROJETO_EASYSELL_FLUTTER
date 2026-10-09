import {
  IsNotEmpty,
  IsNumber,
  IsString,
  IsOptional
} from 'class-validator';

export class CreateClienteDto {
    @IsString()
    @IsNotEmpty()
        name: string;

    @IsNotEmpty()
        Numero: string;

    @IsString()
        IdProduto: string;

    @IsString()
        idcompany: string;

    @IsNumber()
        Preco_gasto: Number;

    @IsNumber()
        Quantidade: Number;

    @IsOptional()
    @IsString()
        status?: string;

    @IsOptional()
    @IsString()
        funcionarioId?: string;

}
