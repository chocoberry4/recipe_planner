# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a monolithic Ruby on Rails 8.0 application called "recipe_planner" designed for comprehensive meal planning, recipe management, and community recipe sharing. The application combines a Rails API backend with a Vue.js frontend in a single codebase. The application uses:

- **Backend Framework**: Rails 8.0.3 (API-only mode)
- **Frontend Framework**: Vue.js
- **Database**: PostgreSQL with Solid adapters (Solid Cache, Solid Queue, Solid Cable)
- **Deployment**: Kubernetes with Docker containerization
- **Code Quality**: RuboCop with Rails Omakase styling, Brakeman for security analysis

## Project Vision

Recipe Planner is a comprehensive meal planning and recipe management system that helps individuals and families organize their meals, discover new recipes, and share culinary experiences with a global community.

### Primary Goals

1. **Personal Meal Planning**: Enable users to plan weekly/monthly meals with an intuitive calendar interface
2. **Recipe Management**: Store, organize, and search personal recipe collections with rich metadata
3. **Family Coordination**: Support household meal planning with dietary preferences and restrictions
4. **Community Sharing**: Create a global platform for users to share, discover, and rate recipes
5. **Smart Shopping**: Automatically generate shopping lists from planned meals

### Target Users

- **Phase 1**: Single user personal meal planning and recipe management
- **Phase 2**: Multi-user household/family coordination
- **Phase 3**: Community-based platform for worldwide recipe sharing and discovery

## Architecture

The application follows a monolithic architecture combining Rails API backend with Vue.js frontend:

- **Backend**: Rails API-only configuration (`config.api_only = true`) serving JSON endpoints
- **Frontend**: Vue.js application integrated within the Rails project structure
- **Solid Suite Integration**: Uses Solid Cache, Solid Queue, and Solid Cable for Rails infrastructure
- **Job Processing**: Solid Queue configured to run inside Puma process (`SOLID_QUEUE_IN_PUMA: true`)
- **Deployment**: Containerized Docker deployment orchestrated by Kubernetes
  - Kubernetes for container orchestration, scaling, and management
  - Docker for application containerization
  - PostgreSQL database deployment in Kubernetes
  - Ingress for SSL/TLS termination and load balancing
  - ConfigMaps and Secrets for configuration management

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

### Development Server (Local - Without Docker)

Run both servers in separate terminals:

```bash
# Terminal 1: Start Rails API server
bin/rails server       # Starts on http://localhost:3000

# Terminal 2: Start Vite dev server for Vue.js (hot reload)
bin/vite dev           # Starts Vite with hot module replacement

# Rails console
bin/rails console      # Interactive Rails console
```

**Note:** On Windows, use `bin\vite.cmd dev` if `bin/vite dev` doesn't work.

### Development Server (Docker - Recommended)

Docker Compose provides a complete development environment with PostgreSQL:

```bash
# Start all services (PostgreSQL + Rails app)
docker-compose up

# Start in detached mode (background)
docker-compose up -d

# View logs when running in background
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

The docker-compose setup includes:
- **PostgreSQL 18**: Database on port 5432 (user: postgres, password: postgres)
- **Rails web app**: API server on http://localhost:3000
- **Persistent volumes**: Database data and bundle cache preserved between restarts
- **Health checks**: PostgreSQL health check ensures database is ready before Rails starts

First time setup with Docker:
```bash
# Build and start containers
docker-compose up --build

