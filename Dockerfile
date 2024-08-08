FROM public.ecr.aws/lambda/python:3.10

# Copie o arquivo de requisitos e instale as dependências
COPY requirements.txt ./

# Instale as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copie o arquivo da função Lambda
COPY lambda_function.py ./

# Copie o arquivo do modelo de ML
COPY model.pkl ./

# Defina o ponto de entrada para a função Lambda
CMD ["lambda_function.lambda_handler"]terr