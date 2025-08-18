# Tracker

A real-time order tracking application built with ASP.NET Core, SignalR, and Redis.

## Features

- Real-time order tracking with SignalR
- Redis-based order persistence
- Docker support for easy deployment
- RESTful API for order management
- Web interface for order tracking

## Prerequisites

- Docker and Docker Compose
- .NET 8.0 SDK (for local development)

## Quick Start with Docker

### Option 1: Using Helper Scripts (Recommended)

#### For Git Bash (Linux/macOS/Windows):
```bash
# Load the helper functions
source docker-helper.sh

# Start the application
pizza_start

# Open in browser
pizza_open

# Check status
pizza_status

# View logs
pizza_logs

# Create test order
pizza_test

# Stop the application
pizza_stop
```

#### For Windows Command Prompt:
```cmd
# Start the application
pizza-docker.bat start

# Open in browser
pizza-docker.bat open

# Check status
pizza-docker.bat status

# View logs
pizza-docker.bat logs

# Create test order
pizza-docker.bat test

# Stop the application
pizza-docker.bat stop
```

### Option 2: Manual Docker Commands

1. Clone the repository
2. Run the application using Docker Compose:

```bash
docker-compose up --build
```

3. Open your browser and navigate to `http://localhost:8080`

## Local Development

1. Install Redis locally or use Docker:
```bash
docker run -d -p 6379:6379 redis:7-alpine
```

2. Run the application:
```bash
dotnet run
```

3. Open your browser and navigate to `http://localhost:5000`

## API Endpoints

- `POST /api/orders` - Create a new order
- `GET /api/orders/{id}` - Get order details
- `PUT /api/orders/{id}/stage` - Update order stage
- `POST /api/orders/{id}/advance` - Advance order to next stage

## SignalR Hub

The application uses SignalR for real-time updates:

- Hub endpoint: `/orderhub`
- Events:
  - `OrderCreated` - Fired when a new order is created
  - `OrderStatusChanged` - Fired when an order stage changes

## Order Stages

1. **Initial** - Order has been created
2. **InProgress** - Order is being prepared
3. **Completed** - Order is ready for delivery
4. **Closed** - Order has been delivered
5. **Cancelled** - Order has been cancelled

## Configuration

The application can be configured using environment variables or appsettings.json:

- `Redis:ConnectionString` - Redis connection string
- `Azure:SignalR:ConnectionString` - Azure SignalR connection string (optional)

## Docker Compose Services

- **webapp** - ASP.NET Core application
- **redis** - Redis cache for order storage

## Development

### Project Structure

```
src/
├── Controllers/          # API controllers
├── Hubs/                # SignalR hubs
├── Models/              # Data models
│   ├── Enums/          # Enumerations
│   └── Records/        # Record types
└── Services/           # Business logic services
    └── Interfaces/     # Service interfaces
```

### Adding New Features

1. Create new models in `src/Models/`
2. Add business logic in `src/Services/`
3. Create API endpoints in `src/Controllers/`
4. Update SignalR hub if real-time updates are needed

## Production Deployment

### Azure Deployment

For production deployment to Azure, see the comprehensive guide in [`azure/README.md`](azure/README.md).

#### Quick Azure Setup:

1. **Automated Deployment (Recommended):**
   ```powershell
   cd azure
   .\azure-deploy.ps1 -ResourceGroupName "pizza-tracker-prod" -Environment "prod"
   ```

2. **Using ARM Template:**
   ```powershell
   cd azure
   .\deploy-arm.ps1 -ResourceGroupName "pizza-tracker-prod" -Environment "prod"
   ```

3. **Manual Setup:**
   - Follow the step-by-step instructions in [`azure/README.md`](azure/README.md)
   - Set up Azure Redis Cache
   - Configure Azure SignalR Service
   - Deploy to Azure App Service

#### Azure Resources Created:
- **App Service Plan** - Hosting for your web application
- **App Service** - Web application hosting
- **Azure Redis Cache** - Order data storage
- **Azure SignalR Service** - Real-time communication
- **Azure Container Registry** - Docker image storage
- **Key Vault** - Secure secret management

**Estimated Cost: ~$34/month for development, ~$100+/month for production**

### Other Deployment Options

1. **Docker Compose on VPS:**
   - Deploy to any VPS with Docker
   - Use external Redis service
   - Configure environment variables

2. **Kubernetes:**
   - Deploy to AKS or any Kubernetes cluster
   - Use Helm charts for deployment
   - Configure persistent storage

3. **AWS/GCP:**
   - Similar setup with respective cloud services
   - Use ElastiCache (AWS) or Memorystore (GCP) for Redis
   - Use App Engine (GCP) or Elastic Beanstalk (AWS)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request
