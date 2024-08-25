#!/bin/bash

# Updated backup directory
backup_dir="/root/backup/containers-backup"

# Ensure the backup directory exists
if [ ! -d "$backup_dir" ]; then
  echo "Creating backup directory $backup_dir..."
  mkdir -p "$backup_dir"
fi

# Function to prompt for container names to include or exclude
get_container_list() {
  echo "Fetching running containers..."
  docker ps --format "{{.Names}}" > all_containers.txt

  echo "Available containers:"
  cat all_containers.txt

  echo "Enter container names to include (comma-separated) or leave empty to include all:"
  read -r include_list
  echo "Enter container names to exclude (comma-separated) or leave empty to exclude none:"
  read -r exclude_list

  # Convert comma-separated lists to arrays
  IFS=',' read -r -a include_array <<< "$include_list"
  IFS=',' read -r -a exclude_array <<< "$exclude_list"

  # Build the final list of containers to back up
  containers=()
  while IFS= read -r container; do
    if [[ " ${exclude_array[*]} " =~ " ${container} " ]]; then
      continue
    fi
    if [[ -z "$include_list" || " ${include_array[*]} " =~ " ${container} " ]]; then
      containers+=("$container")
    fi
  done < all_containers.txt

  # Clean up
  rm all_containers.txt
}

# Get list of containers based on user input
get_container_list

# Backup each container
for container in "${containers[@]}"; do
  container_backup_dir="$backup_dir/$container"
  
  # Ensure the directory for the container exists
  if [ ! -d "$container_backup_dir" ]; then
    echo "Creating directory for $container: $container_backup_dir"
    mkdir -p "$container_backup_dir"
  fi
  
  echo "Backing up $container..."
  
  # Check if the container is running
  if docker ps --format "{{.Names}}" | grep -q "^$container$"; then
    if docker cp "$container:/." "$container_backup_dir" 2>/dev/null; then
      echo "Backup for $container completed successfully."
    else
      echo "Error: Failed to back up $container."
    fi
  else
    echo "Error: Container $container is not running or does not exist."
  fi
done

echo "Backup process complete."
echo "Backup stored in $backup_dir"
