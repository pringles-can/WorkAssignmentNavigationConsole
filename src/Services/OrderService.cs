using Microsoft.AspNetCore.SignalR;
using WorkAssignmentNavigationConsole.Hubs;
using WorkAssignmentNavigationConsole.Models;
using WorkAssignmentNavigationConsole.Models.Enums;
using WorkAssignmentNavigationConsole.Models.Records;
using WorkAssignmentNavigationConsole.Services.Interfaces;

namespace WorkAssignmentNavigationConsole.Services;

public class OrderService
{
    private readonly IOrderStore _orderStore;
    private readonly IHubContext<OrderHub> _hubContext;

    public OrderService(IOrderStore orderStore, IHubContext<OrderHub> hubContext)
    {
        _orderStore = orderStore;
        _hubContext = hubContext;
    }

    public async Task<Order> CreateOrderAsync()
    {
        var order = await _orderStore.CreateAsync();
        
        // Notify clients about the new order
        await _hubContext.Clients.Group($"order:{order.Id}")
            .SendAsync("OrderCreated", order);
            
        return order;
    }

    public async Task<Order?> GetOrderAsync(Guid id)
    {
        return await _orderStore.GetAsync(id);
    }

    public async Task<Order?> UpdateOrderStageAsync(Guid id, OrderStage stage)
    {
        var order = await _orderStore.UpdateStageAsync(id, stage);
        
        if (order != null)
        {
            // Notify clients about the stage change
            var statusChange = new OrderStatusChanged(order.Id, order.Stage, order.UpdatedAtUtc);
            await _hubContext.Clients.Group($"order:{order.Id}")
                .SendAsync("OrderStatusChanged", statusChange);
        }
        
        return order;
    }

    public async Task<Order?> AdvanceOrderStageAsync(Guid id)
    {
        var order = await _orderStore.GetAsync(id);
        if (order == null)
            return null;

        var nextStage = order.Stage switch
        {
            OrderStage.Initial => OrderStage.InProgress,
            OrderStage.InProgress => OrderStage.Completed,
            OrderStage.Completed => OrderStage.Closed,
            _ => order.Stage
        };

        return await UpdateOrderStageAsync(id, nextStage);
    }
}
