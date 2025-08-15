using WorkAssignmentNavigationConsole.Models.Enums;

namespace WorkAssignmentNavigationConsole.Models.Records;

public record OrderStatusChanged(Guid OrderId, OrderStage Stage, DateTimeOffset AtUtc);