namespace QuranHero.Api.Configuration;

public static class ProductionConfigurationValidator
{
    public static void Validate(IConfiguration configuration, IHostEnvironment environment)
    {
        if (environment.IsDevelopment() || environment.IsEnvironment("Testing"))
            return;

        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(configuration["Firebase:ProjectId"]))
            missing.Add("Firebase:ProjectId");
        if (string.IsNullOrWhiteSpace(configuration.GetConnectionString("QuranHero")))
            missing.Add("ConnectionStrings:QuranHero");

        if (missing.Count > 0)
        {
            throw new InvalidOperationException(
                $"Required production configuration is missing: {string.Join(", ", missing)}.");
        }
    }
}
