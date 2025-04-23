# Hathor Hackathon Blueprint Submitter

A simple web application for submitting blueprints to the Hathor Network.

## Prerequisites

- Docker
- Docker Compose (optional)

## Running the Application

### Using Docker

1. Build the Docker image:
```bash
docker build -t hathor-blueprint-submitter .
```

2. Run the container:
```bash
docker run -p 80:80 hathor-blueprint-submitter
```

### Using Docker Compose

1. Create a `docker-compose.yml` file with the following content:
```yaml
version: '3'
services:
  web:
    build: .
    ports:
      - "80:80"
```

2. Run the application:
```bash
docker-compose up
```

## Accessing the Application

Once running, you can access the application at:
- http://localhost

## API Endpoint

The application proxies requests to:
- http://localhost:8000/wallet/nano-contracts/create-on-chain-blueprint

Make sure the backend service is running on port 8000 before submitting blueprints. 