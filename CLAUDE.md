# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Setup and Running
```bash
# Initial setup
sg setup
sg doctor  # Check system requirements

# Start development environment
sg start  # Starts default services
sg start enterprise  # Start with enterprise features
sg start batches  # Start with batch changes features

# Access local instance
# URL: https://sourcegraph.test:3443
```

### Testing
```bash
# Backend tests
sg test backend  # Run all backend unit tests
sg test backend ./internal/database  # Run specific package tests
sg test backend-integration  # Integration tests

# Frontend tests
pnpm test  # Run Vitest tests
sg test client  # Run all client tests
sg test web-e2e  # End-to-end tests
sg test bext-e2e  # Browser extension E2E tests

# Run specific test file
pnpm test path/to/test.spec.ts
```

### Linting and Formatting
```bash
# Run all linters
sg lint

# Specific linters
sg lint go
sg lint client
sg lint shell
sg lint svg
sg lint yaml

# Frontend specific
pnpm lint:js:all
pnpm lint:css:all
pnpm format  # Prettier formatting
```

### Building
```bash
# Backend services (using Bazel)
sg build  # Build all
bazel build //cmd/frontend  # Build specific service

# Frontend
pnpm build-web  # Production build
pnpm watch-web  # Development watch mode
pnpm storybook  # Component development
```

### Database Operations
```bash
sg db migrate  # Run migrations
sg db reset  # Reset database
sg db create-test  # Create test database
```

### Code Generation
```bash
sg generate  # Run all code generators
```

## Architecture Overview

Sourcegraph is a microservices-based code intelligence platform organized as follows:

### Service Architecture
The system consists of multiple Go services that communicate via gRPC and HTTP:

- **frontend** (cmd/frontend): API gateway and web server, handles authentication, GraphQL API, and serves the React web app
- **gitserver** (cmd/gitserver): Manages git repository clones, handles git operations, horizontally scalable
- **repo-updater** (cmd/repo-updater): Syncs repositories from code hosts (GitHub, GitLab, etc.)
- **searcher** (cmd/searcher): Performs non-indexed regex searches across repositories
- **symbols** (cmd/symbols): Extracts and serves code symbols for navigation
- **worker** (cmd/worker): Processes background jobs (repo syncing, batch changes, code intel)
- **zoekt-indexserver**: Creates trigram indexes for fast code search
- **zoekt-webserver**: Serves indexed search queries

### Frontend Architecture
The frontend (client/ directory) is a React/TypeScript application:

- **client/web**: Main web application using React, Apollo GraphQL client
- **client/branded**: Shared branded components used across products
- **client/wildcard**: Core UI component library
- **client/shared**: Shared utilities and types
- Uses Monaco editor for code viewing
- GraphQL for API communication with backend

### Data Flow
1. Code hosts → repo-updater → gitserver (repository data)
2. gitserver → zoekt-indexserver → zoekt-webserver (search indexes)
3. gitserver → symbols/syntactic-code-intel-worker → PostgreSQL (code intelligence)
4. Frontend → GraphQL API → backend services → data stores

### Key Design Patterns
- **GraphQL resolvers** in internal/graphqlbackend handle API requests
- **Database access** through internal/database package with sqlc for type-safe queries
- **Background jobs** managed by internal/workerutil framework
- **Feature flags** controlled through internal/conf
- **Observability** built into all services via internal/observation

### Development Configuration
- Main config: sg.config.yaml (defines services, commands, environments)
- Local overrides: sg.config.overwrite.yaml (gitignored)
- Site configuration: dev/site-config.json
- Uses Docker Compose for local development dependencies