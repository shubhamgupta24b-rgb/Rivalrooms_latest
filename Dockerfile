FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src ./src
COPY migrations ./migrations
COPY scripts ./scripts
EXPOSE 3000
CMD ["node", "src/index.js"]
