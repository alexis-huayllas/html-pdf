---
sidebar_position: 3
---

# Activo-Codigo

## Carpeta de activos

Se realisara la convercion de un archivo word y html texto plano a un pdf base 64 **Para el sistema de activos** este como tal tiene tres subcarpetas y tres archivo. Empesaremos con los archivos y luego con las carpetas

Archivo `src/activo/activo.controller.ts`:
```jsx title="src/activo/activo.controller.ts"
//Importacion de las clases nesesarias
import { Controller, Get, Post, Body, Patch, Param, Delete, Res, Req } from '@nestjs/common';
import { ActivoService } from './activo.service';
import { CreateActivoDto } from './dto/create-activo.dto';
import { UpdateActivoDto } from './dto/update-activo.dto';
import { Activo } from './schemas/activo.schema';
import * as fs from 'fs';
import { Response, Request } from 'express';
import * as cheerio from 'cheerio';
import * as mammoth from "mammoth";
import * as pdf from 'html-pdf';
import { ApiOperation, ApiProperty, ApiResponse, ApiTags } from '@nestjs/swagger';

class WordtoPdfbase64Dto {
  @ApiProperty({ type:'string', description: 'id del template', required: true })
  id: string;   //Decorador para asignar etiquetas
  @ApiProperty({ type:'string', description: 'archivo word en base64', required: true })    //Decorador para asignar etiquetas
  word: string;
}

@ApiTags('activo')
@Controller('activo')
export class ActivoController { //Construcctor del controlador
  constructor(private readonly activoService: ActivoService) {}
   //decorador que define la ruta y el método HTTP para crear un nuevo activo
  @Post()  
  async create(@Body() createActivoDto: CreateActivoDto, @Res() response: Response) {
    try {
      let data=await this.activoService.create(createActivoDto);
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
      //return data;
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error});
    }
  }
   //decorador que define la ruta y el método HTTP para obtener todos los activos
  @Get()
  async findAll( @Res() response: Response) {
    try {
      let data= await this.activoService.findAll();
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error});
    } 
  }
  //decorador que define la ruta y el método HTTP para obtener un activo específico por su ID
  @Get(':id')
  async findOne(@Param('id') id: string, @Res() response: Response) {
    try {
      let data= await this.activoService.findOne(id);
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error});
    }
  }
  // decorador que define la ruta y el método HTTP para actualizar un activo por su ID
  @Patch(':id')
  async update(@Param('id') id: string, @Body() updateActivoDto: UpdateActivoDto, @Res() response: Response) {
    try {
      let data= await this.activoService.update(id, updateActivoDto);
      response.status(200).json({status:200,error:false,mensaje:"se ejecuto correctamente",response:data});
    } catch (error) {
      response.status(400).json({status:400,error:true,mensaje:"se produjo un error al consultar a la base de datos",response:error});
    } 
  }
  //decorador que define la ruta y el método HTTP para eliminar un activo por su ID
  @Delete(':id')
  async remove(@Param('id') id: string, @Res() response: Response)
    try {
      let data= await this.activoService.remove(id);
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
    let datatemplate= await this.activoService.findOne(body.id);
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
        footer=footer.replace('${currentDate}',currentDate);
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
        html = result.value;
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
**import { Controller, Get, Post, Body, Patch, Param, Delete, Res, Req } from '@nestjs/common';**: Importa los decoradores y funciones necesarios de **@nestjs/common** para definir un controlador en NestJS.
**import { BibliotecaService } from './biblioteca.service';**: Importa la clase **BibliotecaService** que contiene la lógica de negocio relacionada con las bibliotecas.
**import { CreateBibliotecaDto } from './dto/create-biblioteca.dto';**: Importa la clase **CreateBibliotecaDto** que define la estructura de los datos necesarios para crear una biblioteca.
**import { UpdateBibliotecaDto } from './dto/update-biblioteca.dto';**: Importa la clase **UpdateBibliotecaDto** que define la estructura de los datos necesarios para actualizar una biblioteca.
**import { Biblioteca } from './schemas/biblioteca.schema';**: Importa la clase **Biblioteca** que representa el esquema de una biblioteca en la base de datos.
**import { ApiOperation, ApiProperty, ApiResponse, ApiTags } from '@nestjs/swagger';**: Importa los decoradores relacionados con **Swagger** para documentar la API.
**import * as fs from 'fs';**: Importa el módulo fs de Node.js para trabajar con el sistema de archivos.
**import { Response, Request, response } from 'express';**: Importa las interfaces Response y Request de Express para trabajar con las respuestas y solicitudes HTTP.
**import * as cheerio from 'cheerio';**: Importa el módulo cheerio para analizar y manipular HTML en el servidor.
**import * as mammoth from "mammoth";**: Importa el módulo mammoth para convertir documentos de Word a HTML.
**import * as pdf from 'html-pdf';**: Importa el módulo html-pdf para generar archivos PDF a partir de HTML.
**class WordtoPdfbase64Dto { ... }**: Define la clase **WordtoPdfbase64Dto**, que representa la estructura de datos necesaria para convertir un archivo de Word a PDF. Esta clase tiene dos propiedades: id que representa el ID del template y word que representa el archivo de Word en formato base64.
**@ApiTags('activo')**: Es un decorador que se utiliza para asignar etiquetas a nivel de controlador en Swagger. En este caso, se etiqueta el controlador como 'activo'.
**@Controller('activo')**: Es un decorador que indica que la clase **ActivoController** es un controlador y define el prefijo de ruta **'/activo'** para todas las rutas dentro de este controlador.
**constructor(private readonly activoService: ActivoService) {}**: Define el constructor del controlador e inyecta una instancia de **ActivoService** para acceder a los métodos y lógica de negocio relacionados con los activos.
**@Post()**: Es un decorador que define la ruta y el método HTTP para crear un nuevo activo. Este método maneja las solicitudes POST a **'/activo'** y utiliza el decorador **@Body()** para obtener los datos del cuerpo de la solicitud.
**async create(@Body() createActivoDto: CreateActivoDto, @Res() response: Response) { ... }**: Define el método create que se ejecuta cuando se realiza una solicitud POST a **'/activo'**. Toma el cuerpo de la solicitud y la respuesta como parámetros. Dentro del método, se llama al método create del servicio ActivoService para crear un nuevo activo utilizando los datos proporcionados. La respuesta se envía al cliente en formato JSON.
**@Get()**: Es un decorador que define la ruta y el método HTTP para obtener todos los activos. Este método maneja las solicitudes GET a **'/activo'**.
**async findAll(@Res() response: Response) { ... }**: Define el método findAll que se ejecuta cuando se realiza una solicitud GET a **'/activo'**. Toma la respuesta como parámetro y dentro del método se llama al método findAll del servicio ActivoService para obtener todos los activos. La respuesta se envía al cliente en formato JSON.
**@Get(':id')**: Es un decorador que define la ruta y el método HTTP para obtener un activo específico por su ID. Este método maneja las solicitudes GET a **'/activo/:id'** donde **':id'** es el ID del activo.
**async findOne(@Param('id') id: string, @Res() response: Response) { ... }**: Define el método findOne que se ejecuta cuando se realiza una solicitud GET a **'/activo/:id'**. Toma el parámetro de ruta **'id'** y la respuesta como parámetros. Dentro del método, se llama al método findOne del servicio ActivoService para obtener el activo correspondiente al ID proporcionado. La respuesta se envía al cliente en formato JSON.
**@Patch(':id')**: Es un decorador que define la ruta y el método HTTP para actualizar un activo por su ID. Este método maneja las solicitudes PATCH a **'/activo/:id'** donde **':id'** es el ID del activo.

**async update(@Param('id') id: string, @Body() updateActivoDto: UpdateActivoDto, @Res() response: Response) { ... }**: Define el método update que se ejecuta cuando se realiza una solicitud PATCH a **'/activo/:id'**. Toma el parámetro de ruta **'id'**, los datos del cuerpo de la solicitud y la respuesta como parámetros. Dentro del método, se llama al método update del servicio ActivoService para actualizar el activo correspondiente al ID proporcionado con los datos proporcionados. La respuesta se envía al cliente en formato JSON.
**@Delete(':id')**: Es un decorador que define la ruta y el método HTTP para eliminar un activo por su ID. Este método maneja las solicitudes DELETE a **'/activo/:id'** donde **':id'** es el ID del activo.
**async remove(@Param('id') id: string, @Res() response: Response) { ... }**: Define el método remove que se ejecuta cuando se realiza una solicitud DELETE a **'/activo/:id'**. Toma el parámetro de ruta **'id'** y la respuesta como parámetros. Dentro del método, se llama al método remove del servicio **ActivoService** para eliminar el activo correspondiente al ID proporcionado. La respuesta se envía al cliente en formato JSON.
**@ApiOperation({ summary: 'WORD to PDF' })**: Es un decorador que se utiliza para documentar el método convertwordtopdf en Swagger. Proporciona un resumen descriptivo de lo que hace el método.
**@ApiResponse({ status: 200, description: 'Convert the WORD to PDF' })**: Es un decorador que se utiliza para documentar la respuesta exitosa del método convertwordtopdf en Swagger. Indica que la solicitud fue exitosa y proporciona una descripción del resultado.
**@ApiResponse({ status: 400, description: 'Error al convertir archivo' })**: Es un decorador que se utiliza para documentar la respuesta de error del método convertwordtopdf en Swagger. Indica que se produjo un error durante la conversión del archivo y proporciona una descripción del error.
**@Post('wordbase64-to-base64pdf')**: Es un decorador que define la ruta y el método HTTP para convertir un archivo de Word a PDF en formato base64. Este método maneja las solicitudes POST a **'/activo/wordbase64-to-base64pdf'**.
**async convertwordtopdf(@Res() response: Response, @Req() request: Request, @Body() body: WordtoPdfbase64Dto) { ... }**: Define el método **convertwordtopdf** que se ejecuta cuando se realiza una solicitud POST a **'/activo/wordbase64-to-base64pdf'**. Toma la respuesta, la solicitud y los datos del cuerpo de la solicitud como parámetros. Dentro del método, se llama al método **findOne** del servicio **ActivoService** para obtener los datos de una plantilla específica. Luego, se convierte el archivo de Word en formato base64 a HTML y se genera un archivo PDF a partir de ese HTML. Finalmente, se envía el contenido del archivo PDF en formato base64 como respuesta al cliente.

Archivo `src/activo/activo.modulo.ts`:
```jsx title="src/activo/activo.modulo.ts"
//Importacion de las clases nesesarias
import { Module } from '@nestjs/common';
import { ActivoService } from './activo.service';
import { ActivoController } from './activo.controller';
import { Activo, ActivoSchema } from './schemas/activo.schema';
import { MongooseModule } from '@nestjs/mongoose';

