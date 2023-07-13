---
sidebar_position: 1
---

# HTML-PDF-Codigo
- /src
  - /activo
    - /dto
      - create-activo.dto.ts
      - update-activo.dto.ts
    - /entities
      - activo.entity.ts
    - /schemas
      - activo.schema.ts
    - activo.controller.ts
    - activo.module.ts
    - activo.service.ts
  - /biblioteca
    - /dto
      - create-biblioteca.dto.ts
      - update-biblioteca.dto.ts
    - /entities
      - biblioteca.entity.ts
    - /schemas
      - biblioteca.schema.ts
    - biblioteca.controller.ts
    - biblioteca.module.ts
    - biblioteca.service.ts
  - app.module.ts
  - main.ts



## Main.ts
Archivo `src/main.ts`:

```jsx title="src/main.ts"
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';


async function bootstrap() {
  const app = await NestFactory.create(AppModule,{cors:true});
  const config = new DocumentBuilder()
    .setTitle('API Convert')
    .setDescription('Convert HTML to PDF')
    .setVersion('1.0')
    .addTag('Convert')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  await app.listen(3000);
}
bootstrap();
```

## App.Module.ts
Archivo `src/app.module.ts`:

```jsx title="src/app.module.ts"
import { Module } from '@nestjs/common';
import { ConvertController } from './convert/convert.controller';

@Module({
  imports: [],
  controllers: [ConvertController],
  providers: [],
})
export class AppModule {}
```

## Create-Activo.Dto.ts
Archivo `src/activo/dto/create-activo.dto.ts`:

```jsx title="src/activo/dto/create-activo.dto.ts"
import { ApiProperty } from "@nestjs/swagger";

export class CreateActivoDto {
    @ApiProperty({ type:'string', description: 'cabecera de pagina', required: false })
    readonly header: string;
    @ApiProperty({ type:'string', description: 'pie de pagina', required: false })
    readonly footer: string;
}

```

## Update-Activo.Dto.ts
Archivo `src/activo/dto/update-activo.dto.ts`:

```jsx title="src/activo/dto/update-activo.dto.ts"
import { PartialType } from '@nestjs/swagger';
import { CreateActivoDto } from './create-activo.dto';

export class UpdateActivoDto extends PartialType(CreateActivoDto) {}

```

## Activo.Entity.ts
Archivo `src/activo/entities/activo.entity.ts`:

```jsx title="src/activo/entities/activo.entity.ts"
import { PartialType } from '@nestjs/swagger';
import { CreateActivoDto } from './create-activo.dto';

export class UpdateActivoDto extends PartialType(CreateActivoDto) {}

```

## Activo.Schema.ts
Archivo `src/activo/schemas/activo.schema.ts`:

```jsx title="src/activo/schemas/activo.schema.ts"
import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { HydratedDocument } from "mongoose";
export type ActivoDocument = HydratedDocument<Activo>;

@Schema()
export class Activo{
    @Prop()
    header:string

    @Prop()
    footer:string
}

export const ActivoSchema = SchemaFactory.createForClass(Activo);

```

## Activo.Controller.ts
Archivo `src/activo/activo.controller.ts`:

