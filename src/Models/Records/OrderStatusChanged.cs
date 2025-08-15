using Server.Models.Enums;

namespace Server.Models.Records;

public record OrderStatusChanged(Guid OrderId, OrderStage Stage, DateTimeOffset AtUtc);