FROM python:3.11-slim
ENV DAGSTER_HOME=/opt/dagster/dagster_home

# Installation des dépendances système pour PostgreSQL
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Installation des packages Dagster et autres
RUN pip install \
    dagster \
    dagster-azure \
    dagster-postgres \
    dagster-k8s \
    dagster-aws \
    dagster-celery[flower,redis,kubernetes] \
    dagster-celery-k8s \
    dagster-gcp \
    dagster-graphql \
    dagster-webserver \
    psycopg2-binary

# Création des répertoires nécessaires
RUN mkdir -p \
    $DAGSTER_HOME \
    $DAGSTER_HOME/history \
    $DAGSTER_HOME/schedules \
    $DAGSTER_HOME/compute_logs \
    /opt/dagster/app

# Copier le fichier dagster.yaml si disponible (fallback local, sera remplacé par ConfigMap)
COPY dagster.yaml $DAGSTER_HOME/dagster.yaml

# Permissions
RUN chmod -R 777 $DAGSTER_HOME

WORKDIR $DAGSTER_HOME

# Commande de démarrage du webserver
CMD ["dagster-webserver", "-h", "0.0.0.0", "-p", "3000"]
EXPOSE 3000
