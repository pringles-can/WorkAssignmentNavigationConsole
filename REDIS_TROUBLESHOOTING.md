# Redis Connection Testing Guide

This guide provides multiple ways to test Redis connections in your WANC application.

## Quick Tests

### 1. Health Check Endpoint
Test the built-in health check endpoint:
```bash
# Local development
curl http://localhost:8080/health

# Azure deployment
curl https://your-app-service.azurewebsites.net/health
```

### 2. Redis Test API Endpoints
Use the new Redis test controller:
```bash
# Test basic connection
curl http://localhost:8080/api/redistest/health

# Get Redis server information
curl http://localhost:8080/api/redistest/info

# Test operations
curl -X POST http://localhost:8080/api/redistest/test \
  -H "Content-Type: application/json" \
  -d '{"value": "test-data"}'
```

## PowerShell Script Testing

### Local Redis
```powershell
.\test-redis-connection.ps1 -ConnectionString "localhost:6379" -Environment "local"
```

### Docker Redis
```powershell
.\test-redis-connection.ps1 -ConnectionString "localhost:6379" -Environment "docker"
```

### Azure Redis Cache
```powershell
.\test-redis-connection.ps1 -ConnectionString "your-redis-host:6380,password=your-password,ssl=True,abortConnect=False" -Environment "azure"
```

## C# Console Application Testing

### Compile and Run
```bash
# Compile the tester
dotnet build RedisConnectionTester.cs

# Test local Redis
dotnet run --project RedisConnectionTester.cs "localhost:6379"

# Test Azure Redis
dotnet run --project RedisConnectionTester.cs "your-redis-host:6380,password=your-password,ssl=True,abortConnect=False"
```

## Docker Environment Testing

### Start Redis with Docker Compose
```bash
# Start Redis only
docker-compose up redis

# Test connection
.\test-redis-connection.ps1 -ConnectionString "localhost:6379"
```

### Test from within Docker container
```bash
# Start the full application
docker-compose up

# Test from another container
docker run --rm -it redis:7-alpine redis-cli -h host.docker.internal -p 6379 ping
```

## Azure Redis Cache Testing

### Get Connection String
```powershell
# Get Redis connection details
$redisName = "wanc-redis-dev-20250820-112507"
$resourceGroup = "wanc-tracker-dev"

$redisKeys = az redis list-keys --name $redisName --resource-group $resourceGroup | ConvertFrom-Json
$redisHost = az redis show --name $redisName --resource-group $resourceGroup --query hostName --output tsv
$redisPort = az redis show --name $redisName --resource-group $resourceGroup --query port --output tsv
$redisConnectionString = "$redisHost`:$redisPort,password=$($redisKeys.primaryKey),ssl=True,abortConnect=False"

Write-Host "Redis Connection String: $redisConnectionString"
```

### Test Azure Redis
```powershell
# Test the connection
.\test-redis-connection.ps1 -ConnectionString $redisConnectionString -Environment "azure"
```

## Troubleshooting Common Issues

### 1. Connection Refused
**Symptoms**: `Connection refused` or `No connection could be made`
**Solutions**:
- Ensure Redis server is running
- Check if Redis is listening on the correct port
- Verify firewall settings

### 2. Authentication Failed
**Symptoms**: `NOAUTH Authentication required` or `WRONGPASS invalid username-password pair`
**Solutions**:
- Check password in connection string
- Verify username if using ACLs
- Ensure SSL settings are correct for Azure Redis

### 3. SSL/TLS Issues
**Symptoms**: `SSL handshake failed` or `The remote certificate is invalid`
**Solutions**:
- For Azure Redis: Ensure `ssl=True` in connection string
- For local Redis: Remove SSL settings if not configured
- Check certificate validity

### 4. Timeout Issues
**Symptoms**: `Timeout performing operation` or `Connection timeout`
**Solutions**:
- Increase timeout values in connection string
- Check network connectivity
- Verify Redis server performance

## Connection String Examples

### Local Redis
```
localhost:6379
```

### Local Redis with Password
```
localhost:6379,password=your-password
```

### Azure Redis Cache
```
your-redis-host:6380,password=your-password,ssl=True,abortConnect=False,connectTimeout=10000,syncTimeout=10000
```

### Docker Redis
```
redis:6379
```

## Monitoring Redis Health

### Application Health Checks
Your application includes built-in health checks that monitor Redis connectivity. These are available at:
- `/health` - Overall application health including Redis
- `/api/redistest/health` - Redis-specific health check

### Azure Monitor
For Azure Redis Cache, you can monitor:
- Connection count
- Memory usage
- Cache hit/miss ratio
- Network bandwidth

### Logs
Check application logs for Redis-related errors:
```bash
# Local development
dotnet run --environment Development

# Azure App Service
az webapp log tail --name your-app-service --resource-group your-resource-group
```

## Performance Testing

### Basic Performance Test
```bash
# Test with multiple operations
for i in {1..100}; do
  curl -X POST http://localhost:8080/api/redistest/test \
    -H "Content-Type: application/json" \
    -d "{\"value\": \"test-data-$i\"}"
done
```

### Redis CLI Performance Test
```bash
# Install redis-cli if not available
# Windows: Download from https://github.com/microsoftarchive/redis/releases
# Linux: sudo apt-get install redis-tools

# Test with redis-cli
redis-cli -h localhost -p 6379 --eval performance-test.lua
```

## Security Considerations

### Connection String Security
- Never commit connection strings with passwords to source control
- Use Azure Key Vault for production secrets
- Use environment variables for local development

### Network Security
- Use SSL/TLS for Azure Redis Cache
- Configure firewall rules appropriately
- Use private endpoints for production Azure Redis

### Access Control
- Use Redis ACLs for fine-grained access control
- Rotate passwords regularly
- Monitor access logs