@Module({       //Decorador
  imports:[MongooseModule.forFeature([{name:Activo.name,schema:ActivoSchema}])],        //Importacion espesificas de los modulos
  controllers: [ActivoController],      //Controladores especificos
  providers: [ActivoService]        // Proveedores esepecificos
})
export class ActivoModule {}        //Exportacion de la clase

```

### Explicacion Detallada
**import { Module } from '@nestjs/common';**: Importa la clase Module de **@nestjs/common**. Esta clase se utiliza para definir un módulo en NestJS.

**import { ActivoService } from './activo.service';**: Importa la clase **ActivoService** desde el archivo **'/activo.service'**. Esto proporciona acceso a los servicios relacionados con el modelo Activo.

**import { ActivoController } from './activo.controller';**: Importa la clase **ActivoController** desde el archivo **'./activo.controller'**. Esto proporciona acceso a las rutas y controladores relacionados con el modelo Activo.

**import { Activo, ActivoSchema } from './schemas/activo.schema';**: Importa la clase Activo y el esquema **ActivoSchema** desde el archivo **'./schemas/activo.schema'**. Estas importaciones se utilizan para definir el esquema y el modelo de Mongoose para el modelo Activo.

**import { MongooseModule } from '@nestjs/mongoose';**: Importa la clase **MongooseModule** de **@nestjs/mongoose**. Esta clase se utiliza para integrar Mongoose con NestJS y proporciona funcionalidades para la conexión y configuración de la base de datos MongoDB.

**@Module({ ... })**: Esta es una decoración que se aplica a la clase **ActivoModule** para indicar que es un módulo de NestJS. Se utilizan varias opciones dentro de **{ ... }** para configurar el módulo.

**imports: [MongooseModule.forFeature([{name: Activo.name, schema: ActivoSchema}])],**: La opción imports especifica los módulos importados en el módulo actual. En este caso, se utiliza **MongooseModule.forFeature()** para importar el esquema y el modelo de Mongoose para el modelo Activo. Esto permite utilizar las funcionalidades de Mongoose en el módulo.

**controllers: [ActivoController],**: La opción controllers especifica los controladores que están registrados en el módulo actual. En este caso, se registra el controlador **ActivoController** para manejar las rutas y las solicitudes relacionadas con el modelo Activo.

**providers: [ActivoService]**: La opción providers especifica los proveedores de servicios que están registrados en el módulo actual. En este caso, se registra el servicio **ActivoService** para proporcionar funcionalidades relacionadas con el modelo Activo.

Archivo `src/activo/activo.service.ts`:
```jsx title="src/activo/activo.service.ts"
//Realisamos las importaciones nesesarias
import { Injectable } from '@nestjs/common';
import { CreateActivoDto } from './dto/create-activo.dto';
import { UpdateActivoDto } from './dto/update-activo.dto';
import { InjectModel } from '@nestjs/mongoose';
import { Activo } from './schemas/activo.schema';
import { Model } from 'mongoose';