# In another terminal, create and migrate the database
docker-compose exec web rails db:create db:migrate db:seed
```

### Background Jobs
```bash
rake solid_queue:start # Start Solid Queue supervisor
bin/jobs              # Alternative job runner command
```

### Docker Operations (Standalone)
```bash
docker build -t recipe_planner:latest .    # Build Docker image
docker run -p 3000:3000 recipe_planner     # Run container locally (requires external DB)
```

### Kubernetes Deployment

See [k8s/README.md](k8s/README.md) for comprehensive deployment instructions including SSL/TLS setup, scaling, and troubleshooting.

Quick reference:
```bash
kubectl apply -f k8s/                      # Deploy all Kubernetes manifests
kubectl get pods                           # List running pods
kubectl get services                       # List services
kubectl logs -l app=recipe-planner -f      # View app logs (follow mode)
kubectl exec -it deployment/recipe-planner -- bash           # Shell into pod
kubectl exec -it deployment/recipe-planner -- rails console  # Remote Rails console
kubectl port-forward service/recipe-planner 3000:80          # Forward port for local access
kubectl describe pod <pod-name>            # Get detailed pod information
kubectl rollout restart deployment/recipe-planner            # Rolling restart
kubectl delete -f k8s/                     # Remove all resources
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
- **Kubernetes Manifests**: Deployment configurations in `k8s/` directory (see [k8s/README.md](k8s/README.md))
- **Docker Configuration**: `Dockerfile` for containerization
- **Docker Compose**: `docker-compose.yml` - Complete local dev environment with PostgreSQL and Rails

## Key Configuration Files

### Backend Configuration
- **Database**: `config/database.yml` - PostgreSQL configuration
- **Routes**: `config/routes.rb` - API endpoints
- **Solid Queue**: `config/queue.yml` - Job processing configuration
- **RuboCop**: `.rubocop.yml` - Code style rules (inherits from rails-omakase)

### Deployment Configuration
- **Dockerfile**: Application containerization configuration
- **docker-compose.yml**: Local development multi-service setup
- **k8s/deployment.yml**: Kubernetes deployment specification
- **k8s/service.yml**: Kubernetes service definition
- **k8s/ingress.yml**: Ingress rules for external access
- **k8s/configmap.yml**: Application configuration
- **k8s/secrets.yml**: Sensitive data (database credentials, etc.)
- **k8s/postgresql.yml**: PostgreSQL database deployment

### Frontend Configuration
- **Package.json**: `package.json` - NPM dependencies for Vue.js
- **Vite Config**: `vite.config.ts` - Vite build configuration
- **Vite Runner**: `bin/vite` - Vite CLI wrapper (use `bin/vite dev` to start dev server)

## Core Features

### Phase 1: Personal Recipe & Meal Planning (Current Focus)

#### Recipe Management
- **CRUD Operations**: Create, read, update, and delete recipes
- **Rich Recipe Data**:
  - Title, description, instructions (step-by-step)
  - Ingredients with quantities and units
  - Prep time, cook time, total time
  - Servings/yield information
  - Photos/images
  - Tags and categories (breakfast, lunch, dinner, dessert, etc.)
- **Recipe Search & Filtering**:
  - Search by recipe name, ingredients, or tags
  - Filter by dietary preferences (vegetarian, vegan, gluten-free, dairy-free, etc.)
  - Filter by liked/disliked ingredients
  - Filter by meal type, cuisine, preparation time
- **Portion Scaling**: Automatically adjust ingredient quantities based on desired servings
- **Nutritional Information**: Calculate and display nutritional data per serving

#### Meal Planning
- **Calendar Interface**:
  - Weekly and monthly views
  - Drag-and-drop recipe scheduling
  - Multiple meals per day (breakfast, lunch, dinner, snacks)
- **Meal Dashboard**: Overview of upcoming meals and planning statistics
- **Meal Prep Notes**: Add preparation notes and timing for each scheduled meal

#### Shopping Lists
- **Auto-Generation**: Create shopping lists from planned meals
- **Ingredient Aggregation**: Combine ingredients across multiple recipes
- **List Management**:
  - Check off purchased items
  - Add custom items
  - Organize by store sections/categories
  - Share lists with household members

#### User Preferences
- **Dietary Restrictions**: Set dietary requirements (vegetarian, vegan, allergies, etc.)
- **Ingredient Preferences**:
  - Mark favorite ingredients
  - Mark disliked/avoided ingredients
  - Filter recipes automatically based on preferences
- **Allergen Tracking**: Track and warn about allergens in recipes

### Phase 2: Household/Family Features (Future)

