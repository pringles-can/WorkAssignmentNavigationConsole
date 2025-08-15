# ASP.NET Core 8 + SignalR + Azure SignalR (optional) + Redis + Docker + GitHub Actions

Minimal "tracker" app. It supports:
- SignalR in-process locally
- Azure SignalR Service offload (if you provide the connection string)
- Redis cache for basic chat history storage

## Prerequisites
- Docker Desktop (recommended) 
- .NET 8 SDK if you want `dotnet run`
- GitHub account and repository (for Actions/Container Registry)
- Optional: Azure subscription if you want Azure SignalR Service

## Run locally with Docker