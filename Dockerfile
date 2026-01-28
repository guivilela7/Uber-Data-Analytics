# Usar imagem base do Jupyter com suporte a data science
FROM jupyter/scipy-notebook:python-3.11

# Mudar para o usuário root para instalar pacotes do sistema
USER root

# Instalar o cliente do PostgreSQL para conectividade com o banco
RUN apt-get update && \
    apt-get install -y postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Voltar para o usuário padrão do Jupyter
USER ${NB_UID}

# Definir o diretório de trabalho
WORKDIR /home/jovyan/work

# Copiar o arquivo de dependências
COPY --chown=${NB_UID}:${NB_GID} requirements.txt .

# Instalar as dependências Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o restante do projeto
COPY --chown=${NB_UID}:${NB_GID} . .

# Expor a porta padrão do Jupyter
EXPOSE 8888

# Comando para iniciar o Jupyter Lab
CMD ["start-notebook.sh", "--NotebookApp.token=''", "--NotebookApp.password=''"]
