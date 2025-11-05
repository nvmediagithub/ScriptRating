.PHONY: help install-backend run-backend test-backend lint-backend format-backend clean-backend docker-build-backend docker-run-backend install-frontend run-frontend test-frontend analyze-frontend format-frontend build-frontend clean-frontend help-backend help-frontend dev full-setup

help: ## Show this help message
	@echo 'Project Development Commands:'
	@echo ''
	@echo 'Full Project:'
	@echo '  dev              - Run both backend and frontend in development mode'
	@echo '  full-setup       - Complete setup for both backend and frontend'
	@echo ''
	@echo 'Backend Commands:'
	@make -f Makefile help-backend 2>/dev/null || echo '  (see help-backend)'
	@echo ''
	@echo 'Frontend Commands:'
	@make -f flutter/Makefile help-frontend 2>/dev/null || echo '  (see help-frontend)'

# Backend commands (delegated to root Makefile)
install-backend: ## Install backend dependencies
	pip install -e .[dev]

run-backend: ## Run backend development server
	uvicorn app.presentation.api.main:app --reload --host 0.0.0.0 --port 8000

test-backend: ## Run backend tests
	pytest tests/ -v

lint-backend: ## Run backend linting
	flake8 app/ tests/
	mypy app/

format-backend: ## Format backend code
	black app/ tests/
	isort app/ tests/

clean-backend: ## Clean backend cache files
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete

docker-build-backend: ## Build backend Docker image
	docker build -t script-rating-backend .

docker-run-backend: ## Run backend with Docker Compose
	docker-compose up --build

# Frontend commands (delegated to flutter/Makefile)
install-frontend: ## Install frontend dependencies
	cd flutter && flutter pub get

run-frontend: ## Run frontend development server
	cd flutter && flutter run

test-frontend: ## Run frontend tests
	cd flutter && flutter test

analyze-frontend: ## Analyze frontend code
	cd flutter && flutter analyze

format-frontend: ## Format frontend code
	cd flutter && dart format .

build-frontend: ## Build frontend for current platform
	cd flutter && flutter build

clean-frontend: ## Clean frontend project
	cd flutter && flutter clean

# Combined commands
dev: ## Run both backend and frontend in development mode
	@echo "Starting backend and frontend in development mode..."
	@echo "Backend will be available at http://localhost:8000"
	@echo "Frontend will launch in a new window"
	@echo ""
	@echo "Press Ctrl+C to stop both services"
	@trap 'pkill -f uvicorn; exit 0' INT; \
	(make run-backend & make run-frontend & wait)

full-setup: ## Complete setup for both backend and frontend
	@echo "Setting up complete development environment..."
	make install-backend
	make install-frontend
	@echo ""
	@echo "Setup complete! Run 'make dev' to start development servers."
	@echo ""
	@echo "Environment files:"
	@echo "  - Copy .env.example to .env for backend configuration"
	@echo "  - Copy flutter/.env.example to flutter/.env for frontend configuration"