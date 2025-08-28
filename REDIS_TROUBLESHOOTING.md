# Redis Connection Troubleshooting Guide

## Issue: Redis Connection Timeout

If you're getting a `RedisConnectionException: The message timed out in the backlog attempting to send because no connection became available` error, follow these steps:

### 1. Check Health Check Endpoint

First, test the health check endpoint to see if Redis is accessible:

```bash
curl https://your-app-url.azurewebsites.net/health
```

This will show you the status of Redis and other services.

### 2. Verify Azure Redis Cache Configuration

Check that your Azure Redis Cache is properly configured:

1. Go to Azure Portal
2. Navigate to your Redis Cache resource
3. Check the "Access keys" section
4. Verify the connection string format

### 3. Check App Service Configuration

Verify that the Redis connection string is properly set in your App Service:

1. Go to Azure Portal
2. Navigate to your App Service
3. Go to "Configuration" > "Application settings"
4. Look for `Redis:ConnectionString`
5. Verify it contains the correct connection string

### 4. Test Redis Connection String

The connection string should look like:
```
your-redis-host:6380,password=your-password,ssl=True,abortConnect=False
```

### 5. Common Issues and Solutions

#### Issue: SSL/TLS Configuration
- **Problem**: Azure Redis Cache requires SSL
- **Solution**: Ensure `ssl=True` is in the connection string

#### Issue: Network Connectivity
- **Problem**: App Service can't reach Redis Cache
- **Solution**: 
  - Check if both resources are in the same region
  - Verify firewall rules
  - Check VNet configuration if using private endpoints

#### Issue: Authentication
- **Problem**: Invalid password or access key
- **Solution**: 
  - Regenerate the access key in Azure Portal
  - Update the connection string in App Service configuration

#### Issue: Connection Timeout
- **Problem**: Network latency or Redis overload
- **Solution**: 
  - Increase timeout values in connection string
  - Check Redis Cache performance metrics

### 6. Fallback Mechanism

The application now includes a fallback mechanism:
- If Redis is unavailable, it will automatically switch to in-memory storage
- Check the application logs for fallback messages
- Orders will still work, but won't persist across app restarts

### 7. Monitoring and Logging

Check the application logs for:
- Redis connection attempts
- Fallback to in-memory storage
- Connection string configuration

### 8. Testing

Use the provided test script:
```powershell
.\test-redis-connection.ps1 -AppUrl "https://your-app-url.azurewebsites.net"
```

### 9. Emergency Fix

If Redis is completely unavailable and you need immediate functionality:

1. Deploy the application with the fallback mechanism (already implemented)
2. The app will automatically use in-memory storage
3. Orders will work but won't persist across restarts

### 10. Contact Support

If the issue persists:
1. Check Azure Redis Cache health status
2. Review Azure Service Health for any regional issues
3. Contact Azure support if needed
