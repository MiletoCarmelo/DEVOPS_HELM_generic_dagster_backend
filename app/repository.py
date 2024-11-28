# repository.py
from dagster import Definitions, asset

@asset
def mon_premier_asset():
    return "Hello World"

@asset
def mon_deuxieme_asset(mon_premier_asset):
    return f"Received: {mon_premier_asset}"

# Cette ligne dit à Dagster quels assets/jobs il doit gérer
defs = Definitions(
    assets=[mon_premier_asset, mon_deuxieme_asset]
)