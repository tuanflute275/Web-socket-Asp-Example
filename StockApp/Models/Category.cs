namespace StockApp.Models
{
    public class Category
    {
        public int CategoryId { get; set; }
        public string CategoryName { get; set; }
        public string? CategorySlug { get; set; }
        public bool CategoryStatus { get; set; } = true;
    }
}
