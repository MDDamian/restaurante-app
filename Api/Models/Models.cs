namespace Api.Models;

public class Product
{
    public string Id { get; set; } = null!;
    public string Name { get; set; } = null!;
    public decimal Price { get; set; }
    public string? Image { get; set; }
    public int SortOrder { get; set; }
}

public class OrderTable
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
}

public class OrderItem
{
    public int Id { get; set; }
    public string ProductId { get; set; } = null!;
    public Product? Product { get; set; }
    public int Quantity { get; set; }
    public string Note { get; set; } = "";
    public string OrderId { get; set; } = null!;
}

public class Order
{
    public string Id { get; set; } = null!;
    public int OrderNumber { get; set; }
    public int TableNumber { get; set; }
    public string WaiterName { get; set; } = null!;
    public string? ClientName { get; set; }
    public string? ClientDocument { get; set; }
    public List<OrderItem> Items { get; set; } = new();
    public bool IsCompleted { get; set; }
    public DateTime Timestamp { get; set; }
}
