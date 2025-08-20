# Hathor Tools

Simples tools to support Hathor development.

Currently, it has information specifically for the Hackathon testnet on the webpages.

## Prerequisites

- Docker
- Docker Compose (optional)
- Wallet headless running on localhost port 8000

## Running in Docker

1. Build the Docker image:
```bash
docker build -t hathor-tools .
```

2. Run the container:
```bash
docker run -p 8081:8081 -p 8082:8082 -p 8000:8000 hathor-tools
```

## Tools

### Blueprint submitter

Simple webpage to submit blueprint. Checks it has the `__blueprint__ = BlueprintName` in the file.

Runs on port 8081.

### Faucet

Sends 1000 HTR.

Runs on port 8082.