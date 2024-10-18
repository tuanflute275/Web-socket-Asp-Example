using Microsoft.AspNetCore.Mvc;
using StockApp.Models;

namespace StockApp.Controllers
{
    [ApiController]
    [Route("api/category")]
    public class CategoryController : ControllerBase
    {
        private static List<Category> categories = new List<Category>
        {
            new Category { CategoryId = 1, CategoryName = "Category 1", CategorySlug = "category-1" },
            new Category { CategoryId = 2, CategoryName = "Category 2", CategorySlug = "category-2" }
        };


        [HttpGet]
        public async Task<ActionResult<Category>> GetAll()
        {
            return Ok(categories);
        }

        [HttpGet("{id}")]
        public ActionResult<Category> GetById(int id)
        {
            var category = categories.FirstOrDefault(c => c.CategoryId == id);
            if (category == null)
            {
                return NotFound();
            }
            return Ok(category);
        }

        [HttpPost]
        public ActionResult<Category> Create(Category category)
        {
            category.CategoryId = categories.Max(c => c.CategoryId) + 1; // Tăng ID mới
            categories.Add(category);
            return CreatedAtAction(nameof(GetById), new { id = category.CategoryId }, category);
        }

        [HttpPut("{id}")]
        public IActionResult Update(int id, Category category)
        {
            var existingCategory = categories.FirstOrDefault(c => c.CategoryId == id);
            if (existingCategory == null)
            {
                return NotFound();
            }
            existingCategory.CategoryName = category.CategoryName;
            existingCategory.CategorySlug = category.CategorySlug;
            existingCategory.CategoryStatus = category.CategoryStatus;
            return NoContent();
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var category = categories.FirstOrDefault(c => c.CategoryId == id);
            if (category == null)
            {
                return NotFound();
            }
            categories.Remove(category);
            return NoContent();
        }
    }
}
