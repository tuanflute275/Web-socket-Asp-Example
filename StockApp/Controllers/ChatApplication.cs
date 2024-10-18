using Microsoft.AspNetCore.Mvc;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;

namespace ChatApplication.Controllers
{
    [ApiController]
    [Route("api/chat")]
    public class ChatController : ControllerBase
    {
        private static List<WebSocket> _clients = new List<WebSocket>();

        [HttpGet]
        public async Task Get()
        {
            if (HttpContext.WebSockets.IsWebSocketRequest)
            {
                var socket = await HttpContext.WebSockets.AcceptWebSocketAsync();
                _clients.Add(socket);
                await Receive(socket);
            }
            else
            {
                HttpContext.Response.StatusCode = 400;
            }
        }

        [HttpPost("change-background")]
        public async Task<IActionResult> ChangeBackground([FromBody] string color)
        {
            await SendMessageToAllClients(color);
            return Ok();
        }

        public static async Task SendMessageToAllClients(string message)
        {
            var buffer = Encoding.UTF8.GetBytes(message);
            var segment = new ArraySegment<byte>(buffer);

            foreach (var client in _clients)
            {
                if (client.State == WebSocketState.Open)
                {
                    await client.SendAsync(segment, WebSocketMessageType.Text, true, CancellationToken.None);
                }
            }
        }

        private async Task Receive(WebSocket socket)
        {
            var buffer = new byte[1024 * 4];
            WebSocketReceiveResult result;

            while (socket.State == WebSocketState.Open)
            {
                result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed by the WebSocket", CancellationToken.None);
                    _clients.Remove(socket);
                }
                else
                {
                    var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                    await SendMessageToAll(message);
                }
            }
        }

        private async Task SendMessageToAll(string message)
        {
            var buffer = Encoding.UTF8.GetBytes(message);
            var tasks = _clients.Select(client => client.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None));
            await Task.WhenAll(tasks);
        }
    }
}