@Injectable()       //Decorador
export class ActivoService {
//Constructor de la clase ActivoService
  constructor(@InjectModel(Activo.name) private readonly ActivoModel: Model<Activo>) {}
  //Creacion de un objeto activo
  async create(createActivoDto: CreateActivoDto) {
    const created= await this.ActivoModel.create(createActivoDto);
    return created;
  }
    //Debuelve una promesa
  findAll(): Promise<Activo[]> {
    return this.ActivoModel.find().exec();
  }
    //Devuelve una promesa de tipo  activo
  findOne(id: string): Promise<Activo> {
    return this.ActivoModel.findOne({_id:id}).exec();
  }
    //Devuelve una promesa que resuelve un objeto actualizado
  update(id: string, updateActivoDto: UpdateActivoDto): Promise<Activo> {
    return this.ActivoModel.findByIdAndUpdate(id,updateActivoDto).exec();
  }
    //Devuelve una promesa que resuelve un objeto eliminado
  async remove(id: string): Promise<Activo> {
    const deleted=await this.ActivoModel.findByIdAndRemove({_id:id}).exec();
    return deleted;
  }
}
```
### Explicacion Detallada
```
import { Injectable } from '@nestjs/common';: Importa la clase Injectable desde '@nestjs/common'. Esta clase se utiliza para marcar la clase ActivoService como un proveedor de servicios inyectable en NestJS.

