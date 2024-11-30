#!/bin/bash

# Définir le chemin relatif vers le fichier .env
ENV_FILE=".env"

# Fonction pour afficher les erreurs et sortir
error_exit() {
    echo "❌ ERROR: $1" >&2
    exit 1
}

# Fonction pour afficher les succès
success_message() {
    echo "✅ SUCCESS: $1"
}

# Vérifier si kubectl est installé
command -v kubectl >/dev/null 2>&1 || error_exit "kubectl n'est pas installé"

# Vérifier si le fichier .env existe
if [ ! -f "$ENV_FILE" ]; then
    error_exit "Le fichier $ENV_FILE n'existe pas"
fi

# Charger les variables d'environnement
. "$ENV_FILE" || error_exit "Impossible de charger le fichier .env"

# Vérifier que les variables nécessaires sont définies
[ -z "$NAME_PG_SCRET_SOURCE" ] && error_exit "NAME_PG_SCRET_SOURCE n'est pas défini dans .env"
[ -z "$NAMESPACE_PG_SCRET_SOURCE" ] && error_exit "NAMESPACE_PG_SCRET_SOURCE n'est pas défini dans .env"

# Afficher les informations de configuration
echo "🔄 Configuration:"
echo "  - Secret source: $NAME_PG_SCRET_SOURCE"
echo "  - Namespace source: $NAMESPACE_PG_SCRET_SOURCE"
echo "  - Namespace destination: dagster"

# Vérifier si le secret existe dans le namespace postgres
if ! kubectl get secret "$NAME_PG_SCRET_SOURCE" -n "$NAMESPACE_PG_SCRET_SOURCE" >/dev/null 2>&1; then
    error_exit "Le secret $NAME_PG_SCRET_SOURCE n'existe pas dans le namespace $NAMESPACE_PG_SCRET_SOURCE"
fi

# Créer le namespace dagster s'il n'existe pas
kubectl create namespace dagster --dry-run=client -o yaml | kubectl apply -f - || error_exit "Impossible de créer/vérifier le namespace dagster"

# Récupérer les données du secret avec les bonnes clés
POSTGRES_USER=$(kubectl get secret "$NAME_PG_SCRET_SOURCE" -n "$NAMESPACE_PG_SCRET_SOURCE" -o jsonpath='{.data.POSTGRES_USER}' 2>/dev/null) || error_exit "Impossible de récupérer POSTGRES_USER"
POSTGRES_PASSWORD=$(kubectl get secret "$NAME_PG_SCRET_SOURCE" -n "$NAMESPACE_PG_SCRET_SOURCE" -o jsonpath='{.data.POSTGRES_PASSWORD}' 2>/dev/null) || error_exit "Impossible de récupérer POSTGRES_PASSWORD"
POSTGRES_DB=$(kubectl get secret "$NAME_PG_SCRET_SOURCE" -n "$NAMESPACE_PG_SCRET_SOURCE" -o jsonpath='{.data.POSTGRES_DB}' 2>/dev/null) || error_exit "Impossible de récupérer POSTGRES_DB"

# Vérifier que toutes les données sont présentes
[ -z "$POSTGRES_USER" ] && error_exit "POSTGRES_USER non trouvé dans le secret"
[ -z "$POSTGRES_PASSWORD" ] && error_exit "POSTGRES_PASSWORD non trouvé dans le secret"
[ -z "$POSTGRES_DB" ] && error_exit "POSTGRES_DB non trouvé dans le secret"

# Créer ou mettre à jour le secret dans le namespace dagster
cat << EOF | kubectl apply -f - || error_exit "Impossible de créer/mettre à jour le secret dans le namespace dagster"
apiVersion: v1
kind: Secret
metadata:
  name: $NAME_PG_SCRET_SOURCE
  namespace: dagster
type: Opaque
data:
  POSTGRES_USER: $POSTGRES_USER
  POSTGRES_PASSWORD: $POSTGRES_PASSWORD
  POSTGRES_DB: $POSTGRES_DB
EOF

# Vérifier que le secret a été créé
if kubectl get secret "$NAME_PG_SCRET_SOURCE" -n dagster >/dev/null 2>&1; then
    success_message "Secret créé/mis à jour avec succès dans le namespace dagster"
    echo "📝 Détails:"
    echo "  - Nom du secret: $NAME_PG_SCRET_SOURCE"
    echo "  - Namespace source: $NAMESPACE_PG_SCRET_SOURCE"
    echo "  - Namespace destination: dagster"
    
    # Vérification des valeurs (optionnel)
    echo -e "\n🔍 Vérification des valeurs:"
    echo -n "POSTGRES_DB: "
    kubectl get secret $NAME_PG_SCRET_SOURCE -n dagster -o jsonpath='{.data.POSTGRES_DB}' | base64 --decode
    echo
    echo -n "POSTGRES_USER: "
    kubectl get secret $NAME_PG_SCRET_SOURCE -n dagster -o jsonpath='{.data.POSTGRES_USER}' | base64 --decode
    echo
    echo "POSTGRES_PASSWORD: ***" # Pour la sécurité, on n'affiche pas le mot de passe
else
    error_exit "Le secret n'a pas été créé correctement dans le namespace dagster"
fi