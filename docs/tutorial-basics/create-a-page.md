---
sidebar_position: 4
---

# Biblioteca-Codigo


## Carpeta de Biblioteca

Se realisara la convercion de un archivo word o html en texto plano a un pdf base 64 **Para el sistema de activos** este como tal tiene tres subcarpetas y tres archivo. Empesaremos con los archivos y luego con las carpetas

Archivo `src/biblioteca/biblioteca.controller.ts`:
```jsx title="src/biblioteca/biblioteca.controller.ts"
//Importacion de las clases nesesarias
import { Controller, Get, Post, Body, Patch, Param, Delete, Res, Req } from '@nestjs/common';
import { BibliotecaService } from './biblioteca.service';
import { CreateBibliotecaDto } from './dto/create-biblioteca.dto';
import { UpdateBibliotecaDto } from './dto/update-biblioteca.dto';
import { Biblioteca } from './schemas/biblioteca.schema';
import { ApiOperation, ApiProperty, ApiResponse, ApiTags } from '@nestjs/swagger';
import * as fs from 'fs';
import { Response, Request, response } from 'express';
import * as cheerio from 'cheerio';
import * as mammoth from "mammoth";
import * as pdf from 'html-pdf';


class WordtoPdfbase64Dto {
  @ApiProperty({ type:'string', description: 'id del template', required: true })
  id: string;   //Decorador para asignar etiquetas
  @ApiProperty({ type:'string', description: 'archivo word en base64', required: true })
  word: string;   //Decorador para asignar etiquetas
}


@ApiTags('biblioteca')
@Controller('biblioteca')
export class BibliotecaController {   //Construcctor del controlador
  constructor(private readonly bibliotecaService: BibliotecaService) {}
  //decorador que define la ruta y el método HTTP para crear un nuevo activo
  @Post()
  async create(@Body() createBibliotecaDto: CreateBibliotecaDto, @Res() response: Response) {
    try {
      let data=await this.bibliotecaService.create(createBibliotecaDto);
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
      //return data;
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error});
    }
  }
  //decorador que define la ruta y el método HTTP para obtener todos los activos
  @Get()
  async findAll( @Res() response: Response){
    try {
      let data= await this.bibliotecaService.findAll();
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error});
    }
  }
  //decorador que define la ruta y el método HTTP para obtener un activo específico por su ID
  @Get(':id')
  async findOne(@Param('id') id: string, @Res() response: Response) {
    try {
      let data= await this.bibliotecaService.findOne(id);
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error}); 
  }
  // decorador que define la ruta y el método HTTP para actualizar un activo por su ID
  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateBibliotecaDto: UpdateBibliotecaDto, @Res() response: Response){
    try {
      let data= await this.bibliotecaService.update(id, updateBibliotecaDto);
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error});
    }
  }
  //decorador que define la ruta y el método HTTP para eliminar un activo por su ID
  @Delete(':id')
  async remove(@Param('id') id: string, @Res() response: Response) {
    try {
      let data= await this.bibliotecaService.remove(id);
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error});
    }
  }
  //Decoradores para el Swagger
  @ApiOperation({ summary: 'WORD to PDF' })
  @ApiResponse({ status: 200, description: 'Convert the WORD to PDF' })
  @ApiResponse({ status: 400, description: 'Error al convertir archivo' })
  // decorador que define la ruta y el método HTTP para convertir un archivo de Word a PDF en formato base64
  @Post('wordbase64-to-base64pdf')
  async convertwordtopdf(
    @Res() response: Response,
    @Req() request: Request,
    @Body() body: WordtoPdfbase64Dto,
  ) {
    // obtencion de los datos necesarios para la conversión de un archivo Word a PDF.
    let datatemplate= await this.bibliotecaService.findOne(body.id);
    console.log('datatemplate');
    console.log(datatemplate);

    const pdfPath = `${__dirname}/uploads/${Date.now()}.pdf`;
    let html = '';
    let wordPath = '';
      html = Buffer.from(body.word, 'base64').toString('utf8');
      if(html.includes('[Content_Types].xml')){
        wordPath = `${__dirname.replace(/dist\\convert/g, 'uploads/')}${Date.now()}.docx`;
        await fs.writeFileSync(wordPath,html);
      }
      else{
        html=body.word;
      }
    //Recupera el tamaño de la hoja
    const $ = cheerio.load(html);
    const pageSize = $('meta[name="page-size"]').attr('content');
    let format: 'A3' | 'A4' | 'A5' | 'Legal' | 'Letter' | 'Tabloid' = 'Letter';

    if (['A3', 'A4', 'A5', 'Legal', 'Letter', 'Tabloid'].includes(pageSize)) {
      format = pageSize as 'A3' | 'A4' | 'A5' | 'Legal' | 'Letter' | 'Tabloid';
    }
    //Los estilos la cabesera y el pie de pagina
    const currentDate = new Date().toLocaleDateString('es-Es');
    let header='';
    let footer='';
    if(datatemplate.header!==''){
      header=datatemplate.header;
    }
    if(datatemplate.header!==''){
      footer=datatemplate.footer;
      if (footer.includes('${currentDate}')) {
        console.log('reeemplaza♂0do',currentDate);
        footer=footer.replace('${currentDate}',currentDate);
        console.log(footer);
      }
    }

    const options: pdf.CreateOptions = {
      format: format,
      orientation: 'portrait',
      header: {
        height: '30mm',
        contents: `${header}`,
      },
      footer: {
        height: '30mm',
        contents: `${footer}`,
      },
      border:{
        left:"2cm",
        right:"2cm"
      }
    };
    //Realiza la conversión del contenido HTML en texto plano o del contenido de un archivo Word a un archivo PDF utilizando la biblioteca mammoth y html-pdf
    if (wordPath!=='' && (wordPath.includes('.docx') || wordPath!==''&& wordPath.includes('.doc'))) {
      const buffer = Buffer.from(body.word, 'base64');
      
      mammoth.convertToHtml({ buffer:buffer }).then(function (result) {
        html=result.value;
        console.log(html);

        pdf.create(html, options).toFile(pdfPath, function (err, res) {
          if (err) {
            console.log(err);
            response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:err});
          } else {
            console.log(res);
            const pdfContent = fs.readFileSync(pdfPath, 'base64');
            fs.unlinkSync(pdfPath);
            if (wordPath!=='') {
              fs.unlinkSync(wordPath);            
            }
            response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:pdfContent});
          }
        });
      });
    } else {
      pdf.create(html, options).toFile(pdfPath, function (err, res) {
        if (err) {
          console.log(err);
          response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:err});
        } else {
          console.log(res);
          const pdfContent = fs.readFileSync(pdfPath, 'base64');
          fs.unlinkSync(pdfPath);
          if (wordPath!=='') {
            fs.unlinkSync(wordPath);            
          }
          response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:pdfContent});
        }
      });
    }
  }
}
```
### Explicacion Detallada
Son los mismos pasos que en la documentacion de **Activos**

