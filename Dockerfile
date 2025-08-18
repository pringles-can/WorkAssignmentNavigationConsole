# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY WorkAssignmentNavigationConsole.csproj ./
RUN dotnet restore WorkAssignmentNavigationConsole.csproj

# Copy the rest of the source
COPY . .

# Publish
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

# Overridden by docker-compose or environment
# ENV Azure__SignalR__ConnectionString=
# ENV Redis__ConnectionString=localhost:6379

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "WorkAssignmentNavigationConsole.dll"]