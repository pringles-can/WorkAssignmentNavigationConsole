using Server.Models.Enums;

namespace Server.Models;

// todo: Rename to WorkOrder(?)

public record Order
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public OrderStage Stage { get; set; } = OrderStage.Initial;
    public DateTimeOffset CreatedAtUtc { get; init; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAtUtc { get; set; } = DateTimeOffset.UtcNow;
}
