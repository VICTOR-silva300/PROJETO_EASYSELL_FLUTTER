import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type ClienteDocument = HydratedDocument<Cliente>;

@Schema({ timestamps: true })
export class Cliente {

  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  Numero: string;

  @Prop({ required: true })
  IdProduto: string;

  @Prop({ required: true })
  idcompany: string;

  @Prop({ required: true })
  Preco_gasto: number;

  @Prop({ required: true })
  Quantidade: number;

  @Prop({ required: true, default: 'Concluída' })
  status: string;

  @Prop({ required: false })
  funcionarioId?: string;
}

export const ClienteSchema = SchemaFactory.createForClass(Cliente);