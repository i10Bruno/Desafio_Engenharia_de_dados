import os
import traceback
from pathlib import Path
from typing import List, Dict, Set
from urllib.parse import quote_plus

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

from schema_generator import pluralizar, obter_tabela_fk


BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / "config" / ".env"
DATA_DIR = BASE_DIR / "data"
SCHEMA_PATH = BASE_DIR / "schema.sql"

load_dotenv(ENV_PATH)

user = os.getenv("user")
password = os.getenv("password")
database = os.getenv("database")
host = os.getenv("host", "localhost")


def get_engine() -> Engine:
    """Cria e retorna a engine de conexão com o banco de dados PostgreSQL."""
    conn_str = (
        f"postgresql+psycopg2://"
        f"{user}:{quote_plus(password or '')}"
        f"@{host}:5432/{database}"
    )
    return create_engine(conn_str)


def descobrir_dependencias(csv_files: List[Path]) -> Dict[str, Set[str]]:
    """Descobre dependências entre tabelas mapeando as chaves estrangeiras nos cabeçalhos dos CSVs."""
    arquivos_validos = {arquivo.stem for arquivo in csv_files}
    dependencias = {}

    for csv_file in csv_files:
        tabela = pluralizar(csv_file.stem)
        with csv_file.open("r", encoding="utf-8-sig", newline="") as file:
            headers = file.readline().strip().split(",")

        deps = set()
        for coluna in headers:
            coluna = coluna.strip()
            tabela_referenciada = obter_tabela_fk(coluna, arquivos_validos)

            if tabela_referenciada and tabela_referenciada != tabela:
                deps.add(tabela_referenciada)

        dependencias[tabela] = deps

    return dependencias


def ordenar_tabelas(csv_files: List[Path], dependencias: Dict[str, Set[str]]) -> List[Path]:
    """Realiza a ordenação topológica dos arquivos CSV para garantir a integridade referencial na inserção."""
    arquivos_por_tabela = {pluralizar(csv_file.stem): csv_file for csv_file in csv_files}
    ordenadas = []
    visitando = set()
    visitadas = set()

    def visitar(tabela: str) -> None:
        if tabela in visitadas:
            return
        if tabela in visitando:
            raise ValueError(f"Ciclo de dependência encontrado envolvendo a tabela '{tabela}'.")

        visitando.add(tabela)
        for dependencia in dependencias.get(tabela, set()):
            if dependencia in arquivos_por_tabela:
                visitar(dependencia)

        visitando.remove(tabela)
        visitadas.add(tabela)
        ordenadas.append(tabela)

    for tabela in arquivos_por_tabela:
        visitar(tabela)

    return [arquivos_por_tabela[tabela] for tabela in ordenadas]


def run_schema(engine: Engine) -> None:
    """Lê e executa o script SQL para estruturar o schema do banco de dados."""
    print("-> Configurando o Banco de Dados...")
    with open(SCHEMA_PATH, "r", encoding="utf-8") as file:
        sql_script = file.read()
    print(f"-> Schema lido: {len(sql_script)} caracteres")

    with engine.begin() as conn:
        conn.execute(text(sql_script))
    print("-> Schema configurado com sucesso!\n")


def load_data(engine: Engine) -> bool:
    """Carrega os dados dos CSVs para o banco na ordem correta, retornando o status de sucesso."""
    csv_files = list(DATA_DIR.glob("*.csv"))
    if not csv_files:
        print(f"Nenhum CSV encontrado em: {DATA_DIR}")
        return False

    dependencias = descobrir_dependencias(csv_files)
    csv_files = ordenar_tabelas(csv_files, dependencias)

    print("\n-> ORDEM DE CARGA:")
    for arquivo in csv_files:
        print(f"   {arquivo.name}")
    print()

    for file_path in csv_files:
        print(f"Lendo o arquivo: {file_path.name}")
        df = pd.read_csv(file_path)
        table_name = pluralizar(file_path.stem)
        print(f"Inserindo {len(df)} registros na tabela '{table_name}'...")

        try:
            df.to_sql(name=table_name, con=engine, if_exists="append", index=False)
            print("-> Registros inseridos com sucesso!\n")
        except Exception as e:
            print(f"\n-> ERRO ao inserir na tabela '{table_name}'")
            print(f"-> {e}\n")
            traceback.print_exc()
            return False

    return True


if __name__ == "__main__":
    try:
        db_engine = get_engine()
        run_schema(db_engine)
        sucesso = load_data(db_engine)

        if sucesso:
            print("\n================================")
            print("PROCESSO FINALIZADO COM SUCESSO!")
            print("================================")
        else:
            print("\n================================")
            print("PROCESSO FINALIZADO COM ERROS!")
            print("================================")
    except Exception as e:
        print("\n================================")
        print("FALHA NA EXECUÇÃO!")
        print("================================")
        print(e)
        traceback.print_exc()