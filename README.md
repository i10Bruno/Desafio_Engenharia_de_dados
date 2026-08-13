# Desafio Engenharia de Dados

Este projeto cria o schema de um banco PostgreSQL a partir dos CSVs e carrega os dados automaticamente.

## Pré-requisitos

- Python 3.13+
- [Poetry](https://python-poetry.org/)
- Docker + Docker Compose

## 1) Instalar o Poetry

No Linux/macOS:

```bash
curl -sSL https://install.python-poetry.org | python3 -
```

Verifique se instalou:

```bash
poetry --version
```

## 2) Configurar variáveis de ambiente

Edite o arquivo `/home/runner/work/Desafio_Engenharia_de_dados/Desafio_Engenharia_de_dados/config/.env`.

Exemplo:

```env
# usado pela aplicação Python
database=lh_nautical_database
user=lighthouse
host=localhost

# usado pelo docker-compose
DB_NAME=lh_nautical_database
DB_USER=lighthouse
DB_PASSWORD=sua_senha
DB_PORT=5432
```

> Também inclua no `.env` a variável `password` (usada pelo `src/load_data.py`).

## 3) Subir o PostgreSQL com Docker

Na raiz do projeto:

```bash
docker compose up -d
```

Para verificar:

```bash
docker ps
```

## 4) Instalar dependências do projeto

Na raiz do projeto:

```bash
poetry install
```

## 5) Executar o projeto

Gerar/atualizar o schema SQL:

```bash
poetry run python src/schema_generator.py
```

Criar tabelas no PostgreSQL e carregar os CSVs:

```bash
poetry run python src/load_data.py
```

## Estrutura de pastas

- `config/`: arquivo `.env` com variáveis de ambiente.
- `data/`: arquivos CSV de entrada.
- `docs/reports/`: imagens e saídas de relatórios.
- `notebooks/`: análises exploratórias e modelos.
- `sql/`: consultas SQL das questões do desafio.
- `src/`: scripts Python principais (`schema_generator.py` e `load_data.py`).
- `schema.sql`: schema gerado para criação das tabelas.
- `docker-compose.yml`: serviço PostgreSQL usado no projeto.
- `pyproject.toml`: configuração do projeto e dependências (Poetry).