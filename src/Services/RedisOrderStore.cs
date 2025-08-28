using System.Text.Json;
using Microsoft.Extensions.Caching.Distributed;
using WorkAssignmentNavigationConsole.Models;
using WorkAssignmentNavigationConsole.Models.Enums;
using WorkAssignmentNavigationConsole.Services.Interfaces;

namespace WorkAssignmentNavigationConsole.Services;

public class RedisOrderStore : IOrderStore
{
    private readonly IDistributedCache _cache;
    private const string OrderKeyPrefix = "order:";

    public RedisOrderStore(IDistributedCache cache)
    {
        _cache = cache;
    }

    public async Task<Order> CreateAsync()
    {
        try
        {
            var order = new Order();
            var key = $"{OrderKeyPrefix}{order.Id}";
            var json = JsonSerializer.Serialize(order);
            
            await _cache.SetStringAsync(key, json, new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(24) // Orders expire after 24 hours
            });
            
            return order;
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Failed to create order in Redis: {ex.Message}", ex);
        }
    }

    public async Task<Order?> GetAsync(Guid id)
    {
        try
        {
            var key = $"{OrderKeyPrefix}{id}";
            var json = await _cache.GetStringAsync(key);
            
            if (string.IsNullOrEmpty(json))
                return null;
                
            return JsonSerializer.Deserialize<Order>(json);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Failed to get order {id} from Redis: {ex.Message}", ex);
        }
    }

    public async Task<Order?> UpdateStageAsync(Guid id, OrderStage stage)
    {
        try
        {
            var order = await GetAsync(id);
            if (order == null)
                return null;
                
            order.Stage = stage;
            order.UpdatedAtUtc = DateTimeOffset.UtcNow;
            
            var key = $"{OrderKeyPrefix}{id}";
            var json = JsonSerializer.Serialize(order);
            
            await _cache.SetStringAsync(key, json, new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(24)
            });
            
            return order;
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Failed to update order {id} stage in Redis: {ex.Message}", ex);
        }
    }
}