Archivo `src/biblioteca/biblioteca.modulo.ts`:
```jsx title="src/biblioteca/biblioteca.modulo.ts"
//Importacion de las clases nesesarias
import { Module } from '@nestjs/common';
import { BibliotecaService } from './biblioteca.service';
import { BibliotecaController } from './biblioteca.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { Biblioteca, BibliotecaSchema } from './schemas/biblioteca.schema';

@Module({   //Decorador
  imports:[MongooseModule.forFeature([{name:Biblioteca.name,schema:BibliotecaSchema}])],    //Importaciones especificas del modulo
  controllers: [BibliotecaController],    //Controladores asociados al modulo
  providers: [BibliotecaService]    //Servicios asociados al modulo
})
export class BibliotecaModule {}    //Exportacion de la clase
```

### Explicacion Detallada

**import { Module } from '@nestjs/common';**: Importa la clase Module desde **'@nestjs/common'**. Esta clase se utiliza para definir un módulo en NestJS.

**import { BibliotecaService } from './biblioteca.service';**: Importa la clase **BibliotecaService** desde el archivo **'./biblioteca.service'**. Esta clase es el servicio que se encarga de la lógica de negocio relacionada con la biblioteca.

**import { BibliotecaController } from './biblioteca.controller';**: Importa la clase **BibliotecaController** desde el archivo **'./biblioteca.controller'**. Esta clase es el controlador que define las rutas y maneja las solicitudes HTTP relacionadas con la biblioteca.

**import { MongooseModule } from '@nestjs/mongoose';**: Importa el módulo **MongooseModule** desde **@nestjs/mongoose**. Este módulo se utiliza para integrar Mongoose con NestJS y proporciona funcionalidades relacionadas con la base de datos MongoDB.

