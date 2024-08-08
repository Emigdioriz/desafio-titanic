# Survival Prediction API

Este projeto implementa uma API para prever a probabilidade de sobrevivência com base em características fornecidas. A API é construída usando AWS Lambda, Docker e Terraform.

## Requisitos

- Docker instalado
- AWS CLI configurada
- Terraform instalado

## Configuração ```

1. Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

    ```properties
    AWS_ACCOUNT_ID= seu_AWS_id
    AWS_REGION= Sua_região_AWS
    REPOSITORY_NAME= sobreviventes_titanic
    IMAGE_TAG= v1 
    ```

2. Configure as permissões de execução para o script `build_and_push.sh`:

    ```sh
    chmod +x build_and_push.sh
    ```

3. Execute o script `build_and_push.sh` para construir a imagem Docker e configurar a infraestrutura com Terraform:

    ```sh
    ./build_and_push.sh
    ```

## Uso

### POST Request

Para fazer uma requisição POST, envie um corpo JSON com as características e o header `Content-Type: application/json`.

Exemplo de corpo da requisição:

```json
{
  "caracteristicas": [70, 1, 1, 30.25, 0, 0, 1, 0]
}