using Microsoft.AspNetCore.SignalR;
using WorkAssignmentNavigationConsole.Hubs;
using WorkAssignmentNavigationConsole.Services;
using WorkAssignmentNavigationConsole.Services.Interfaces;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure SignalR
builder.Services.AddSignalR();

// Configure Redis
builder.Services.AddStackExchangeRedisCache(options =>
{
    var redisConnectionString = builder.Configuration.GetConnectionString("Redis")
        ?? builder.Configuration["RedisConnectionString"]  // Alternative name without colon
        ?? "localhost:6379";
    
    // Debug logging to help diagnose configuration issues
    Console.WriteLine($"DEBUG: GetConnectionString('Redis') = {builder.Configuration.GetConnectionString("Redis")}");
    Console.WriteLine($"DEBUG: Configuration['RedisConnectionString'] = {builder.Configuration["RedisConnectionString"]}");
    Console.WriteLine($"DEBUG: Final Redis connection string = {redisConnectionString}");
    
    // For Azure Redis Cache, ensure proper connection settings
    if (redisConnectionString.Contains("ssl=True") || redisConnectionString.Contains("ssl=true"))
    {
        // Add additional parameters for Azure Redis Cache reliability
        if (!redisConnectionString.Contains("abortConnect=False"))
        {
            redisConnectionString += ",abortConnect=False";
        }
        if (!redisConnectionString.Contains("connectTimeout="))
        {
            redisConnectionString += ",connectTimeout=10000";
        }
        if (!redisConnectionString.Contains("syncTimeout="))
        {
            redisConnectionString += ",syncTimeout=10000";
        }
    }
    
    // Log Redis connection string (without password for security)
    var loggableConnectionString = redisConnectionString;
    if (loggableConnectionString.Contains("password="))
    {
        var parts = loggableConnectionString.Split(',');
        var filteredParts = parts.Where(p => !p.Trim().StartsWith("password="));
        loggableConnectionString = string.Join(",", filteredParts);
    }
    Console.WriteLine($"Redis Connection String: {loggableConnectionString}");
    
    options.Configuration = redisConnectionString;
});

// Configure Azure SignalR (optional - for production)
var signalRConnectionString = builder.Configuration["Azure:SignalR:ConnectionString"];
if (!string.IsNullOrEmpty(signalRConnectionString))
{
    builder.Services.AddSignalR()
        .AddAzureSignalR(signalRConnectionString);
}

// Register services
builder.Services.AddScoped<RedisOrderStore>();
builder.Services.AddScoped<InMemoryOrderStore>();
builder.Services.AddScoped<IOrderStore, FallbackOrderStore>();
builder.Services.AddScoped<OrderService>();

// Add health checks
builder.Services.AddHealthChecks()
    .AddCheck<RedisHealthCheck>("redis");

// Add CORS - moved outside the development check
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Enable CORS for all environments (needed for SignalR)
app.UseCors();

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

// Map API controllers BEFORE the fallback
app.MapControllers();
app.MapHub<OrderHub>("/orderhub");

// Add health check endpoint
app.MapHealthChecks("/health");

// Map fallback to file LAST - this catches everything that wasn't handled above
app.MapFallbackToFile("index.html");

app.Run();