import { CreateActivoDto } from './dto/create-activo.dto';: Importa la clase CreateActivoDto desde el archivo './dto/create-activo.dto'. Esta clase representa el DTO (Objeto de Transferencia de Datos) utilizado para crear un nuevo objeto Activo.

import { UpdateActivoDto } from './dto/update-activo.dto';: Importa la clase UpdateActivoDto desde el archivo './dto/update-activo.dto'. Esta clase representa el DTO utilizado para actualizar un objeto Activo existente.

import { InjectModel } from '@nestjs/mongoose';: Importa la función InjectModel desde @nestjs/mongoose. Esta función se utiliza para inyectar el modelo de Mongoose en el servicio.

import { Activo } from './schemas/activo.schema';: Importa la clase Activo desde el archivo './schemas/activo.schema'. Esta clase representa el modelo de datos de Mongoose para el objeto Activo.

import { Model } from 'mongoose';: Importa la clase Model desde 'mongoose'. Esta clase se utiliza para definir el tipo del modelo de datos de Mongoose.

@Injectable(): Esta es una decoración que se aplica a la clase ActivoService para indicar que es un proveedor de servicios inyectable en NestJS.

constructor(@InjectModel(Activo.name) private readonly ActivoModel: Model<Activo>) {}: El constructor de la clase ActivoService recibe el modelo ActivoModel inyectado utilizando @InjectModel(Activo.name). Esto permite acceder al modelo de datos de Mongoose para realizar operaciones en la base de datos.

