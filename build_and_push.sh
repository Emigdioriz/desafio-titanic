#!/bin/bash

# Defina variáveis
REPOSITORY_URI="021891592095.dkr.ecr.us-east-2.amazonaws.com/desafio"
IMAGE_TAG="teste_v6"
DOCKERFILE_PATH="."

# Crie a imagem Docker
sudo docker build -t minha-lambda-function:$IMAGE_TAG $DOCKERFILE_PATH

# Tag a imagem com o URI do repositório ECR
sudo docker tag minha-lambda-function:$IMAGE_TAG $REPOSITORY_URI:$IMAGE_TAG

# Faça login no ECR
aws ecr get-login-password --region us-east-2 | sudo docker login --username AWS --password-stdin 021891592095.dkr.ecr.us-east-2.amazonaws.com

# Faça o push da imagem para o ECR
sudo docker push $REPOSITORY_URI:$IMAGE_TAG

echo "Imagem Docker criada e enviada para o ECR com sucesso!"