## Aspire setup

### Create a new folder, typically called aspire-dashboard 

### To run aspire run this command

dotnet new aspire-apphost -n MyApp.AppHost

### This creates a new app host can name the AppHost anything

<ItemGroup>
    <ProjectReference Include="../../path\LoggingService.csproj" />
    <ProjectReference Include="../../path\PatientService.csproj" />
    <ProjectReference Include="../../path\PortalsProxy.csproj" />
    <ProjectReference Include="../../path\PractitionerService.csproj" />
    <ProjectReference Include="../../path\ReportService.csproj" />
</ItemGroup>

### Add these to the cs proj, is going to be whatever your relative route is 


```cs
var builder = DistributedApplication.CreateBuilder(new DistributedApplicationOptions
{
    EnableResourceLogging = true,
    DisableDashboard = true
});

builder.AddProject<Projects.LoggingService>("logging");
builder.AddProject<Projects.PatientService>("patient");
builder.AddProject<Projects.PortalsProxy>("proxy");
builder.AddProject<Projects.PractitionerService>("practitioner");
builder.AddProject<Projects.ReportService>("report");

builder.Build().Run();

```

### This would use the project reference and then instantiate them

##  Logging

To enable logging on repo's that either dont use it or have their own custom logic or appsettings rules you can override it from the aspire dashboard as shown

You'll want to create a AspireExtensions file that overrides the noisy logs and sets formatting options


```cs


public static class AspireExtensions
{
  public static IResourceBuilder<T> WithQuietHttpLogging<T>(this IResourceBuilder<T> builder)
    where T : IResourceWithEnvironment
    {
      return builder
           // JSON formatter configuration
            .WithEnvironment("Logging__Console__FormatterName", "json")
            .WithEnvironment("Logging__Console__FormatterOptions__JsonWriterOptions__Indented", "false")
            .WithEnvironment("Logging__Console__FormatterOptions__IncludeScopes", "false")
            .WithEnvironment("Logging__Console__FormatterOptions__TimestampFormat", "yyyy-MM-dd'T'HH:mm:ss.fffK")
            .WithEnvironment("Logging__Console__FormatterOptions__UseUtcTimestamp", "true")
            
            // Default levels
            .WithEnvironment("Logging__LogLevel__Default", "Information")  // Changed from Debug
            
            // Suppress ALL Microsoft internal logs unless Error
            .WithEnvironment("Logging__LogLevel__Microsoft", "Error")
            .WithEnvironment("Logging__LogLevel__Microsoft.AspNetCore", "Error")
            .WithEnvironment("Logging__LogLevel__Microsoft.EntityFrameworkCore", "Error")
            .WithEnvironment("Logging__LogLevel__Microsoft.Extensions.Http", "Error")  // This one!
            .WithEnvironment("Logging__LogLevel__Microsoft.Extensions.Http.Logging", "Error")  // And this!
            
            // Suppress System logs
            .WithEnvironment("Logging__LogLevel__System", "Error")
            .WithEnvironment("Logging__LogLevel__System.Net.Http", "Error")
            .WithEnvironment("Logging__LogLevel__System.Net.Http.HttpClient", "Error")
            
            // Suppress other noisy libraries
            .WithEnvironment("Logging__LogLevel__Polly", "Error")
            .WithEnvironment("Logging__LogLevel__Yarp", "Error")
            
            // Keep YOUR logs at Debug level
            .WithEnvironment("Logging__LogLevel__PatientService", "Debug")
            .WithEnvironment("Logging__LogLevel__PractitionerService", "Debug")
            .WithEnvironment("Logging__LogLevel__LoggingService", "Debug")
            .WithEnvironment("Logging__LogLevel__ReportService", "Debug")
            .WithEnvironment("Logging__LogLevel__Shared", "Debug");
    }

  public static IResourceBuilder<T> WithSingleLineLogging<T>(this IResourceBuilder<T> builder)
    where T : IResourceWithEnvironment
    {
      return builder
        .WithEnvironment("Logging__Console__FormatterName", "json")
        .WithEnvironment("Logging__Console__FormatterOptions__JsonWriterOptions__Indented", "false")
        .WithEnvironment("Logging__Console__FormatterOptions__IncludeScopes", "true")
        .WithEnvironment("Logging__Console__FormatterOptions__TimestampFormat", "yyyy-MM-dd'T'HH:mm:ss.fffK");
    }

  // Or combine them:
  public static IResourceBuilder<T> WithCleanLogging<T>(this IResourceBuilder<T> builder)
    where T : IResourceWithEnvironment
    {
      return builder
        .WithQuietHttpLogging()
        .WithSingleLineLogging();
    }
}

```

And then use them as follows 

```cs

builder.AddProject<Projects.LoggingService>("logging").WithCleanLogging();

```
