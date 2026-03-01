using Api.Data;
using Api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RestaurantController : ControllerBase
{
    private readonly RestaurantContext _context;

    public RestaurantController(RestaurantContext context)
    {
        _context = context;
    }

    [HttpGet("tables")]
    public async Task<ActionResult<IEnumerable<OrderTable>>> GetTables() => await _context.Tables.ToListAsync();

    [HttpPost("tables")]
    public async Task<IActionResult> SaveTables(List<OrderTable> tables)
    {
        var existing = await _context.Tables.ToListAsync();
        _context.Tables.RemoveRange(existing);
        await _context.Tables.AddRangeAsync(tables);
        await _context.SaveChangesAsync();
        return Ok();
    }

    [HttpGet("menu")]
    public async Task<ActionResult<IEnumerable<Product>>> GetMenu() => 
        await _context.Products.OrderBy(p => p.SortOrder).ToListAsync();

    [HttpPost("menu")]
    public async Task<IActionResult> SaveMenu(List<Product> products)
    {
        var existing = await _context.Products.ToListAsync();
        _context.Products.RemoveRange(existing);
        await _context.Products.AddRangeAsync(products);
        await _context.SaveChangesAsync();
        return Ok();
    }

    [HttpGet("orders")]
    public async Task<ActionResult<IEnumerable<Order>>> GetOrders() => 
        await _context.Orders.Include(o => o.Items).ThenInclude(i => i.Product).ToListAsync();

    [HttpPost("orders")]
    public async Task<IActionResult> SaveOrders(List<Order> orders)
    {
        // Simple strategy for local/sync app: replace all or update logic. 
        // For now, let's do a more robust upsert for orders.
        foreach (var order in orders)
        {
            var existing = await _context.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == order.Id);
            if (existing != null)
            {
                _context.Entry(existing).CurrentValues.SetValues(order);
                _context.OrderItems.RemoveRange(existing.Items);
                existing.Items = order.Items;
            }
            else
            {
                await _context.Orders.AddAsync(order);
            }
        }
        await _context.SaveChangesAsync();
        return Ok();
    }
    
    [HttpGet("counter")]
    public async Task<ActionResult<int>> GetCounter()
    {
        try 
        {
            var max = await _context.Orders.AnyAsync() 
                ? await _context.Orders.MaxAsync(o => o.OrderNumber) 
                : 0;
            return Ok(max + 1);
        }
        catch (Exception ex)
        {
            return StatusCode(500, ex.Message);
        }
    }
}
