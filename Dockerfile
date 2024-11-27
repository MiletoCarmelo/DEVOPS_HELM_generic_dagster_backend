FROM python:3.11-slim
ARG DAGSTER_VERSION=1.6.0

# Définition de DAGSTER_HOME
ENV DAGSTER_HOME=/opt/dagster/dagster_home

# Création du répertoire DAGSTER_HOME
RUN mkdir -p $DAGSTER_HOME

# Installation des packages
RUN pip install \
    dagster==${DAGSTER_VERSION} \
    dagster-azure \
    dagster-postgres \
    dagster-k8s \
    dagster-aws \
    dagster-celery[flower,redis,kubernetes] \
    dagster-celery-k8s \
    dagster-gcp \
    dagster-graphql \
    dagster-webserver

# Commande par défaut
CMD ["dagster-daemon", "run"]

# Exposer le port
EXPOSE 3000