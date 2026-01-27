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
├── Transformer/          # Scripts e notebooks de ETL
├── notebooks/            # Análises exploratórias
├── docker-compose.yml    # Ambiente containerizado
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
docker compose up -d
```

### Ambiente Python Local

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## Notebooks

Os notebooks estão organizados para:

* Exploração inicial dos dados
* Validação das transformações
* Análises estatísticas
* Visualizações exploratórias

Execute-os preferencialmente após o processamento da camada **Silver**.

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

## Contato

* GitHub: [https://github.com/guivilela7](https://github.com/guivilela7)
