using MediatR;
using FluentValidation;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Shared.Infrastructure.Repositories;
using IntegradorHub.API.Shared.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

// === SERVICES ===

// Controllers
builder.Services.AddControllers();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

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

// HTTP Request Logging
builder.Services.AddHttpLogging(logging =>
{
    logging.LoggingFields = Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.RequestMethod
        | Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.RequestPath
        | Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.ResponseStatusCode
        | Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.Duration;
});

// CORS (para React Frontend)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:5173", "http://localhost:5174", "http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

var app = builder.Build();

// === MIDDLEWARE ===

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpLogging();
app.UseCors("AllowFrontend");
app.UseAuthorization();
app.MapControllers();

// Endpoint de prueba
app.MapGet("/api/health", () => new { status = "ok", timestamp = DateTime.UtcNow })
   .WithName("HealthCheck")
   .WithOpenApi();

app.Run();
