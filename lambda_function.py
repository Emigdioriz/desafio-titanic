import logging
import boto3
import pickle
import json
import uuid
import pandas as pd
import numpy as np
import boto3
from decimal import Decimal, getcontext, Inexact, Rounded

logger = logging.getLogger()
logger.setLevel(logging.INFO)

getcontext().traps[Inexact] = 0
getcontext().traps[Rounded] = 0

logger.info("Versão 1.4")

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Survivals_table')

logger.info("Carregando o modelo")

def load_model():
    try:
        with open('model.pkl', 'rb') as model_file:
            return pickle.load(model_file)
    except Exception as e:
        logger.error(f"Erro ao carregar o modelo: {e}")
        return None

model = load_model()

def handle_post_request(body):
    logger.info("Método POST")

    caracteristics = body.get('caracteristicas', None)
    if caracteristics is None or len(caracteristics) != 8:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Array de características não fornecido ou inválido'})
        }

    caracteristics_array = np.array(caracteristics).reshape(1, -1)
    probability = model.predict_proba(caracteristics_array)
    survival_prob = Decimal(str(probability[0][1]))
    user_id = str(uuid.uuid4())

    try:
        table.put_item(
            Item={
                'user_id': user_id,
                'survival_prob': survival_prob
            }
        )
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

def handle_get_request(query_params):

    logger.info("Método Get")
    user_id = query_params.get('user_id', None)
    if user_id:
        response = table.get_item(Key={'user_id': user_id})
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
        response = table.scan()
        items = response.get('Items', [])
        user_ids = [item['user_id'] for item in items]
        return {
            'statusCode': 200,
            'body': json.dumps({'user_ids': user_ids})
        }

def handle_delete_request(query_params):
    logger.info("Método Delete")

    user_id = query_params.get('user_id', None)
    if user_id:
        try:
            table.delete_item(
                Key={'user_id': user_id},
                ConditionExpression="attribute_exists(user_id)"
            )
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
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'user_id é obrigatório'})
        }

def lambda_handler(event, context):
    if model is None:
        logger.error("Modelo não carregado")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Erro ao carregar o modelo'})
        }

    try:
        http_method = event.get('httpMethod', '')
        if http_method == 'POST':
            body = json.loads(event.get('body', '{}'))
            return handle_post_request(body)
        elif http_method == 'GET':
            query_params = event.get('queryStringParameters', None)
            if query_params is None: query_params = {}
            return handle_get_request(query_params)
        elif http_method == 'DELETE':
            query_params = event.get('queryStringParameters', {})
            return handle_delete_request(query_params)
        else:
            return {
                'statusCode': 405,
                'body': json.dumps({'message': 'Método não permitido'})
            }
    except Exception as e:
        logger.error(f"Erro no lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'Erro interno do servidor {e}'})
        }