**import { Biblioteca, BibliotecaSchema } from './schemas/biblioteca.schema';**: Importa la clase Biblioteca y el esquema **BibliotecaSchema** desde el archivo **'./schemas/biblioteca.schema'**. Estos representan el modelo de datos y el esquema de Mongoose para la biblioteca.

**@Module({})**: Decorador que se aplica a la clase **BibliotecaModule** para definir un módulo en NestJS.

**imports: [MongooseModule.forFeature([{name:Biblioteca.name, schema:BibliotecaSchema}])],**: La propiedad imports especifica los módulos importados por **BibliotecaModule**. En este caso, se utiliza MongooseModule.**forFeature()** para importar el modelo Biblioteca y el esquema **BibliotecaSchema** para su uso en el módulo.
```
controllers: [BibliotecaController],: La propiedad controllers especifica los controladores asociados al módulo. En este caso, se incluye BibliotecaController como controlador para gestionar las solicitudes relacionadas con la biblioteca.

providers: [BibliotecaService]: La propiedad providers especifica los proveedores de servicios asociados al módulo. En este caso, se incluye BibliotecaService como proveedor de servicios para proporcionar la lógica de negocio relacionada con la biblioteca.
```

Archivo `src/biblioteca/biblioteca.service.ts`:
```jsx title="src/biblioteca/biblioteca.service.ts"
//Importacion de las clsaes nesesarias
import { Injectable } from '@nestjs/common';
import { CreateBibliotecaDto } from './dto/create-biblioteca.dto';
import { UpdateBibliotecaDto } from './dto/update-biblioteca.dto';
import { Biblioteca } from './schemas/biblioteca.schema';
import { Model } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';

@Injectable()   //decorador
export class BibliotecaService {
  //Constructor da la clase BibliotecaService
  constructor(@InjectModel(Biblioteca.name) private readonly BibliotecaModel: Model<Biblioteca>) {}

//Creacion de un objeto biblioteca
  async create(createBibliotecaDto: CreateBibliotecaDto): Promise<Biblioteca> {
    const created= await this.BibliotecaModel.create(createBibliotecaDto);
    return created;
  }
  //Debuelve una promesa biblioteca[]
  findAll(): Promise<Biblioteca[]> {
    return this.BibliotecaModel.find().exec();
  }
//Debuelve una promesa biblioteca
  findOne(id: string): Promise<Biblioteca> {
    return this.BibliotecaModel.findOne({_id:id}).exec();
  }
//Devuelve una promesa que resuelve un objeto actualizado
  update(id: string, updateBibliotecaDto: UpdateBibliotecaDto): Promise<Biblioteca> {
    return this.BibliotecaModel.findByIdAndUpdate(id,updateBibliotecaDto).exec();
    //return `This action updates a #${id} biblioteca`;
  }
//Devuelve una promesa que resuelve un objeto eliminado
  async remove(id: string) {
    const deleted=await this.BibliotecaModel.findByIdAndRemove({_id:id}).exec();
    return deleted;
  }
}

```

### Explicacion Detallada

**import { Injectable } from '@nestjs/common';**: Importa la clase **Injectable** desde **'@nestjs/common'**. Esta clase se utiliza para marcar la clase BibliotecaService como un servicio inyectable en NestJS.

**import { CreateBibliotecaDto } from './dto/create-biblioteca.dto';**: Importa la clase **CreateBibliotecaDto** desde el archivo **'./dto/create-biblioteca.dto'**. Esta clase es un **DTO (Data Transfer Object)** utilizado para transferir datos de creación de la biblioteca.

**import { UpdateBibliotecaDto } from './dto/update-biblioteca.dto';**: Importa la clase **UpdateBibliotecaDto** desde el archivo **'./dto/update-biblioteca.dto'**. Esta clase es un DTO utilizado para transferir datos de actualización de la biblioteca.

**import { Biblioteca } from './schemas/biblioteca.schema';**: Importa la clase Biblioteca desde el archivo **'./schemas/biblioteca.schema'**. Esta clase representa el modelo de datos de la biblioteca.

**import { Model } from 'mongoose';**: Importa la interfaz Model desde el módulo **'mongoose'**. Esta interfaz se utiliza para definir y manipular los modelos de Mongoose.

**import { InjectModel } from '@nestjs/mongoose';**: Importa la función **InjectModel** desde el módulo **'@nestjs/mongoose'**. Esta función se utiliza para inyectar el modelo de Mongoose en el servicio.

**@Injectable()**: Decorador que se aplica a la clase **BibliotecaService** para marcarla como un servicio inyectable en NestJS.
```
constructor(@InjectModel(Biblioteca.name) private readonly BibliotecaModel: Model<Biblioteca>) {}: El constructor de la clase BibliotecaService que utiliza la función InjectModel para inyectar el modelo de Mongoose correspondiente a la clase Biblioteca. El modelo se asigna a la propiedad BibliotecaModel para su uso posterior en los métodos del servicio.

