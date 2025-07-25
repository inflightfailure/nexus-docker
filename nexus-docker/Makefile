.PHONY: start stop setup test test-all clean logs lint dev-setup credentials help

help:
	@echo "Available commands:"
	@echo "  credentials - Generate secure credentials (REQUIRED before first run)"
	@echo "  start       - Start all services with docker compose"
	@echo "  stop        - Stop all services"
	@echo "  restart     - Restart all services"
	@echo "  setup       - Run initial Nexus setup and EULA acceptance"
	@echo "  test        - Run comprehensive repository tests"
	@echo "  test-all    - Run all available tests"
	@echo "  lint        - Run pre-commit linting and security checks"
	@echo "  dev-setup   - Setup development environment (pipenv, pre-commit)"
	@echo "  clean       - Stop services and remove volumes"
	@echo "  logs        - Show logs for all services"
	@echo "  help        - Show this help message"

credentials:
	../scripts/generate-credentials.sh

start:
	@if [ ! -f .env ]; then echo "❌ Error: .env file not found. Run 'make credentials' first."; exit 1; fi
	docker compose up -d

stop:
	docker compose down

restart: stop start

setup:
	./scripts/setup/setup-nexus.sh

test:
	./scripts/testing/test-repos.sh

test-all:
	./scripts/testing/test-runner.sh

clean:
	docker compose down -v
	docker system prune -f

logs:
	docker compose logs -f

lint:
	../scripts/lint.sh

dev-setup:
	../scripts/dev-setup.sh
