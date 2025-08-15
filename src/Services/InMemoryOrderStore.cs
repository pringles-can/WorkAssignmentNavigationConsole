using System.Collections.Concurrent;
using WorkAssignmentNavigationConsole.Models;
using WorkAssignmentNavigationConsole.Models.Enums;
using WorkAssignmentNavigationConsole.Services.Interfaces;

namespace WorkAssignmentNavigationConsole.Services;

public class InMemoryOrderStore : IOrderStore
{
    private readonly ConcurrentDictionary<Guid, Order> _orders = new();

    public Task<Order> CreateAsync()
    {
        var order = new Order();
        _orders[order.Id] = order;
        return Task.FromResult(order);
    }

    public Task<Order?> GetAsync(Guid id)
        => Task.FromResult(_orders.TryGetValue(id, out var o) ? o : null);

    public Task<Order?> UpdateStageAsync(Guid id, OrderStage stage)
    {
        if (!_orders.TryGetValue(id, out var o)) return Task.FromResult<Order?>(null);
        o.Stage = stage;
        o.UpdatedAtUtc = DateTimeOffset.UtcNow;
        return Task.FromResult<Order?>(o);
    }
}