- **Multi-User Support**: Multiple users within a household
- **Shared Meal Planning**: Collaborative meal calendar
- **Individual Preferences**: Track dietary preferences per household member
- **Meal Voting**: Family members vote on meal options
- **Cooking Assignments**: Assign who cooks which meals

### Phase 3: Community & Social Features (Future)

#### Public Recipe Sharing
- **Publish Recipes**: Share personal recipes with the community
- **Recipe Discovery**: Browse and search community recipes
- **Recipe Collections**: Curated recipe collections and meal plans

#### Social Interaction
- **User Profiles**: Public profiles showing shared recipes and activity
- **Recipe Ratings & Reviews**: Community feedback on recipes
- **Comments**: Discussion on recipes
- **Favorites/Bookmarks**: Save community recipes to personal collection
- **Follow System**: Follow favorite recipe creators
- **Recipe Forking**: Copy and modify community recipes for personal use

#### Community Features
- **Trending Recipes**: Popular and trending recipes
- **Seasonal Collections**: Curated seasonal recipe collections
- **Global Cuisine Explorer**: Browse recipes by country/region
- **Cooking Challenges**: Community cooking challenges and events

## Data Models (Planned)

### Core Models
- **User**: User accounts and authentication
- **Recipe**: Recipe data (title, description, instructions, etc.)
- **Ingredient**: Ingredient master list
- **RecipeIngredient**: Join model linking recipes to ingredients with quantities
- **MealPlan**: Scheduled meals on calendar
- **ShoppingList**: Generated shopping lists
- **ShoppingListItem**: Individual items on shopping lists
- **Tag**: Recipe categorization tags
- **Category**: Recipe categories (meal type, cuisine, etc.)

### User Preference Models
- **UserDietaryRestriction**: User dietary requirements
- **UserIngredientPreference**: Liked/disliked ingredients
- **UserAllergen**: Allergen tracking

### Community Models (Phase 3)
- **PublicRecipe**: Community-shared recipes
- **RecipeRating**: User ratings on recipes
- **RecipeReview**: User reviews/comments
- **UserFollow**: User following relationships
- **RecipeCollection**: Curated recipe collections
- **RecipeFavorite**: User-favorited recipes

## Development Notes

- This is a monolithic application combining Rails backend with Vue.js frontend
- Uses Rails 8.0 defaults including Solid adapters for infrastructure
- Rails configured in API-only mode to serve JSON endpoints for the Vue.js frontend
- Vue.js handles all user interface and client-side functionality
- Containerized with Docker and orchestrated with Kubernetes for scalability
- Follows Rails Omakase conventions for backend code styling

### Kubernetes Architecture
- **Application Pods**: Rails application running in multiple replicas for high availability
- **Database**: PostgreSQL StatefulSet with persistent volumes
- **Services**: ClusterIP services for internal communication
- **Ingress**: NGINX Ingress Controller for external access with SSL/TLS
- **ConfigMaps**: Environment-specific configuration (non-sensitive)
- **Secrets**: Sensitive data like database passwords, API keys
- **Persistent Volumes**: For PostgreSQL data persistence and uploaded recipe images
- **Horizontal Pod Autoscaling**: Auto-scale based on CPU/memory usage

## Development Priorities

### Current Sprint (Phase 1 - MVP)
1. Complete recipe CRUD functionality
2. Build meal planning dashboard with calendar
3. Implement recipe search and filtering
4. Add user preferences for dietary restrictions and ingredient likes/dislikes
5. Create shopping list generation from meal plans
6. Add portion scaling for recipes
7. Implement basic nutritional information

### Next Steps
1. Polish UI/UX for Phase 1 features
2. Add comprehensive testing coverage
3. Deploy to production environment
4. User testing and feedback collection

### Future Enhancements
1. Mobile-responsive design optimization
2. Recipe import from URLs (web scraping)
3. Meal planning AI suggestions based on preferences
4. Integration with grocery delivery services
5. Recipe scaling with unit conversions
6. Multi-user household features (Phase 2)
7. Community and social features (Phase 3)