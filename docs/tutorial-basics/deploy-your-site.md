---
sidebar_position: 1
---

# Main
## Inicio de la Aplicación

Aquí configuraremos el **Inicio de la Aplicación**  en `src/main.ts` 

```jsx title="src/main.ts"
import { NestFactory } from '@nestjs/core';   
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';   
//Importación de las dependencias necesarias 

async function bootstrap() {
  const app = await NestFactory.create(AppModule,{cors:true});    //Creación de la aplicación
  const config = new DocumentBuilder() //Configuración de la documentación Swagger
    .setTitle('API Convert')    //Establecemos el titulo
    .setDescription('Convert HTML to PDF')  //La descripción
    .setVersion('1.0')  //La versión
    .addTag('Convert')  //La etiqueta de la API
    .build();   //Construcción de la configuración del documento Swagger

  const document = SwaggerModule.createDocument(app, config); //Creamos la documentación de Swagger
  SwaggerModule.setup('api', app, document);  //Configuración del Swagger utilizando el método estático

  await app.listen(3000); //Iniciamos la aplicación en el puerto 3000
}
bootstrap(); //Inicia la aplicación
```
