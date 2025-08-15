using Server.Models;
using Server.Models.Enums;

namespace Server.Services.Interfaces;

public interface IOrderStore
{
    Task<Order> CreateAsync();
    Task<Order?> GetAsync(Guid id);
    Task<Order?> UpdateStageAsync(Guid id, OrderStage stage);
}