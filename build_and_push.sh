#!/bin/bash

# Carregar variáveis do arquivo .env
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo ".env file not found!"
  exit 1
fi

# Verificar se as variáveis necessárias estão definidas
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$IMAGE_TAG" ]; then
  echo "Uma ou mais variáveis necessárias não estão definidas no arquivo .env"
  exit 1
fi
DOCKERFILE_PATH="."
REPOSITORY_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME"

# Crie a imagem Docker
sudo docker build -t minha-lambda-function:$IMAGE_TAG $DOCKERFILE_PATH

# Tag a imagem com o URI do repositório ECR
sudo docker tag minha-lambda-function:$IMAGE_TAG $REPOSITORY_URI:$IMAGE_TAG

# Faça login no ECR
aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Crie o repositório no ECR, se não existir
aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $AWS_REGION 2>/dev/null || \
aws ecr create-repository --repository-name $REPOSITORY_NAME --region $AWS_REGION

# Faça o push da imagem para o ECR
sudo docker push $REPOSITORY_URI:$IMAGE_TAG

echo ""
echo "Imagem Docker criada e enviada para o ECR com sucesso!"
echo ""
echo "iniciando o deploy da infraestrutura..."
echo ""

# Definir variáveis diretamente no script
export TF_VAR_aws_account_id=$AWS_ACCOUNT_ID
export TF_VAR_repository_name=$REPOSITORY_NAME
export TF_VAR_image_tag=$IMAGE_TAG
export TF_VAR_aws_region=$AWS_REGION

echo "Iniciando terraform"
terraform init
terraform apply -auto-approve
echo ""
echo "Infraestrutura criada com sucesso!"