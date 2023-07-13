# Usar una imagen base de Node.js
FROM node:latest

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar los archivos del proyecto a la imagen
COPY . /app

# Instalar las dependencias del proyecto
RUN npm install

# Compilar el proyecto
RUN npm run build

# Configurar el servidor web para servir los archivos estáticos
FROM nginx:latest
COPY --from=0 /app/build /usr/share/nginx/html

# Exponer el puerto 3201
EXPOSE 3002

# Comando para iniciar el servidor web de Nginx
CMD ["nginx", "-g", "daemon off;"]