# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a monolithic Ruby on Rails 8.0 application called "recipe_planner" designed for recipe planning functionality. The application combines a Rails API backend with a Vue.js frontend in a single codebase. The application uses:

- **Backend Framework**: Rails 8.0.3 (API-only mode)
- **Frontend Framework**: Vue.js
- **Database**: PostgreSQL with Solid adapters (Solid Cache, Solid Queue, Solid Cable)
- **Deployment**: Kamal with Docker containerization
- **Code Quality**: RuboCop with Rails Omakase styling, Brakeman for security analysis

## Architecture

The application follows a monolithic architecture combining Rails API backend with Vue.js frontend:

- **Backend**: Rails API-only configuration (`config.api_only = true`) serving JSON endpoints
- **Frontend**: Vue.js application integrated within the Rails project structure
- **Solid Suite Integration**: Uses Solid Cache, Solid Queue, and Solid Cable for Rails infrastructure
- **Job Processing**: Solid Queue configured to run inside Puma process (`SOLID_QUEUE_IN_PUMA: true`)
- **Deployment**: Configured for Docker deployment via Kamal to single web server with SSL

## Common Development Commands

### Setup and Dependencies
```bash
bundle install          # Install Ruby gems
npm install            # Install Node.js dependencies for Vue.js
bin/setup              # Initial application setup
```

### Database Operations
```bash
rake db:create         # Create databases
rake db:migrate        # Run pending migrations
rake db:reset          # Drop, recreate, and seed databases
rake db:seed           # Load seed data
```

### Testing
```bash
rake test              # Run all tests except system tests
rake test:db           # Reset database and run tests
```

### Code Quality
```bash
bin/rubocop            # Run RuboCop linter (Rails Omakase style)
bin/brakeman           # Run security analysis
```

### Development Server
```bash
bin/rails server       # Start Rails development server
npm run dev            # Start Vue.js development server with hot reload
bin/rails console      # Start Rails console
```

### Background Jobs
```bash
rake solid_queue:start # Start Solid Queue supervisor
bin/jobs              # Alternative job runner command
```

### Deployment (Kamal)
```bash
bin/kamal deploy       # Deploy application
bin/kamal console      # Remote Rails console
bin/kamal shell        # Remote shell access
bin/kamal logs         # View application logs
```

## Project Structure

### Backend (Rails)
- **Models**: Standard ActiveRecord models in `app/models/`
- **Controllers**: API controllers in `app/controllers/`
- **Jobs**: Background jobs in `app/jobs/`
- **Configuration**: Rails configuration in `config/`
- **Database**: Schema and seeds in `db/`

### Frontend (Vue.js)
- **Vue Components**: Vue.js components and application files
- **Assets**: Frontend assets and static files
- **Node Modules**: NPM dependencies in `node_modules/`

### Deployment
- **Kamal Configuration**: Deployment configuration in `config/deploy.yml`

## Key Configuration Files

### Backend Configuration
- **Kamal Deployment**: `config/deploy.yml` - Docker deployment configuration
- **Database**: `config/database.yml` - PostgreSQL configuration
- **Routes**: `config/routes.rb` - API endpoints
- **Solid Queue**: `config/queue.yml` - Job processing configuration
- **RuboCop**: `.rubocop.yml` - Code style rules (inherits from rails-omakase)

### Frontend Configuration
- **Package.json**: `package.json` - NPM dependencies and scripts for Vue.js
- **Vite Config**: `vite.config.ts` - Vite build configuration

## Development Notes

- This is a monolithic application combining Rails backend with Vue.js frontend
- Uses Rails 8.0 defaults including Solid adapters for infrastructure
- Rails configured in API-only mode to serve JSON endpoints for the Vue.js frontend
- Vue.js handles all user interface and client-side functionality
- Configured for containerized deployment with Kamal
- Follows Rails Omakase conventions for backend code styling