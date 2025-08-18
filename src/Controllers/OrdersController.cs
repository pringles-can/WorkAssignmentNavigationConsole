using Microsoft.AspNetCore.Mvc;
using WorkAssignmentNavigationConsole.Models.Enums;
using WorkAssignmentNavigationConsole.Services;

namespace WorkAssignmentNavigationConsole.Controllers;

[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly OrderService _orderService;

    public OrdersController(OrderService orderService)
    {
        _orderService = orderService;
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrder()
    {
        var order = await _orderService.CreateOrderAsync();
        return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetOrder(Guid id)
    {
        var order = await _orderService.GetOrderAsync(id);
        if (order == null)
            return NotFound();
            
        return Ok(order);
    }

    [HttpPut("{id:guid}/stage")]
    public async Task<IActionResult> UpdateStage(Guid id, [FromBody] OrderStage stage)
    {
        var order = await _orderService.UpdateOrderStageAsync(id, stage);
        if (order == null)
            return NotFound();
            
        return Ok(order);
    }

    [HttpPost("{id:guid}/advance")]
    public async Task<IActionResult> AdvanceStage(Guid id)
    {
        var order = await _orderService.AdvanceOrderStageAsync(id);
        if (order == null)
            return NotFound();
            
        return Ok(order);
    }
}
