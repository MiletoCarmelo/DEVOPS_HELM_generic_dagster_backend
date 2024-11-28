FROM python:3.11-slim
ENV DAGSTER_HOME=/opt/dagster/dagster_home

# Installation des packages
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
    dagster-webserver

# Création des répertoires nécessaires
RUN mkdir -p \
    $DAGSTER_HOME \
    $DAGSTER_HOME/history \
    $DAGSTER_HOME/schedules \
    $DAGSTER_HOME/compute_logs \
    /opt/dagster/app

# Copie des fichiers de configuration
COPY dagster.yaml workspace.yaml $DAGSTER_HOME/
# COPY app/repository.py /opt/dagster/app/

# Permissions
RUN chmod -R 777 $DAGSTER_HOME

WORKDIR $DAGSTER_HOME

# Commande de démarrage du webserver
CMD ["dagster-webserver", "-h", "0.0.0.0", "-p", "3000"]
EXPOSE 3000