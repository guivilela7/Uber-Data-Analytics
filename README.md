# Uber Data Analytics

![Python](https://img.shields.io/badge/Python-3.10+-blue)
![Pandas](https://img.shields.io/badge/Pandas-Data%20Analysis-green)
![Docker](https://img.shields.io/badge/Docker-Container-blue)
![Status](https://img.shields.io/badge/Status-Em%20Desenvolvimento-yellow)

Projeto de **engenharia e análise de dados** focado em dados de corridas do Uber, implementando um pipeline ETL completo — da ingestão dos dados brutos até a camada analítica pronta para visualização.

Inspirado em boas práticas de projetos analíticos e estruturado de forma modular para facilitar manutenção, escalabilidade e reutilização.

---

## Visão Geral

Este projeto analisa **corridas do Uber realizadas em uma Nova Delhi ao longo de 2024**, com foco em entender padrões operacionais, comportamento de demanda, preços, distâncias, avaliações e métodos de pagamento.

O objetivo é organizar e analisar dados de viagens do Uber, permitindo responder perguntas como:

* Quais são os horários de maior demanda?
* Quais locais concentram mais embarques e desembarques?
* Como se comportam os preços, distâncias e avaliações?
* Existe relação entre método de pagamento e valor da corrida?

---

## Arquitetura do Projeto

O pipeline segue o conceito de **Data Lake em camadas**:

```
Raw (Bronze) → Silver → Gold
```

Cada camada possui um papel específico dentro do fluxo de dados.

---

## Estrutura de Pastas

```
.
├── Data Layer/
│   ├── raw/              # Dados brutos, sem tratamento
│   ├── silver/           # Dados limpos e padronizados
│   └── gold/             # Dados analíticos prontos para BI
├── Data Visualization/   # Arquivo .pbix do PowerBI
├── Transformer/          # Scripts e notebooks de ETL
├── .env                  # Arquivo de variáveis de ambiente
├── docker-compose.yml    # Ambiente containerizado
├── Dockerfile            # Arquivo de configurações do Docker
├── requirements.txt      # Dependências do projeto
└── README.md             # Documentação
```

---

## Pipeline ETL

### Ingestão (Raw)

* Leitura dos dados originais
* Manutenção do formato original

### Transformação (Silver)

* Tratamento de valores nulos
* Padronização de datas e horários
* Conversão de tipos
* Remoção de inconsistências

### Modelagem (Gold)

* Criação de tabelas analíticas
* Métricas agregadas
* Dados prontos para dashboards

---

## Análises Desenvolvidas

Alguns exemplos de análises implementadas ou possíveis com este projeto:

* Pickup Location x Booking Status
* Pickup Location x Price
* Pickup Location x Avg CTAT
* Booking Value x Booking Status
* Ride Distance x Booking Status
* Customer Rating x Driver Rating
* Payment Method x Price
* Análise de Outliers

---

## Visualização de Dados

Os dados da camada **Gold** podem ser facilmente integrados a ferramentas de BI como:

* Power BI
* Tableau
* Looker Studio

> Ideal para criação de dashboards operacionais e analíticos.

---

## Executando o Projeto

### Usando Docker

```bash
docker compose up -d --build
```

#### Acessar os Serviços

Após os containers iniciarem, os seguintes serviços estarão disponíveis:

| Serviço | URL de Acesso | Descrição |
| :--- | :--- | :--- |
| **Jupyter Lab** | [http://localhost:8888](http://localhost:8888) | Ambiente para executar os notebooks de ETL e análise. |
| **pgAdmin** | [http://localhost:5050](http://localhost:5050) | Ferramenta para gerenciar e executar queries no banco de dados. |

#### Configurar o pgAdmin

Ao acessar o pgAdmin pela primeira vez, siga estes passos:

1.  **Faça login** com as credenciais do arquivo `.env` (padrão: `admin@admin.com` / `admin`). ||| Caso não haja tela de login, será pedido apenas a criação de uma senha global, que recomendamos ser `admin` para praticidade.
2.  Clique em **Add New Server**.
3.  Preencha as informações de conexão:
    - **Aba General**:
        - **Name**: `Uber Analytics Docker` (pode ser o nome que preferir)
    - **Aba Connection**:
        - **Host**: `postgres` 
        - **Port**: `5432`
        - **Maintenance database**: `uber_analytics`
        - **Username**: `postgres`
        - **Password**: `postgres`
4.  Clique em **Save**.

### Executar os Notebooks

No Jupyter Lab, navegue até a pasta `Transformer` e execute os notebooks na seguinte ordem:

1.  **`etl_raw_to_silver.ipynb`**: Carrega os dados brutos, limpa-os e armazena na camada Silver.
2.  **`etl_silver_to_gold.ipynb`**: Transforma os dados da camada Silver e os carrega no modelo dimensional (camada Gold).

Após a execução dos arquivos ETL, os dados estão disponíveis para buscas pelo pgAdmin.

---

## Notebooks

Os notebooks estão organizados para:

* Exploração inicial dos dados
* Validação das transformações
* Análises estatísticas
* Visualizações exploratórias

---

## Qualidade e Boas Práticas

* Separação clara de camadas
* Código reutilizável
* Estrutura escalável
* Fácil adaptação para novos datasets

---

## Tecnologias Utilizadas

* Python
* Pandas
* Jupyter Notebook
* Docker
* Power BI

---

## Integrantes

| ![Guilherme Aguera de la Fuente Vilela](https://github.com/guivilela7.png) | ![⁠Lucas Oliveira Meireles](https://github.com/katuner.png) | ![Víctor Moreira Almeida](https://github.com/vitu-moreira.png) | ![⁠Felipe Nunes de Mello](https://github.com/FelipeNunesdM.png) |
| ----- | ----- | ----- | ----- |
| [Guilherme Aguera de la Fuente Vilela](https://github.com/guivilela7)  | [⁠Lucas Oliveira Meireles](https://github.com/katuner)  | [Víctor Moreira Almeida](https://github.com/vitu-moreira)  | [⁠Felipe Nunes de Mello](https://github.com/FelipeNunesdM)  | 
