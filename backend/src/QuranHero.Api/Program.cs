using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using System.Text.Json;
using System.Text.Json.Serialization;
using QuranHero.Api.Auth;
using QuranHero.Application;
using QuranHero.Infrastructure;
using QuranHero.Infrastructure.Persistence;
using QuranHero.Api.OpenApi;
using QuranHero.Api.Configuration;

var builder = WebApplication.CreateBuilder(args);

ProductionConfigurationValidator.Validate(builder.Configuration, builder.Environment);
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration, builder.Environment);
builder.Services.AddFirebaseAuthentication(builder.Configuration);
builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Quran Hero Kids API",
        Version = "v1",
        Description = "API لإدارة ملفات الأسرة وجلسات تعلم الأطفال."
    });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Firebase ID token: Bearer {token}"
    });
    options.OperationFilter<AuthorizeOperationFilter>();
});

var app = builder.Build();

if (app.Environment.IsDevelopment() || app.Environment.IsEnvironment("Testing"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<QuranHeroDbContext>();
    await db.Database.EnsureCreatedAsync();
}

if (app.Environment.IsDevelopment() || app.Environment.IsEnvironment("Testing"))
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.MapGet("/health", () => Results.Ok(new HealthResponse("ok")))
    .Produces<HealthResponse>(StatusCodes.Status200OK)
    .AllowAnonymous()
    .WithName("GetHealth")
    .WithTags("System");

app.Run();

public sealed record HealthResponse(string Status);

public partial class Program;
