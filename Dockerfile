# Use a specific Node.js version as the base image
FROM node:21-alpine

# Install curl for health checks
RUN apk add --no-cache curl
RUN apk add --no-cache bash

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of your application source code into the container
COPY . .

# Copy the start script into the container
COPY docker-start.sh /app/start.sh

# Make the start script executable
RUN chmod +x /app/start.sh

# Expose the ports your applications listen on
EXPOSE 3010
EXPOSE 8545

# Command to run the start script
CMD ["/app/start.sh"] # <--- THIS IS THE NEW CMD