```jsx title="src/activo/activo.controller.ts"
import { Controller, Get, Post, Body, Patch, Param, Delete, Res, Req } from '@nestjs/common';
import { ActivoService } from './activo.service';
import { CreateActivoDto } from './dto/create-activo.dto';
import { UpdateActivoDto } from './dto/update-activo.dto';
import { Activo } from './schemas/activo.schema';
import * as fs from 'fs';
import { Response, Request } from 'express';
import * as cheerio from 'cheerio';
import mammoth from "mammoth";
import * as pdf from 'html-pdf';
import { ApiOperation, ApiProperty, ApiResponse, ApiTags } from '@nestjs/swagger';

class WordtoPdfbase64Dto {
  @ApiProperty({ type:'string', description: 'id del template', required: true })
  id: string;
  @ApiProperty({ type:'string', description: 'archivo word en base64', required: true })
  word: string;
}

@ApiTags('activo')
@Controller('activo')
export class ActivoController {
  constructor(private readonly activoService: ActivoService) {}

  @Post()
  async create(@Body() createActivoDto: CreateActivoDto) {
    return await this.activoService.create(createActivoDto);
  }

  @Get()
  findAll():Promise<Activo[]> {
    return this.activoService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string):Promise<Activo> {
    return this.activoService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateActivoDto: UpdateActivoDto):Promise<Activo> {
    return this.activoService.update(id, updateActivoDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string):Promise<Activo> {
    return this.activoService.remove(id);
  }

  @ApiOperation({ summary: 'WORD to PDF' })
  @ApiResponse({ status: 200, description: 'Convert the WORD to PDF' })
  @ApiResponse({ status: 400, description: 'Error al convertir archivo' })
  @Post('wordbase64-to-base64pdf')
  async convertwordtopdf(
    @Res() response: Response,
    @Req() request: Request,
    @Body() body: WordtoPdfbase64Dto,
  ) {
    const datatemplate= await this.activoService.findOne(body.id);
    const pdfPath = `${__dirname}/uploads/${Date.now()}.pdf`;
    let html = '';
    let wordPath = '';

    
      html = Buffer.from(body.word, 'base64').toString('utf8');
      if(html.includes('[Content_Types].xml')){
        wordPath = `${__dirname.replace(/dist\\convert/g, 'uploads/')}${Date.now()}.docx`;
        await fs.writeFileSync(wordPath,html);
      }
    

    const $ = cheerio.load(html);
    const pageSize = $('meta[name="page-size"]').attr('content');
    let format: 'A3' | 'A4' | 'A5' | 'Legal' | 'Letter' | 'Tabloid' = 'Letter';

    if (['A3', 'A4', 'A5', 'Legal', 'Letter', 'Tabloid'].includes(pageSize)) {
      format = pageSize as 'A3' | 'A4' | 'A5' | 'Legal' | 'Letter' | 'Tabloid';
    }

    const currentDate = new Date().toLocaleDateString('es-Es');
    let header='';
    let footer='';
    if(datatemplate.header!==''){
      header=datatemplate.header;
    }
    if(datatemplate.header!==''){
      footer=datatemplate.footer;
      if (footer.includes('${currentDate}')) {
        footer=footer.replace('${currentDate}',currentDate);
      }
    }

    const options: pdf.CreateOptions = {
      format: format,
      orientation: 'portrait',
      header: {
        height: '30mm',
        contents: `
          ${header}`,
      },
      footer: {
        height: '30mm',
        contents: `
          ${footer}`,
      },
    };

    if (wordPath!=='' && (wordPath.includes('.docx') || wordPath!==''&& wordPath.includes('.doc'))) {
      const buffer = Buffer.from(body.word, 'base64');
      
      mammoth.convertToHtml({ buffer:buffer }).then(function (result) {
        html = result.value;

        pdf.create(html, options).toFile(pdfPath, function (err, res) {
          if (err) {
            console.log(err);
            response.status(400).json(err);
          } else {
            console.log(res);
            const pdfContent = fs.readFileSync(pdfPath, 'base64');
            fs.unlinkSync(pdfPath);
            if (wordPath!=='') {
              fs.unlinkSync(wordPath);            
            }
            response.status(200).json(pdfContent);
          }
        });
      });
    } else {
      pdf.create(html, options).toFile(pdfPath, function (err, res) {
        if (err) {
          console.log(err);
          response.status(400).json(err);
        } else {
          console.log(res);
          const pdfContent = fs.readFileSync(pdfPath, 'base64');
          fs.unlinkSync(pdfPath);
          if (wordPath!=='') {
            fs.unlinkSync(wordPath);            
          }
          response.status(200).json(pdfContent);
        }
      });
    }
  }
}
```


## Activo.Module.ts
Archivo `src/activo/activo.module.ts`:

```jsx title="src/activo/activo.module.ts"
import { Module } from '@nestjs/common';
import { ActivoService } from './activo.service';
import { ActivoController } from './activo.controller';
import { Activo, ActivoSchema } from './schemas/activo.schema';
import { MongooseModule } from '@nestjs/mongoose';

@Module({
  imports:[MongooseModule.forFeature([{name:Activo.name,schema:ActivoSchema}])],
  controllers: [ActivoController],
  providers: [ActivoService]
})
export class ActivoModule {}

```

## Activo.Service.ts
Archivo `src/activo/activo.service.ts`:

```jsx title="src/activo/activo.service.ts"
import { Injectable } from '@nestjs/common';
import { CreateActivoDto } from './dto/create-activo.dto';
import { UpdateActivoDto } from './dto/update-activo.dto';
import { InjectModel } from '@nestjs/mongoose';
import { Activo } from './schemas/activo.schema';
import { Model } from 'mongoose';

@Injectable()
export class ActivoService {
  constructor(@InjectModel(Activo.name) private readonly ActivoModel: Model<Activo>) {}
  
  async create(createActivoDto: CreateActivoDto) {
    const created= await this.ActivoModel.create(createActivoDto);
    return created;
  }

  findAll(): Promise<Activo[]> {
    return this.ActivoModel.find().exec();
  }

  findOne(id: string): Promise<Activo> {
    return this.ActivoModel.findOne({_id:id}).exec();
  }

  update(id: string, updateActivoDto: UpdateActivoDto): Promise<Activo> {
    return this.ActivoModel.findByIdAndUpdate(id,updateActivoDto).exec();
  }

  async remove(id: string): Promise<Activo> {
    const deleted=await this.ActivoModel.findByIdAndRemove({_id:id}).exec();
    return deleted;
  }
}

```

