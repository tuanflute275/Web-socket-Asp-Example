using Microsoft.AspNetCore.Mvc;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace StockApp.Controllers
{
    [ApiController]
    [Route("api/websocket")]
    public class HomeController : ControllerBase
    {
        [HttpGet]
        public async Task Get()
        {
            if (HttpContext.WebSockets.IsWebSocketRequest)
            {
                // Chấp nhận kết nối WebSocket
                WebSocket webSocket = await HttpContext.WebSockets.AcceptWebSocketAsync();
                //sinh ngẫu nhiên 2 giá trị x,y thay đổi mỗi 2 giây
                var random = new Random();
                while(webSocket.State == WebSocketState.Open)
                {
                    // tạo giá trị ngẫu nhiên
                    int x = random.Next(1, 100);
                    int y = random.Next(1, 100);
                    var buffer = Encoding.UTF8.GetBytes($"{{ \"x\": {x}, \"y\": {y} }}");
                    await webSocket.SendAsync(
                            new ArraySegment<byte>(buffer),
                            WebSocketMessageType.Text, true, CancellationToken.None
                        );
                    await Task.Delay(2000);
                }

            }
            else
            {
                // Trả về trạng thái 400 nếu không phải là yêu cầu WebSocket
                HttpContext.Response.StatusCode = 400;
                await HttpContext.Response.WriteAsync("Not a websocket request.");
            }
        }
    }
}
