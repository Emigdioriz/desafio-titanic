import logging
import boto3
import pickle
import json
import uuid
import pandas as pd
import numpy as np
import boto3
from decimal import Decimal, getcontext, Inexact, Rounded

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
# Configure o contexto decimal
getcontext().traps[Inexact] = 0
getcontext().traps[Rounded] = 0

logger.info("Versão 1.4")

# Inicializar o cliente do DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Survivals_table')

logger.info("Carregando as bibliotecas")

# Carregar o modelo a partir do arquivo incluído na imagem Docker
logger.info("Carregando o modelo")
try:
    with open('model.pkl', 'rb') as model_file:
        model = pickle.load(model_file)
    logger.info("Modelo carregado com sucesso")
except Exception as e:
    logger.error(f"Erro ao carregar o modelo: {e}")
    model = None

def lambda_handler(event, context):
    logger.info("Início da execução da função lambda_handler")
    if model is None:
        logger.error("Modelo não carregado")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Erro ao carregar o modelo'})
        }
    
    try:
        http_method = event.get('httpMethod', '')
        logger.info(f"Método HTTP recebido: {http_method}")

        if http_method == 'POST':
            body = json.loads(event.get('body', '{}'))
            logger.info(f"Corpo da requisição: {body}")
            caracteristics = body.get('caracteristicas', None)
            
            if caracteristics is None or len(caracteristics) != 8:
                logger.warning("Array de características não fornecido ou inválido")
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Array de características não fornecido ou inválido'})
                }
            
            # Converter as características para um array NumPy
            logger.info("Convertendo características para array NumPy")
            caracteristics_array = np.array(caracteristics).reshape(1, -1)
            
            # Fazer a previsão usando o modelo carregado
            logger.info("Fazendo a previsão")
            probability = model.predict_proba(caracteristics_array)
            logger.info(f"Probabilidade calculada: {probability}")
            
            # Retornar a probabilidade da classe positiva (assumindo que a classe positiva é a segunda coluna)
            survival_prob = Decimal(str(probability[0][1]))
            user_id = str(uuid.uuid4())
            logger.info("Inserindo no banco de dados")
            # Inserir no DynamoDB
            try:
                table.put_item(
                    Item={
                        'user_id': user_id,
                        'survival_prob': survival_prob
                    }
                )
                logger.info("inserção realizada com sucesso")
            except Exception as e:
                logger.error(f"Erro ao inserir no DynamoDB: {e}")
                return {
                    'statusCode': 500,
                    'body': json.dumps({'message': 'Erro ao inserir no DynamoDB'})
                }
            
            survival_prob_percentage = f"{survival_prob * 100:.2f}%"

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'user_id': user_id,
                    'survival_probability': survival_prob_percentage
                })
            }
        elif http_method == 'GET':
            query_params = event.get('queryStringParameters', None)
            
            if query_params is None:
                query_params = {}

            user_id = query_params.get('user_id', None)

            if user_id:
                logger.info(f"método GET com user_id {user_id}")
                # Consultar o DynamoDB para o user_id específico
                response = table.get_item(
                    Key={
                        'user_id': user_id
                    }
                )
                logger.info("Busca no banco completa")
                item = response.get('Item', None)
                
                if item:
                    return {
                        'statusCode': 200,
                        'body': json.dumps({
                            'user_id': user_id,
                            'survival_probability': f"{float(item['survival_prob']) * 100:.2f}%"
                        })
                    }
                else:
                    return {
                        'statusCode': 404,
                        'body': json.dumps({'message': 'Usuário não encontrado'})
                    }
            else:
                logger.info("método GET SEM user_id")
                # Retornar todos os user_id do DynamoDB
                response = table.scan()
                items = response.get('Items', [])
                user_ids = [item['user_id'] for item in items]
                logger.info("Busca no banco completa")
                
                return {
                    'statusCode': 200,
                    'body': json.dumps({'user_ids': user_ids})
                }
        elif http_method == 'DELETE':
            query_params = event.get('queryStringParameters', None)
            
            if query_params is None:
                query_params = {}

            user_id = query_params.get('user_id', None)

            if user_id:
                logger.info(f"método DELETE com user_id {user_id}")
                # Deletar o item do DynamoDB para o user_id específico
                try:
                    response = table.delete_item(
                        Key={
                            'user_id': user_id
                        },
                        ConditionExpression="attribute_exists(user_id)"
                    )
                    logger.info("Deleção no banco completa")
                    return {
                        'statusCode': 200,
                        'body': json.dumps({'message': f'Usuário {user_id} deletado com sucesso'})
                    }
                except Exception as e:
                    logger.error(f"Erro ao deletar usuário: {str(e)}")
                    return {
                        'statusCode': 500,
                        'body': json.dumps({'message': 'Erro ao deletar usuário'})
                    }
            else:
                logger.info("método DELETE SEM user_id")
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'user_id é obrigatório'})
                }
        else:
            logger.warning("Método não permitido")
            return {
                'statusCode': 405,
                'body': json.dumps({'message': 'Método não permitido'})
            }
    except Exception as e:
        logger.error(f"Erro no lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({f'message': 'Erro interno do servidor {e}'})
        }