## Create-Biblioteca.Dto.ts
Archivo `src/biblioteca/dto/create-biblioteca.dto.ts`:

```jsx title="src/biblioteca/dto/create-biblioteca.dto.ts"
import { ApiProperty } from "@nestjs/swagger";

export class CreateBibliotecaDto {
    @ApiProperty({ type:'string', description: 'cabecera de pagina', required: false })
    readonly header: string;
    @ApiProperty({ type:'string', description: 'pie de pagina', required: false })
    readonly footer: string;
}

```

## Update-Biblioteca.Dto.ts
Archivo `src/biblioteca/dto/update-biblioteca.dto.ts`:

```jsx title="src/biblioteca/dto/update-biblioteca.dto.ts"
import { PartialType } from '@nestjs/swagger';
import { CreateBibliotecaDto } from './create-biblioteca.dto';

export class UpdateBibliotecaDto extends PartialType(CreateBibliotecaDto) {}

```

## Biblioteca.Entity.ts
Archivo `src/biblioteca/entities/biblioteca.entity.ts`:

```jsx title="src/biblioteca/entities/biblioteca.entity.ts"
import { PartialType } from '@nestjs/swagger';
import { CreateBibliotecaDto } from './create-biblioteca.dto';

export class UpdateBibliotecaDto extends PartialType(CreateBibliotecaDto) {}

```

## Biblioteca.Schema.ts
Archivo `src/biblioteca/schemas/biblioteca.schema.ts`:

```jsx title="src/biblioteca/schemas/biblioteca.schema.ts"
import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { HydratedDocument } from "mongoose";
export type bibliotecaDocument = HydratedDocument<Biblioteca>;

@Schema()
export class Biblioteca{
    @Prop()
    header:string

    @Prop()
    footer:string
}

export const BibliotecaSchema = SchemaFactory.createForClass(Biblioteca);

```

## Biblioteca.Controller.ts
Archivo `src/biblioteca/biblioteca.controller.ts`:

