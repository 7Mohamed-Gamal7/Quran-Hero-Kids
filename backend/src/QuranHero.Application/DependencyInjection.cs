using Microsoft.Extensions.DependencyInjection;
using QuranHero.Application.Children;
using QuranHero.Application.Study;

namespace QuranHero.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IChildProfileService, ChildProfileService>();
        services.AddScoped<IStudySessionService, StudySessionService>();
        return services;
    }
}