async create(createBibliotecaDto: CreateBibliotecaDto): Promise<Biblioteca>: Método create que recibe un objeto createBibliotecaDto de tipo CreateBibliotecaDto y devuelve una promesa de tipo Biblioteca. Este método crea una nueva instancia de la biblioteca utilizando el modelo BibliotecaModel y los datos proporcionados en el DTO de creación.

findAll(): Promise<Biblioteca[]>: Método findAll que devuelve una promesa de tipo Biblioteca[]. Este método busca y devuelve todas las instancias de la biblioteca utilizando el modelo BibliotecaModel.

findOne(id: string): Promise<Biblioteca>: Método findOne que recibe un parámetro id de tipo string y devuelve una promesa de tipo Biblioteca. Este método busca y devuelve una instancia de la biblioteca con el ID proporcionado utilizando el modelo BibliotecaModel.

update(id: string, updateBibliotecaDto: UpdateBibliotecaDto): Promise<Biblioteca>: Método update que recibe un parámetro id de tipo string y un objeto updateBibliotecaDto de tipo UpdateBibliotecaDto, y devuelve una promesa de tipo Biblioteca. Este método actualiza una instancia de la biblioteca con el ID proporcionado utilizando el modelo BibliotecaModel y los datos proporcionados en el DTO de actualización.

async remove(id: string): Método remove que recibe un parámetro id de tipo string y devuelve una promesa. Este método elimina una instancia de la biblioteca con el ID proporcionado utilizando el modelo BibliotecaModel
```
## Carpeta DTO

En esta carpeta existe dos archivos uno de crear y otro de actualizar, esta carpeta servira para configurar **la base de datos**

Archivo `src/biblioteca/create-biblioteca.dto.ts`:
```jsx title="src/biblioteca/create-biblioteca.dto.ts"
//Importacion de las clases nesesarias
import { ApiProperty } from "@nestjs/swagger";

export class CreateBibliotecaDto {
    @ApiProperty({ type:'string', description: 'cabecera de pagina', required: false })//Decorador que aplica y define los metadatos de la documentacion API de un 'header'
    readonly header: string;
    @ApiProperty({ type:'string', description: 'pie de pagina', required: false })//Decorador que aplica y define los metadatos de la documentacion API de un 'footer'
    readonly footer: string;//Define la propiedad como una cadena de texto de solo lectura
}
```
### Explicacion Detallada
**import { ApiProperty } from "@nestjs/swagger";**: Importa la **clase ApiProperty** desde el módulo **@nestjs/swagger**. Esta clase se utiliza para decorar las propiedades de la clase DTO y proporcionar metadatos para la documentación de la API generada por Swagger.

**export class CreateBibliotecaDto { }**: Define la clase **CreateBibliotecaDto** que representa un **DTO (Data Transfer Object)** utilizado para transferir datos de creación de una biblioteca.

**@ApiProperty({ type:'string', description: 'cabecera de pagina', required: false })**: Decorador que se aplica a la propiedad header para proporcionar metadatos a Swagger. El metadato **type** indica que el tipo de la propiedad es una cadena (string). El metadato description proporciona una descripción para la propiedad y el metadato required indica que la propiedad no es obligatoria.

**readonly header: string;**: Declaración de la propiedad header que representa la cabecera de la página. La propiedad es de solo lectura **(readonly)** y tiene un tipo de cadena **(string)**.

**@ApiProperty({ type:'string', description: 'pie de pagina', required: false })**: Decorador que se aplica a la propiedad **footer** para proporcionar metadatos a Swagger. El metadato **type** indica que el tipo de la propiedad es una cadena (string). El metadato description proporciona una descripción para la propiedad y el metadato **required** indica que la propiedad no es obligatoria.

**readonly footer: string;**: Declaración de la propiedad **footer** que representa el pie de página. La propiedad es de solo lectura **(readonly)** y tiene un tipo de cadena **(string)**.

Archivo `src/biblioteca/dto/update-biblioteca.dto.ts`:
```jsx title="src/biblioteca/dto/update-biblioteca.dto.ts"
//Realisamos las importaciones de clases nesesarias
import { PartialType } from '@nestjs/swagger';
import { CreateBibliotecaDto } from './create-biblioteca.dto';