async create(createActivoDto: CreateActivoDto): El método create recibe un objeto createActivoDto del tipo CreateActivoDto y crea un nuevo objeto Activo utilizando el modelo ActivoModel.

findAll(): Promise<Activo[]>: El método findAll devuelve una promesa que resuelve en un array de objetos Activo. Utiliza el método find() del modelo ActivoModel para buscar todos los objetos Activo en la base de datos.

findOne(id: string): Promise<Activo>: El método findOne recibe un parámetro id y devuelve una promesa que resuelve en un objeto Activo. Utiliza el método findOne() del modelo ActivoModel para buscar un objeto Activo por su ID en la base de datos.

update(id: string, updateActivoDto: UpdateActivoDto): Promise<Activo>: El método update recibe un parámetro id y un objeto updateActivoDto del tipo UpdateActivoDto. Devuelve una promesa que resuelve en el objeto Activo actualizado. Utiliza el método findByIdAndUpdate() del modelo ActivoModel para buscar un objeto Activo por su ID y actualizar sus propiedades en la base de datos.

async remove(id: string): Promise<Activo>: El método remove recibe un parámetro id y devuelve una promesa que resuelve en el objeto Activo eliminado. Utiliza el método findByIdAndRemove() del modelo ActivoModel para buscar un objeto Activo por su ID y eliminarlo de la base de datos.
```

## Carpeta DTO

En esta carpeta existe dos archivos uno de crear y otro de actualizar, esta carpeta servira para configurar **la base de datos**

Archivo `src/activo/dto/create-activo.dto.ts`:

```jsx title="src/activo/dto/create-activo.dto.ts"
import { ApiProperty } from "@nestjs/swagger";    //Importacion del decorador 

export class CreateActivoDto {    //Definicion de la clase
    @ApiProperty({ type:'string', description: 'cabecera de pagina', required: false })   //Decorador que aplica y define los metadatos de la documentacion API de un 'header'
    readonly header: string;
    @ApiProperty({ type:'string', description: 'pie de pagina', required: false })    //Decorador que aplica y define los metadatos de la documentacion API de un 'footer'
    readonly footer: string;    //Define la propiedad como una cadena de texto de solo lectura
}

```
### Explicacion Detallada

**import { ApiProperty } from "@nestjs/swagger"**; Esto importa la decoración ApiProperty de la biblioteca **@nestjs/swagger**. La decoración **ApiProperty** se utiliza para describir las propiedades de una entidad en la documentación de la API.

**export class CreateActivoDto { ... }**: Esta es la definición de la clase CreateActivoDto que representa el objeto de transferencia de datos (DTO) utilizado para crear un nuevo activo.

**@ApiProperty({ type:'string', description: 'cabecera de pagina', required: false })**: Esta decoración se aplica a la propiedad header y define sus metadatos para la documentación de la API. **type** especifica el tipo de datos de la propiedad, description proporciona una descripción de la propiedad y **required** indica si la propiedad es obligatoria o no. En este caso, header es opcional ya que **required** se establece en false.

**readonly header: string;**: Esto define la propiedad **header** como una cadena de texto y se establece como de solo lectura (readonly). Al marcarla como **readonly**, se asegura de que la propiedad no pueda ser modificada después de la creación del objeto **CreateActivoDto**.

**@ApiProperty({ type:'string', description: 'pie de pagina', required: false })**: Esta decoración se aplica a la propiedad **footer** y define sus metadatos para la documentación de la API. Al igual que en el caso de **header**, type especifica el tipo de datos de la propiedad, description proporciona una descripción y required indica si la propiedad es obligatoria. En este caso, **footer** también es opcional.

**readonly footer: string;**: Esto define la propiedad **footer** como una cadena de texto de solo lectura.


Archivo `src/activo/dto/update-activo.dto.ts`:
```jsx title="src/activo/dto/update-activo.dto.ts"
//Realisamos las importaciones de clases nesesarias
import { PartialType } from '@nestjs/swagger';     
import { CreateActivoDto } from './create-activo.dto';    

