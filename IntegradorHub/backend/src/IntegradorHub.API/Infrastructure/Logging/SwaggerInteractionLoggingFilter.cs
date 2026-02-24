using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Text;
using System.Text.Json;

namespace IntegradorHub.API.Infrastructure.Logging
{
    public class SwaggerInteractionLoggingFilter : IActionFilter
    {
        private readonly ILogger<SwaggerInteractionLoggingFilter> _logger;

        public SwaggerInteractionLoggingFilter(ILogger<SwaggerInteractionLoggingFilter> logger)
        {
            _logger = logger;
        }

        public void OnActionExecuting(ActionExecutingContext context)
        {
            var req = context.HttpContext.Request;
            var referer = req.Headers["Referer"].ToString();
            var userAgent = req.Headers["User-Agent"].ToString();
            var fromSwagger = (!string.IsNullOrEmpty(referer) && referer.Contains("/swagger", StringComparison.OrdinalIgnoreCase)) ||
                              (!string.IsNullOrEmpty(userAgent) && (userAgent.Contains("swagger-ui", StringComparison.OrdinalIgnoreCase) || userAgent.Contains("Swagger", StringComparison.OrdinalIgnoreCase)));

            if (fromSwagger)
            {
                var user = context.HttpContext.User?.Identity?.Name ?? "anonymous";
                var route = context.ActionDescriptor.DisplayName ?? "unknown";
                _logger.LogInformation("Swagger UI request: User={User} Route={Route} Method={Method} Path={Path} QueryString={QueryString}",
                    user, route, req.Method, req.Path, req.QueryString);
            }

            var path = req.Path.Value?.ToLowerInvariant() ?? string.Empty;
            if (path.Contains("login") || path.Contains("authenticate") || path.Contains("signin"))
            {
                try
                {
                    req.EnableBuffering();
                    using var reader = new StreamReader(req.Body, Encoding.UTF8, detectEncodingFromByteOrderMarks: false, leaveOpen: true);
                    var body = reader.ReadToEnd();
                    req.Body.Position = 0;

                    string userField = null;
                    if (!string.IsNullOrEmpty(body))
                    {
                        try
                        {
                            using var doc = JsonDocument.Parse(body);
                            if (doc.RootElement.TryGetProperty("username", out var u)) userField = u.GetString();
                            else if (doc.RootElement.TryGetProperty("email", out var e)) userField = e.GetString();
                        }
                        catch { }
                    }

                    _logger.LogInformation("Authentication attempt: Path={Path} Method={Method} UserField={UserField}", req.Path, req.Method, userField ?? "unknown");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to parse authentication request body");
                }
            }
        }

        public void OnActionExecuted(ActionExecutedContext context)
        {
            var req = context.HttpContext.Request;
            var referer = req.Headers["Referer"].ToString();
            if (!string.IsNullOrEmpty(referer) && referer.Contains("/swagger", StringComparison.OrdinalIgnoreCase))
            {
                var status = context.HttpContext.Response?.StatusCode;
                _logger.LogInformation("Swagger UI response: Path={Path} StatusCode={StatusCode}", req.Path, status);
            }
        }
    }
}
