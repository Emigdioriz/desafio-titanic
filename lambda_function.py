import logging
import boto3
import pickle
import json
import uuid
import pandas as pd
import numpy as np

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.info("Início de tudo")

logger.info("Carregando as bibliotecas")

# Inicializar o cliente S3
s3 = boto3.client('s3')

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
            survival_prob = probability[0][1]
            user_id = str(uuid.uuid4())
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'user_id': user_id,
                    'survival_probability': survival_prob
                })
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
            'body': json.dumps({'message': 'Internal server error'})
        }