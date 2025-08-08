{ pkgs }:

pkgs.writeShellApplication {
  name = "docker-cleanup";
  runtimeInputs = with pkgs; [
    docker-client
    coreutils
    gnugrep
  ];
  text = ''
    set -euo pipefail

    run_cleanup() {
      local description="''$1"
      local list_command="''$2"
      local cleanup_command="''$3"

      echo "📋 ''$description..."

      local items
      items=$(eval "''$list_command" 2>/dev/null || true)

      if [ -n "''$items" ]; then
        eval "''$cleanup_command" && echo "✅ ''$description completed"
      else
        echo "ℹ️  No items found for: ''$description"
      fi
      echo ""
    }

    if ! docker info >/dev/null 2>&1; then
      echo "❌ Docker is not running or not accessible"
      echo "💡 Please start Docker (Orbstack/Docker Desktop) and try again"
      exit 1
    fi

    echo "🧹 Starting Docker cleanup..."
    echo "⚠️  WARNING: This will remove ALL Docker containers, images, volumes, and networks!"
    echo ""
    printf "Are you sure you want to continue? [y/N]: "
    read -r confirmation || true
    case "''${confirmation,,}" in
      y|yes) echo "Proceeding with Docker cleanup..."; echo "" ;;
      *) echo "Docker cleanup cancelled"; exit 0 ;;
    esac

    # Stop all running containers
    run_cleanup "Stopping all running containers" \
      "docker ps -q" \
      'docker stop $(docker ps -q)'

    # Remove all containers (including stopped ones)
    run_cleanup "Removing all containers" \
      "docker ps -aq" \
      'docker rm $(docker ps -aq)'

    # Remove all images
    run_cleanup "Removing all images" \
      "docker images -q" \
      'docker rmi $(docker images -q)'

    # Remove all volumes (this will delete any persistent data)
    run_cleanup "Removing all volumes" \
      "docker volume ls -q" \
      'docker volume rm $(docker volume ls -q)'

    # Remove all custom networks (except default ones)
    run_cleanup "Removing all custom networks" \
      "docker network ls -q --filter type=custom" \
      'docker network rm $(docker network ls -q --filter type=custom)'

    echo "📋 Cleaning up build cache and unused resources..."
    docker system prune -a --volumes -f
    echo "✅ System cleanup completed"
    echo ""
    echo "🎉 Docker cleanup completed successfully!"
    echo "💡 Your Docker environment is now clean."
  '';
}