export class UpdateActivoDto extends PartialType(CreateActivoDto) {}

```

### Explicacion Detallada
```
import { PartialType } from '@nestjs/swagger';: Esto importa la función PartialType de la biblioteca @nestjs/swagger. PartialType se utiliza para crear un DTO parcial basado en otro DTO existente, lo que significa que heredará las propiedades del DTO original y las marcará como opcionales.

import { CreateActivoDto } from './create-activo.dto';: Esto importa la clase CreateActivoDto desde el archivo create-activo.dto. El DTO CreateActivoDto es el DTO original del que se creará el DTO parcial.

export class UpdateActivoDto extends PartialType(CreateActivoDto) {}: Esta es la definición de la clase UpdateActivoDto que extiende PartialType(CreateActivoDto). Al extender PartialType(CreateActivoDto), la clase UpdateActivoDto heredará las propiedades de CreateActivoDto y las marcará como opcionales.
```

## Carpeta Entities
En esta carpeta solo tiene un archivo el cual es **Activo.entity.ts**.

Archivo `src/activo/entities/activo.entity.ts`:
```jsx title="src/activo/entities/activo.entity.ts"
export class Activo {} //exportar clase Activo
```

## Explicacion Detallada
**export**: La palabra clave export se utiliza para hacer que la clase Activo sea accesible desde otros archivos o módulos. Al exportar la clase, otros archivos podrán importarla y utilizarla.

**class Activo {}**: Esta es la declaración de la clase Activo. Una clase es una plantilla o modelo para crear objetos. Define las propiedades y métodos que tendrán los objetos creados a partir de ella.

## Carpeta Schemas
En esta carpeta solo tiene un archivo el cual es **Activo.schema.ts**.

Archivo `src/activo/schemas/activo.schema.ts`:
```jsx title="src/activo/schemas/activo.schema.ts"
import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";     //importacion para mongoose
import { HydratedDocument } from "mongoose";        
export type ActivoDocument = HydratedDocument<Activo>;      //Se define un tipo personalisado

@Schema()       //Decorador que se aplica a la clase
export class Activo{        //Se define la clase
    @Prop()     //Decorador del'header'
    header:string

    @Prop()     //Decorador del footer
    footer:string
}

export const ActivoSchema = SchemaFactory.createForClass(Activo);       //Creacion del esquema de Mongoose
```
## Explicacion Detallada
```
import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";: Estas importaciones son necesarias para trabajar con Mongoose, una biblioteca de ODM (Object Document Mapper) para MongoDB en NestJS. Prop se utiliza para definir propiedades de un esquema, Schema es la decoración para definir un esquema de Mongoose y SchemaFactory se utiliza para crear instancias de esquemas de Mongoose.

export type ActivoDocument = HydratedDocument<Activo>;: Aquí se define un tipo personalizado llamado ActivoDocument. Este tipo se utiliza para representar el documento de Mongoose completo y enriquecido para la clase Activo.

@Schema(): Esta es una decoración que se aplica a la clase Activo para indicar que es un esquema de Mongoose. Esta decoración permite definir las propiedades del esquema y otros metadatos.

export class Activo { ... }: Aquí se define la clase Activo, que representa un documento del modelo Activo. Esta clase está decorada con @Schema(), lo que significa que se utilizará para definir la estructura y los datos almacenados en la base de datos MongoDB.

@Prop(): Esta decoración se aplica a las propiedades header y footer de la clase Activo. @Prop() indica que estas propiedades serán campos en el esquema de Mongoose. Esto permite almacenar y acceder a estos valores en la base de datos.

export const ActivoSchema = SchemaFactory.createForClass(Activo);: Aquí se crea el esquema de Mongoose para la clase Activo. SchemaFactory.createForClass() es un método proporcionado por @nestjs/mongoose que toma la clase Activo y genera automáticamente el esquema de Mongoose correspondiente utilizando las decoraciones y propiedades definidas en la clase. El esquema generado se asigna a la constante ActivoSchema, que se puede utilizar posteriormente para definir un modelo de Mongoose y realizar operaciones de base de datos.
```