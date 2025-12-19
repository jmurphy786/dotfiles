## Aspire setup

### Create a new folder, typically called aspire-dashboard 

### To run aspire run this command

dotnet new aspire-apphost -n MyApp.AppHost

### This creates a new app host can name the AppHost anything

<ItemGroup>
    <ProjectReference Include="../../portalsv2-microservices/LoggingService\LoggingService.csproj" />
    <ProjectReference Include="../../portalsv2-microservices/PatientService\PatientService.csproj" />
    <ProjectReference Include="../../portalsv2-microservices/PortalsProxy\PortalsProxy.csproj" />
    <ProjectReference Include="../../portalsv2-microservices/PractitionerService\PractitionerService.csproj" />
    <ProjectReference Include="../../portalsv2-microservices/ReportService\ReportService.csproj" />
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
