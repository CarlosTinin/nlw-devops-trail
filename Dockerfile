# Multi stage dockerfile
# Criação da imagem base para instalar pnpm
FROM node:20 AS base

RUN npm i -g pnpm

# Criação da imagem dependencies baseada na imagem anterior para instalação das dependencias do projeto
FROM base AS dependencies

WORKDIR /usr/src/app

COPY package.json ./

RUN pnpm install

# Criação da imagem build para buildar os arquivos da aplicação
FROM base as build

WORKDIR /usr/src/app

COPY . .
COPY --from=dependencies /usr/src/app/node_modules ./node_modules

RUN pnpm build
RUN pnpm prune --prod

# Criação da imagem que será enviada para deploy com os arquivos de dependencias e os builds da aplicação
# Detalhe que será usada como base a imagem do node alpine por ser muito mais leve contendo apenas os recursos essênciais para execução da aplicação. Nos passos anteriores foi utilizada a imagem do node:20 por conter os recursos necessários para instalação das dependencias e build da aplicação.
FROM node:20-alpine3.19 AS deploy

WORKDIR /usr/src/app

RUN npm i -g pnpm prisma

COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prisma ./prisma

RUN pnpm prisma generate

EXPOSE 3333

CMD ["pnpm", "start"]