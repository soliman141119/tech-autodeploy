# setp 1:
FROM node:18-alpine

# step 2:
WORKDIR /app

# step 3:
COPY . .

# step 4:
RUN npm install --production

EXPOSE 3000

CMD ["npm", "start"]
