using Microsoft.AspNetCore.SignalR;

namespace WorkAssignmentNavigationConsole.Hubs;

public class OrderHub : Hub
{
    public async Task JoinOrder(Guid orderId)
        => await Groups.AddToGroupAsync(Context.ConnectionId, $"order:{orderId}");

    public async Task LeaveOrder(Guid orderId)
        => await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"order:{orderId}");
}