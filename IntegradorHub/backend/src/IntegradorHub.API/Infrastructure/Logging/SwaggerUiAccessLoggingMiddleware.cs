using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace IntegradorHub.API.Infrastructure.Logging
{
    public class SwaggerUiAccessLoggingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<SwaggerUiAccessLoggingMiddleware> _logger;

        public SwaggerUiAccessLoggingMiddleware(RequestDelegate next, ILogger<SwaggerUiAccessLoggingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var path = context.Request.Path.Value ?? string.Empty;
            if (path.StartsWith("/swagger") || path.Equals("/swagger/index.html"))
            {
                var user = context.User?.Identity?.Name ?? "anonymous";
                _logger.LogInformation("Swagger endpoint accessed: User={User} Method={Method} Path={Path} Query={QueryString}",
                    user, context.Request.Method, context.Request.Path, context.Request.QueryString);
            }

            await _next(context);
        }
    }
}
