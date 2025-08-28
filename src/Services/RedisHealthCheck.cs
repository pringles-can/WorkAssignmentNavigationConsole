using Microsoft.Extensions.Diagnostics.HealthChecks;
using StackExchange.Redis;

namespace WorkAssignmentNavigationConsole.Services;

public class RedisHealthCheck : IHealthCheck
{
    private readonly IConfiguration _config;
    
    public RedisHealthCheck(IConfiguration config) => _config = config;

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        var conn = _config.GetConnectionString("Redis") 
            ?? _config["Redis:ConnectionString"] 
            ?? _config["RedisConnectionString"]  // Alternative name without colon
            ?? _config["Redis:Connection"];
        if (string.IsNullOrWhiteSpace(conn))
            return HealthCheckResult.Healthy("No Redis configured; skipping");
        try
        {
            using var mplexer = await ConnectionMultiplexer.ConnectAsync(conn);
            var db = mplexer.GetDatabase();
            await db.PingAsync();
            return HealthCheckResult.Healthy();
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Cannot reach Redis", ex);
        }
    }
}