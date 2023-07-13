---
sidebar_position: 2
---

# Module
## Modulo Aplicacion Principal


 En este parte del código se encarga de la configuración y organización de los componentes de la aplicación, como los **Controladores, Servicios y Proveedores** en `src/app.module.ts`

```jsx title="src/app.module.ts"
import { Module } from '@nestjs/common';
import { ConvertController } from './convert/convert.controller';
//importación de las dependencias para el módulo de la aplicación de Nest.js y también un controlador

@Module({   //Creamos un decorador para configurar el modulo
  imports: [],  //importación del modulo
  controllers: [ConvertController],   //Controlador que es utilizado en el modulo
  providers: [],    //Proveedores de servicios que se utiliza en el modulo
})
export class AppModule {}   //Iniciamos la aplicación
```
