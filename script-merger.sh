#!/bin/bash

# Vérifie si un argument (répertoire source) est fourni
if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

SOURCE_DIR="$1"

# Obtient le nom du dossier parent (enlève le chemin complet)
DIR_NAME=$(basename "$(realpath "$SOURCE_DIR")")
OUTPUT_FILE="${DIR_NAME}_combined.txt"

# Vérifie si le répertoire existe
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Le répertoire '$SOURCE_DIR' n'existe pas"
    exit 1
fi

# Supprime le fichier de sortie s'il existe déjà
[ -f "$OUTPUT_FILE" ] && rm "$OUTPUT_FILE"

# Trouve tous les fichiers yaml, yml et _tpl et les traite
find "$SOURCE_DIR" \( -name "*.yaml" -o -name "*.yml" -o -name "*_tpl" \) | while read -r file; do
    # Vérifie si le fichier est lisible
    if [ -r "$file" ]; then
        # Ajoute le séparateur avec le nom du fichier
        echo "==== $file ====" >> "$OUTPUT_FILE"
        # Ajoute une ligne vide pour la lisibilité
        echo "" >> "$OUTPUT_FILE"
        # Ajoute le contenu du fichier
        cat "$file" >> "$OUTPUT_FILE"
        # Ajoute deux lignes vides après chaque fichier
        echo "" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

echo "Les fichiers YAML et TPL ont été combinés dans $OUTPUT_FILE"