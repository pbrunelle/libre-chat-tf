#!/bin/bash
set -e

# Log all output to a file
exec > >(tee /var/log/startup-script.log) 2>&1
echo "Starting LibreChat setup script at $(date)"

git clone https://github.com/danny-avila/LibreChat.git
cd LibreChat

cat .env.example \
  | sed 's/DEBUG_CONSOLE=false/DEBUG_CONSOLE=true/' \
  | sed 's/# ENDPOINTS.*/ENDPOINTS=google,azureOpenAI,bedrock/' \
  | sed 's/# CONFIG_PATH=.*/CONFIG_PATH="librechat.yaml"/' \
  | sed 's/# BEDROCK_AWS_DEFAULT_REGION=.*/BEDROCK_AWS_DEFAULT_REGION=us-east-1/' \
  | sed "s/# BEDROCK_AWS_ACCESS_KEY_ID=.*/BEDROCK_AWS_ACCESS_KEY_ID=${aws_access_key_id}/" \
  | sed "s/# BEDROCK_AWS_SECRET_ACCESS_KEY=.*/BEDROCK_AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}/" \
  | sed "s/# BEDROCK_AWS_MODELS.*/BEDROCK_AWS_MODELS=amazon.nova-lite-v1:0,amazon.nova-pro-v1:0,us.anthropic.claude-3-5-sonnet-20240620-v1:0,us.anthropic.claude-3-5-sonnet-20241022-v2:0,us.anthropic.claude-3-7-sonnet-20250219-v1:0,us.meta.llama3-2-11b-instruct-v1:0/" \
  | sed "s/GOOGLE_KEY=user_provided/GOOGLE_KEY=${gemini_api_key}/" \
  > .env
echo "DEBUG=librechat:*" >> .env

cat > librechat.yaml << EOF
version: 1.2.1
cache: true
endpoints:
  azureOpenAI:
    titleModel: "current_model"
    groups:
    - group: "eastus"
      instanceName: "pierr-m7xbubjd-eastus2"
      apiKey: "${azure_openai_api_key}"
      version: "2025-01-01-preview"
      baseURL: "https://pierr-m7xbubjd-eastus2.cognitiveservices.azure.com/openai/deployments/gpt-4o-mini"
      models:
        gpt-4o-mini:
          deploymentName: "gpt-4o-mini"
EOF

cat > docker-compose.override.yaml << EOF
services:
  api:
    volumes:
    - type: bind
      source: ./librechat.yaml
      target: /app/librechat.yaml
EOF

# Add Docker's official GPG key:
sudo apt-get -y update
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update

# Install Docker
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Make sure Docker is ok
sudo docker run hello-world

echo "Starting LibreChat..."
sudo docker compose up -d

echo "LibreChat setup completed at $(date)"