```jsx title="src/biblioteca/biblioteca.controller.ts"
import { Controller, Get, Post, Body, Patch, Param, Delete, Res, Req } from '@nestjs/common';
import { BibliotecaService } from './biblioteca.service';
import { CreateBibliotecaDto } from './dto/create-biblioteca.dto';
import { UpdateBibliotecaDto } from './dto/update-biblioteca.dto';
import { Biblioteca } from './schemas/biblioteca.schema';
import { ApiOperation, ApiProperty, ApiResponse, ApiTags } from '@nestjs/swagger';
import * as fs from 'fs';
import { Response, Request } from 'express';
import * as cheerio from 'cheerio';
import mammoth from "mammoth";
import * as pdf from 'html-pdf';


class WordtoPdfbase64Dto {
  @ApiProperty({ type:'string', description: 'id del template', required: true })
  id: string;
  @ApiProperty({ type:'string', description: 'archivo word en base64', required: true })
  word: string;
}


@ApiTags('biblioteca')
@Controller('biblioteca')
export class BibliotecaController {
  constructor(private readonly bibliotecaService: BibliotecaService) {}

  @Post()
  async create(@Body() createBibliotecaDto: CreateBibliotecaDto) {
    return await this.bibliotecaService.create(createBibliotecaDto);
  }

  @Get()
  findAll():Promise<Biblioteca[]> {
    return this.bibliotecaService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string):Promise<Biblioteca> {
    return this.bibliotecaService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateBibliotecaDto: UpdateBibliotecaDto):Promise<Biblioteca> {
    return this.bibliotecaService.update(id, updateBibliotecaDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.bibliotecaService.remove(id);
  }

  @ApiOperation({ summary: 'WORD to PDF' })
  @ApiResponse({ status: 200, description: 'Convert the WORD to PDF' })
  @ApiResponse({ status: 400, description: 'Error al convertir archivo' })
  @Post('wordbase64-to-base64pdf')
  async convertwordtopdf(
    @Res() response: Response,
    @Req() request: Request,
    @Body() body: WordtoPdfbase64Dto,
  ) {
    const datatemplate= await this.bibliotecaService.findOne(body.id);

    const pdfPath = `${__dirname}/uploads/${Date.now()}.pdf`;
    let html = '';
    let wordPath = '';

      html = Buffer.from(body.word, 'base64').toString('utf8');
      if(html.includes('[Content_Types].xml')){
        wordPath = `${__dirname.replace(/dist\\convert/g, 'uploads/')}${Date.now()}.docx`;
        await fs.writeFileSync(wordPath,html);
      }
    

    const $ = cheerio.load(html);
    const pageSize = $('meta[name="page-size"]').attr('content');
    let format: 'A3' | 'A4' | 'A5' | 'Legal' | 'Letter' | 'Tabloid' = 'Letter';

    if (['A3', 'A4', 'A5', 'Legal', 'Letter', 'Tabloid'].includes(pageSize)) {
      format = pageSize as 'A3' | 'A4' | 'A5' | 'Legal' | 'Letter' | 'Tabloid';
    }

    const currentDate = new Date().toLocaleDateString('es-Es');
    let header='';
    let footer='';
    if(datatemplate.header!==''){
      header=datatemplate.header;
    }
    if(datatemplate.header!==''){
      footer=datatemplate.footer;
      if (footer.includes('${currentDate}')) {
        footer=footer.replace('${currentDate}',currentDate);
      }
    }

    const options: pdf.CreateOptions = {
      format: format,
      orientation: 'portrait',
      header: {
        height: '30mm',
        contents: `
          ${header}`,
      },
      footer: {
        height: '30mm',
        contents: `
          ${footer}`,
      },
    };

    if (wordPath!=='' && (wordPath.includes('.docx') || wordPath!==''&& wordPath.includes('.doc'))) {
      const buffer = Buffer.from(body.word, 'base64');
      
      mammoth.convertToHtml({ buffer:buffer }).then(function (result) {
        html = result.value;

        pdf.create(html, options).toFile(pdfPath, function (err, res) {
          if (err) {
            console.log(err);
            response.status(400).json(err);
          } else {
            console.log(res);
            const pdfContent = fs.readFileSync(pdfPath, 'base64');
            fs.unlinkSync(pdfPath);
            if (wordPath!=='') {
              fs.unlinkSync(wordPath);            
            }
            response.status(200).json(pdfContent);
          }
        });
      });
    } else {
      pdf.create(html, options).toFile(pdfPath, function (err, res) {
        if (err) {
          console.log(err);
          response.status(400).json(err);
        } else {
          console.log(res);
          const pdfContent = fs.readFileSync(pdfPath, 'base64');
          fs.unlinkSync(pdfPath);
          if (wordPath!=='') {
            fs.unlinkSync(wordPath);            
          }
          response.status(200).json(pdfContent);
        }
      });
    }
  }
}

```

## Biblioteca.Module.ts
Archivo `src/biblioteca/biblioteca.module.ts`:

```jsx title="src/biblioteca/biblioteca.module.ts"
import { Module } from '@nestjs/common';
import { BibliotecaService } from './biblioteca.service';
import { BibliotecaController } from './biblioteca.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { Biblioteca, BibliotecaSchema } from './schemas/biblioteca.schema';

@Module({
  imports:[MongooseModule.forFeature([{name:Biblioteca.name,schema:BibliotecaSchema}])],
  controllers: [BibliotecaController],
  providers: [BibliotecaService]
})
export class BibliotecaModule {}

```

## Biblioteca.Service.ts
Archivo `src/biblioteca/biblioteca.service.ts`:

```jsx title="src/biblioteca/biblioteca.service.ts"
import { Injectable } from '@nestjs/common';
import { CreateBibliotecaDto } from './dto/create-biblioteca.dto';
import { UpdateBibliotecaDto } from './dto/update-biblioteca.dto';
import { Biblioteca } from './schemas/biblioteca.schema';
import { Model } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';

@Injectable()
export class BibliotecaService {

  constructor(@InjectModel(Biblioteca.name) private readonly BibliotecaModel: Model<Biblioteca>) {}


  async create(createBibliotecaDto: CreateBibliotecaDto): Promise<Biblioteca> {
    const created= await this.BibliotecaModel.create(createBibliotecaDto);
    return created;
  }

  findAll(): Promise<Biblioteca[]> {
    return this.BibliotecaModel.find().exec();
  }

  findOne(id: string): Promise<Biblioteca> {
    return this.BibliotecaModel.findOne({_id:id}).exec();
  }

  update(id: string, updateBibliotecaDto: UpdateBibliotecaDto): Promise<Biblioteca> {
    return this.BibliotecaModel.findByIdAndUpdate(id,updateBibliotecaDto).exec();
    //return `This action updates a #${id} biblioteca`;
  }

  async remove(id: string) {
    const deleted=await this.BibliotecaModel.findByIdAndRemove({_id:id}).exec();
    return deleted;
  }
}

```