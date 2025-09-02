using Microsoft.AspNetCore.Mvc;
using StackExchange.Redis;
using System.Text.Json;

namespace WorkAssignmentNavigationConsole.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RedisTestController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IDistributedCache _cache;

    public RedisTestController(IConfiguration configuration, IDistributedCache cache)
    {
        _configuration = configuration;
        _cache = cache;
    }

    [HttpGet("health")]
    public async Task<IActionResult> TestConnection()
    {
        try
        {
            // Test basic cache operations
            var testKey = $"test:health:{Guid.NewGuid()}";
            var testValue = "health-check";
            
            await _cache.SetStringAsync(testKey, testValue, TimeSpan.FromMinutes(1));
            var retrievedValue = await _cache.GetStringAsync(testKey);
            await _cache.RemoveAsync(testKey);
            
            if (retrievedValue != testValue)
            {
                return BadRequest(new { status = "unhealthy", message = "Cache read/write test failed" });
            }
            
            return Ok(new { status = "healthy", message = "Redis connection is working properly" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { status = "unhealthy", message = ex.Message });
        }
    }

    [HttpGet("info")]
    public async Task<IActionResult> GetRedisInfo()
    {
        try
        {
            var connectionString = _configuration.GetConnectionString("Redis")
                ?? _configuration["RedisConnectionString"] 
                ?? "localhost:6379";
            
            using var mplexer = await ConnectionMultiplexer.ConnectAsync(connectionString);
            var server = mplexer.GetServer(mplexer.GetEndPoints().First());
            var info = await server.InfoAsync();
            
            var redisInfo = new Dictionary<string, string>();
            foreach (var entry in info)
            {
                redisInfo[entry.Key] = entry.Value;
            }
            
            return Ok(new { 
                connectionString = connectionString.Replace("password=", "password=***"),
                info = redisInfo 
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpPost("test")]
    public async Task<IActionResult> TestOperations([FromBody] TestRequest request)
    {
        try
        {
            var results = new Dictionary<string, object>();
            
            // Test SET operation
            var testKey = $"test:operation:{Guid.NewGuid()}";
            await _cache.SetStringAsync(testKey, request.Value, TimeSpan.FromMinutes(5));
            results["set"] = "success";
            
            // Test GET operation
            var retrievedValue = await _cache.GetStringAsync(testKey);
            results["get"] = retrievedValue == request.Value ? "success" : "failed";
            
            // Test DELETE operation
            await _cache.RemoveAsync(testKey);
            var deletedValue = await _cache.GetStringAsync(testKey);
            results["delete"] = deletedValue == null ? "success" : "failed";
            
            return Ok(new { 
                testKey = testKey,
                results = results 
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = ex.Message });
        }
    }
}

public class TestRequest
{
    public string Value { get; set; } = "test-value";
}
