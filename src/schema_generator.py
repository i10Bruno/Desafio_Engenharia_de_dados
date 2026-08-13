from pathlib import Path
import csv
from typing import Optional, Set, Dict

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
OUTPUT_FILE = BASE_DIR / "schema.sql"

FORCE_TEXT: Set[str] = {
    "cpf",
    "tax_id",
    "phone",
    "nfe_access_key",
    "ncm_code",
    "series",
    "reference_id",
}

FK_EXCEPTIONS: Dict[str, str] = {
    "parent_category_id": "category",
    "primary_location_id": "location",
    "destination_location_id": "location",
    "received_at_location_id": "location",
    "salesperson_id": "employee",
    "buyer_id": "employee",
    "received_by_employee_id": "employee",
    "exchange_variant_id": "product_variant",
}


def pluralizar(palavra: str) -> str:
    """Transforma o nome de um arquivo no nome da tabela correspondente no plural."""
    if palavra.endswith("y"):
        return palavra[:-1] + "ies"

    if palavra.endswith("ss"):
        return palavra + "es"

    return palavra + "s"


def obter_tabela_fk(coluna: str, arquivos_validos: Set[str]) -> Optional[str]:
    """Verifica e retorna o nome da tabela referenciada caso a coluna seja uma chave estrangeira."""
    if not coluna.endswith("_id"):
        return None

    if coluna in FORCE_TEXT:
        return None

    nome_arquivo_alvo = coluna[:-3]

    if coluna in FK_EXCEPTIONS:
        nome_arquivo_alvo = FK_EXCEPTIONS[coluna]

    if nome_arquivo_alvo not in arquivos_validos:
        raise ValueError(
            f"\n[ERRO DE RELACIONAMENTO] "
            f"A coluna '{coluna}' procura pelo arquivo "
            f"'{nome_arquivo_alvo}.csv', mas ele não existe em data.\n"
        )

    return pluralizar(nome_arquivo_alvo)


def inferir_tipo(valor: str) -> str:
    """Infere e retorna o tipo de dado SQL adequado (INTEGER, NUMERIC ou TEXT) avaliando o conteúdo da string."""
    valor = valor.strip()

    if not valor:
        return "TEXT"

    try:
        int(valor)
        return "INTEGER"
    except ValueError:
        pass

    try:
        float(valor)
        return "NUMERIC"
    except ValueError:
        pass
        
    return "TEXT"


def definir_tipo_por_nome(column: str, arquivos_validos: Set[str]) -> Optional[str]:
    """Define o tipo de dado SQL de uma coluna com base em seu nome e nas regras de domínio."""
    if column == "id":
        return "INTEGER PRIMARY KEY"

    if column in FORCE_TEXT:
        return "TEXT"

    if column.endswith("_at"):
        return "TIMESTAMP"

    if column.endswith("_date"):
        return "DATE"

    if column.startswith("is_"):
        return "BOOLEAN"

    if obter_tabela_fk(column, arquivos_validos) is not None:
        return "INTEGER"

    return None


def gerar_tabela(csv_file: Path, arquivos_validos: Set[str]) -> str:
    """Lê as definições do CSV, infere os tipos não declarados e gera o comando CREATE TABLE."""
    with csv_file.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)

        if not reader.fieldnames:
            raise ValueError(f"CSV sem cabeçalho: {csv_file.name}")

        columns = reader.fieldnames
        tipos = {}
        fks_definitions = []
        fk_columns = []

        for column in columns:
            tipo = definir_tipo_por_nome(column, arquivos_validos)
            tipos[column] = tipo if tipo else "INTEGER"
            tabela_ref = obter_tabela_fk(column, arquivos_validos)

            if tabela_ref:
                fk_columns.append(column)
                fks_definitions.append(
                    f'    FOREIGN KEY ("{column}") REFERENCES "{tabela_ref}"("id")'
                )

        for row in reader:
            for column in columns:
                tipo_definido = definir_tipo_por_nome(column, arquivos_validos)
                
                if tipo_definido is not None:
                    continue

                tipo_inferido = inferir_tipo(row.get(column, ""))

                if tipo_inferido == "TEXT":
                    tipos[column] = "TEXT"
                elif tipos[column] == "INTEGER" and tipo_inferido == "NUMERIC":
                    tipos[column] = "NUMERIC"

        table_name = pluralizar(csv_file.stem)
        table_lines = [f'    "{column}" {tipos[column]}' for column in columns]

        if "id" not in columns and fk_columns:
            pk_cols = ", ".join(f'"{col}"' for col in fk_columns)
            table_lines.append(f"    PRIMARY KEY ({pk_cols})")

        table_lines.extend(fks_definitions)

        return (
            f'CREATE TABLE "{table_name}" (\n'
            + ",\n".join(table_lines)
            + "\n);\n"
        )


def gerar_schema() -> None:
    """Analisa os CSVs, mapeia suas dependências e orquestra a geração do arquivo de schema SQL ordenado."""
    csv_files = list(DATA_DIR.glob("*.csv"))

    if not csv_files:
        raise FileNotFoundError(f"Nenhum CSV encontrado em {DATA_DIR}")

    arquivos_validos = {file.stem for file in csv_files}
    schemas = {}
    dependencias = {}

    for csv_file in csv_files:
        table_name = pluralizar(csv_file.stem)

        with csv_file.open("r", encoding="utf-8-sig", newline="") as file:
            headers = next(csv.reader(file), [])

        deps = set()
        for column in headers:
            tabela_ref = obter_tabela_fk(column, arquivos_validos)
            if tabela_ref:
                deps.add(tabela_ref)

        dependencias[table_name] = deps
        print(f"Processando: {csv_file.name}")
        schemas[table_name] = gerar_tabela(csv_file, arquivos_validos)

    tabelas_ordenadas = []
    visitadas = set()

    def visitar(tabela: str) -> None:
        if tabela in visitadas:
            return
        visitadas.add(tabela)
        for dependencia in dependencias.get(tabela, set()):
            if dependencia in dependencias:
                visitar(dependencia)
        tabelas_ordenadas.append(tabela)

    for tabela in dependencias:
        visitar(tabela)

    sql_final = "".join(schemas[tabela] + "\n" for tabela in tabelas_ordenadas)
    OUTPUT_FILE.write_text(sql_final, encoding="utf-8")
    
    print(f"\nSchema gerado com sucesso em:\n{OUTPUT_FILE}")


if __name__ == "__main__":
    gerar_schema()