using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace QuranHero.Api.Auth;

public static class FirebaseAuthenticationExtensions
{
    public static IServiceCollection AddFirebaseAuthentication(this IServiceCollection services, IConfiguration configuration)
    {
        var projectId = configuration["Firebase:ProjectId"];
        services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        }).AddJwtBearer(options =>
        {
            if (!string.IsNullOrWhiteSpace(projectId))
            {
                options.Authority = $"https://securetoken.google.com/{projectId}";
                options.Audience = projectId;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidIssuer = $"https://securetoken.google.com/{projectId}",
                    ValidAudience = projectId,
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true
                };
            }
            else
            {
                // Production remains fail-closed until Firebase is configured. Tests replace this scheme
                // with an internal test handler via WebApplicationFactory; no fake auth is registered here.
                options.Events = new JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        context.Fail("Firebase:ProjectId is not configured.");
                        return Task.CompletedTask;
                    }
                };
            }
        });
        services.AddAuthorization();
        return services;
    }
}
