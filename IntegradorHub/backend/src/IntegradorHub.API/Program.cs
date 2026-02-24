using MediatR;
using FluentValidation;
using IntegradorHub.API.Infrastructure.Logging;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Shared.Infrastructure.Repositories;
using IntegradorHub.API.Shared.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

// Railway inyecta PORT en runtime; en local corre en 5093 (launchSettings.json)
var port = Environment.GetEnvironmentVariable("PORT") ?? "5093";
builder.WebHost.UseUrls($"http://+:{port}");

// === SERVICES ===

// Controllers
builder.Services.AddControllers(options =>
{
    options.Filters.Add<SwaggerInteractionLoggingFilter>();
});

// register logging filter for DI
builder.Services.AddScoped<SwaggerInteractionLoggingFilter>();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    // Use full type name as schema id to avoid duplicate simple type names
    c.CustomSchemaIds(type => type.FullName?.Replace("+", ".") ?? type.Name);
});

// MediatR (CQRS)
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(typeof(Program).Assembly));

// FluentValidation
builder.Services.AddValidatorsFromAssembly(typeof(Program).Assembly);

// Repositories (Firestore)
builder.Services.AddSingleton<IUserRepository, UserRepository>();
builder.Services.AddScoped<IProjectRepository, ProjectRepository>();
builder.Services.AddScoped<IEvaluationRepository, EvaluationRepository>();
builder.Services.AddScoped<IGroupRepository, GroupRepository>();
builder.Services.AddScoped<IMateriaRepository, MateriaRepository>();
builder.Services.AddScoped<ICarreraRepository, CarreraRepository>();

// Storage Service (Supabase)
builder.Services.AddSingleton<IStorageService, SupabaseStorageService>();

// CORS — permite los orígenes configurados + cualquier origen adicional via env var
// CORS_ORIGINS (separados por coma) p.ej.: https://mi-app.vercel.app
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        // Orígenes base (desarrollo)
        var origins = new List<string>
        {
            "http://localhost:5173",
            "http://localhost:5174",
            "http://localhost:3000",
        };

        // Orígenes adicionales de producción desde variable de entorno
        var extraOrigins = Environment.GetEnvironmentVariable("CORS_ORIGINS");
        if (!string.IsNullOrWhiteSpace(extraOrigins))
        {
            origins.AddRange(extraOrigins.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
        }

        policy.WithOrigins([.. origins])
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();

        // Flutter móvil no envía CORS pero si algún cliente web adicional lo necesita:
        // descomenta la línea siguiente en lugar del bloque anterior
        // policy.SetIsOriginAllowed(_ => true).AllowAnyHeader().AllowAnyMethod().AllowCredentials();
    });
});

var app = builder.Build();

// === MIDDLEWARE ===

// Swagger habilitado siempre (útil para demo y testing en producción)
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "IntegradorHub API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors("AllowFrontend");
// Log accesses to Swagger endpoints
app.UseMiddleware<SwaggerUiAccessLoggingMiddleware>();
app.UseAuthorization();
app.MapControllers();

// Endpoint de prueba
app.MapGet("/api/health", () => new { status = "ok", timestamp = DateTime.UtcNow })
   .WithName("HealthCheck")
   .WithOpenApi();

app.Run();
