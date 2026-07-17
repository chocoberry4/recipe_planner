# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a monolithic Ruby on Rails 8.0 application called "recipe_planner" designed for comprehensive meal planning, recipe management, and community recipe sharing. The application combines a Rails API backend with a Vue.js frontend in a single codebase.

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

## Common Development Commands

**Note:** On Windows, use `bin\vite.cmd dev` if `bin/vite dev` doesn't work.

See [k8s/README.md](k8s/README.md) for Kubernetes deployment instructions including SSL/TLS setup, scaling, and troubleshooting.

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