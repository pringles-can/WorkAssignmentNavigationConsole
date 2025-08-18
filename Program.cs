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
    options.Configuration = builder.Configuration.GetConnectionString("Redis") 
        ?? builder.Configuration["Redis:ConnectionString"] 
        ?? "localhost:6379";
});

// Configure Azure SignalR (optional - for production)
var signalRConnectionString = builder.Configuration["Azure:SignalR:ConnectionString"];
if (!string.IsNullOrEmpty(signalRConnectionString))
{
    builder.Services.AddSignalR()
        .AddAzureSignalR(signalRConnectionString);
}

// Register services
builder.Services.AddScoped<IOrderStore, RedisOrderStore>();
builder.Services.AddScoped<OrderService>();

// Add CORS for development
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
    app.UseCors();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

app.MapControllers();
app.MapHub<OrderHub>("/orderhub");
app.MapFallbackToFile("index.html");

app.Run();