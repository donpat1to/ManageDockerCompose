#!/bin/bash

# Make sure the script is executed with root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

timestamp() {
    date '+%d/%m/%Y: %H:%M:%S'
}

echo "[$(timestamp)] Starting Docker Compose update process..."

compose_files=()

if [[ "$1" == "all" || $# -eq 0 ]]; then
    # Discover all docker-compose.yaml files under /srv
    while IFS= read -r -d '' file; do
        compose_files+=("$file")
    done < <(find /srv -maxdepth 3 -type f -name "docker-compose.yaml" -print0)
    shift
else
    # Use only the provided service directories
    for dir in "$@"; do
        if [[ -f "$dir/docker-compose.yaml" ]]; then
            compose_files+=("$dir/docker-compose.yaml")
        else
            echo "[$(timestamp)] WARNING: No docker-compose.yaml in $dir"
        fi
    done
fi

if [[ ${#compose_files[@]} -eq 0 ]]; then
    echo "[$(timestamp)] No docker-compose.yaml files found. Exiting."
    exit 0
fi

echo "[$(timestamp)] Found ${#compose_files[@]} services. Pulling updates..."

# Pull latest images
for file in "${compose_files[@]}"; do
    service=$(basename "$(dirname "$file")")
    echo "[$(timestamp)] Pulling $service..."
    docker compose -f "$file" pull || echo "[$(timestamp)] WARNING: Failed to pull $service"
done

echo "[$(timestamp)] Restarting services..."

# Restart containers
for file in "${compose_files[@]}"; do
    service=$(basename "$(dirname "$file")")
    echo "[$(timestamp)] Restarting $service..."
    docker compose -f "$file" up -d || echo "[$(timestamp)] WARNING: Failed to restart $service"
done

# Prune unused images
echo "[$(timestamp)] Cleaning up unused Docker images..."
docker image prune -f

# OCC reminder
echo "[$(timestamp)] Update process complete."
echo "[$(timestamp)] Reminder: Run OCC maintenance commands manually if required:"
echo "    sudo -u www-data php occ db:add-missing-columns"
echo "    sudo -u www-data php occ db:add-missing-indices"
echo "    sudo -u www-data php occ db:add-missing-primary-keys"