export class UpdateBibliotecaDto extends PartialType(CreateBibliotecaDto) {}

```
### Explicacion Detallada
**import { PartialType } from '@nestjs/swagger';**: Importa la clase **PartialType** desde el módulo **@nestjs/swagger**. Esta clase se utiliza para crear un DTO parcial basado en otro DTO existente.

**import { CreateBibliotecaDto } from './create-biblioteca.dto';**: Importa la clase **CreateBibliotecaDto** desde el archivo **create-biblioteca.dto.ts**. Esta es la clase DTO de creación de una biblioteca.

**export class UpdateBibliotecaDto extends PartialType(CreateBibliotecaDto) {}**: Define la clase **UpdateBibliotecaDto** que extiende de **PartialType(CreateBibliotecaDto)**. Esto significa que **UpdateBibliotecaDto** es un DTO parcial basado en **CreateBibliotecaDto**, lo que implica que solo las propiedades marcadas como opcionales en **CreateBibliotecaDto** serán opcionales en UpdateBibliotecaDto.

## Carpeta Entities
En esta carpeta solo tiene un archivo el cual es **Biblioteca.entity.ts**.

Archivo `src/biblioteca/entities/biblioteca.entity.ts`:
```jsx title="src/biblioteca/entities/biblioteca.entity.ts"
export class Biblioteca {} //exportar clase Activo
```
## Carpeta Schemas
**export**: La palabra clave export se utiliza para hacer que la clase Biblioteca sea accesible desde otros archivos o módulos. Al exportar la clase, otros archivos podrán importarla y utilizarla.

**class Activo {}**: Esta es la declaración de la clase Biblioteca. Una clase es una plantilla o modelo para crear objetos. Define las propiedades y métodos que tendrán los objetos creados a partir de ella.

## Carpeta Schemas
En esta carpeta solo tiene un archivo el cual es **Biblioteca.schema.ts**.

Archivo `src/biblioteca/schemas/biblioteca.schema.ts`:
```jsx title="src/biblioteca/schemas/biblioteca.schema.ts"
//Importamos las clases nesesarias
import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { HydratedDocument } from "mongoose";
export type bibliotecaDocument = HydratedDocument<Biblioteca>;//Se define un tipo personalisado

@Schema()//Decorador que se aplica a la clase
export class Biblioteca{
    @Prop()
    header:string//Decorador del'header'

    @Prop()//Decorador del footer
    footer:string
}

export const BibliotecaSchema = SchemaFactory.createForClass(Biblioteca);   //Creacion del esquema de Mongoose
```
## Explicacion Detallada
**import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";**: Importa las decoradores y funciones necesarias de **@nestjs/mongoose** para definir y trabajar con esquemas de Mongoose en NestJS.

**import { HydratedDocument } from "mongoose";**: Importa el tipo **HydratedDocument** de Mongoose, que representa un documento de MongoDB con todos los métodos y propiedades disponibles.
```
export type bibliotecaDocument = HydratedDocument<Biblioteca>;: Define un alias de tipo bibliotecaDocument que es equivalente a HydratedDocument<Biblioteca>. Esto permite utilizar el alias bibliotecaDocument para representar documentos de la colección "Biblioteca" en MongoDB.

@Schema(): Es un decorador que indica que la clase Biblioteca es un esquema de Mongoose. Esto permite definir las propiedades y opciones del esquema dentro de la clase.

export class Biblioteca { ... }: Define la clase Biblioteca, que representa el esquema de una biblioteca en la aplicación.

@Prop(): Es un decorador que se utiliza para marcar una propiedad como una propiedad de Mongoose en el esquema. En este caso, se utiliza para marcar las propiedades header y footer como propiedades del esquema Biblioteca.

header: string y footer: string: Son las propiedades de la clase Biblioteca que representan la cabecera y el pie de página de la biblioteca. Ambas propiedades son de tipo string.

export const BibliotecaSchema = SchemaFactory.createForClass(Biblioteca);: Crea el esquema de Mongoose correspondiente a la clase Biblioteca utilizando la función createForClass proporcionada por SchemaFactory. Esta función toma la clase Biblioteca como argumento y genera el esquema de Mongoose basado en las propiedades y opciones definidas en la clase.
```