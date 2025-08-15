using WorkAssignmentNavigationConsole.Models;
using WorkAssignmentNavigationConsole.Models.Enums;

namespace WorkAssignmentNavigationConsole.Services.Interfaces;

public interface IOrderStore
{
    Task<Order> CreateAsync();
    Task<Order?> GetAsync(Guid id);
    Task<Order?> UpdateStageAsync(Guid id, OrderStage stage);
}