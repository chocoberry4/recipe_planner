# Recipe Planner

An easy to use meal planner, pantry tracker, recipe library all in one. I would love to expand this to be community based to share ideas, recipes and just chat amongst one another.

## ✨ Features

- 📖 **Recipe Management** - Store and organize your favorite recipes
- 🛒 **Smart Shopping Lists** - Auto-generate shopping lists from meal plans  
- 📅 **Weekly Meal Planning** - Plan your week ahead with a visual calendar
- 🥫 **Pantry Tracking** - Keep track of what's in your kitchen
- ⭐ **Recipe Discovery** - Find new recipes to try


## 🚀 Tech Stack

    Backend:
    - Ruby 3.4 / Rails 8.0.3
    - PostgreSQL with Solid adapters (Cache, Queue, Cable)
    - Puma web server

    Frontend:
    - Vue.js 3.5
    - Pinia (state management)
    - Vite (build tool)

    Deployment:
    - Docker 
    - Kubernetes


## Prerequisites

    - Ruby 3.4+
    - Node.js 18+ / npm
    - PostgreSQL (or Docker)

## Installation / Setup

    git clone https://github.com/chocoberry4/recipe_planner.git

    cd recipe_planner

    bundle install

    npm install

## Setup database (using Docker)
    docker-compose up -d
    
    rails db:create db:migrate db:seed

## Start development servers
    bin/rails s  

## Features (Current + Planned)

Current:
 - User authentication
 - Recipe management
 - Shopping list generation
 
Planned:
 - Weekly meal planning
 - Pantry tracking
 - Recipe discovery