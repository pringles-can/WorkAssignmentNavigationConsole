using WorkAssignmentNavigationConsole.Models;
using WorkAssignmentNavigationConsole.Models.Enums;
using WorkAssignmentNavigationConsole.Services.Interfaces;

namespace WorkAssignmentNavigationConsole.Services;

public class FallbackOrderStore : IOrderStore
{
    private readonly RedisOrderStore _redisStore;
    private readonly InMemoryOrderStore _memoryStore;
    private readonly ILogger<FallbackOrderStore> _logger;
    private bool _redisAvailable = true;

    public FallbackOrderStore(RedisOrderStore redisStore, InMemoryOrderStore memoryStore, ILogger<FallbackOrderStore> logger)
    {
        _redisStore = redisStore;
        _memoryStore = memoryStore;
        _logger = logger;
    }

    public async Task<Order> CreateAsync()
    {
        if (_redisAvailable)
        {
            try
            {
                var order = await _redisStore.CreateAsync();
                _logger.LogInformation("Order created successfully in Redis");
                return order;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Redis failed, falling back to in-memory storage");
                _redisAvailable = false;
            }
        }

        var fallbackOrder = await _memoryStore.CreateAsync();
        _logger.LogInformation("Order created in fallback in-memory storage");
        return fallbackOrder;
    }

    public async Task<Order?> GetAsync(Guid id)
    {
        if (_redisAvailable)
        {
            try
            {
                var order = await _redisStore.GetAsync(id);
                if (order != null)
                {
                    _logger.LogInformation("Order retrieved successfully from Redis");
                    return order;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Redis failed, falling back to in-memory storage");
                _redisAvailable = false;
            }
        }

        var fallbackOrder = await _memoryStore.GetAsync(id);
        if (fallbackOrder != null)
        {
            _logger.LogInformation("Order retrieved from fallback in-memory storage");
        }
        return fallbackOrder;
    }

    public async Task<Order?> UpdateStageAsync(Guid id, OrderStage stage)
    {
        if (_redisAvailable)
        {
            try
            {
                var order = await _redisStore.UpdateStageAsync(id, stage);
                if (order != null)
                {
                    _logger.LogInformation("Order stage updated successfully in Redis");
                    return order;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Redis failed, falling back to in-memory storage");
                _redisAvailable = false;
            }
        }

        var fallbackOrder = await _memoryStore.UpdateStageAsync(id, stage);
        if (fallbackOrder != null)
        {
            _logger.LogInformation("Order stage updated in fallback in-memory storage");
        }
        return fallbackOrder;
    }
}
