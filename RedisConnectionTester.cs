using StackExchange.Redis;
using System.Text.Json;

class RedisConnectionTester
{
    static async Task Main(string[] args)
    {
        Console.WriteLine("Redis Connection Tester");
        Console.WriteLine("======================");
        
        // Get connection string from args or use default
        string connectionString = args.Length > 0 ? args[0] : "localhost:6379";
        Console.WriteLine($"Testing connection to: {connectionString}");
        Console.WriteLine();
        
        try
        {
            // Test basic connection
            Console.WriteLine("1. Testing basic connection...");
            using var mplexer = await ConnectionMultiplexer.ConnectAsync(connectionString);
            Console.WriteLine("   ✓ Connection established successfully");
            
            // Test database access
            Console.WriteLine("2. Testing database access...");
            var db = mplexer.GetDatabase();
            var pingResult = await db.PingAsync();
            Console.WriteLine($"   ✓ Ping successful (latency: {pingResult.TotalMilliseconds:F2}ms)");
            
            // Test basic operations
            Console.WriteLine("3. Testing basic operations...");
            
            // Test SET operation
            string testKey = $"test:connection:{Guid.NewGuid()}";
            string testValue = "Hello Redis!";
            await db.StringSetAsync(testKey, testValue, TimeSpan.FromMinutes(1));
            Console.WriteLine("   ✓ SET operation successful");
            
            // Test GET operation
            string retrievedValue = await db.StringGetAsync(testKey);
            if (retrievedValue == testValue)
            {
                Console.WriteLine("   ✓ GET operation successful");
            }
            else
            {
                Console.WriteLine("   ✗ GET operation failed - value mismatch");
            }
            
            // Test DELETE operation
            bool deleted = await db.KeyDeleteAsync(testKey);
            if (deleted)
            {
                Console.WriteLine("   ✓ DELETE operation successful");
            }
            else
            {
                Console.WriteLine("   ✗ DELETE operation failed");
            }
            
            // Get server info
            Console.WriteLine("4. Getting server information...");
            var server = mplexer.GetServer(mplexer.GetEndPoints().First());
            var info = await server.InfoAsync();
            var version = info.FirstOrDefault(x => x.Key == "redis_version");
            if (version.HasValue)
            {
                Console.WriteLine($"   ✓ Redis version: {version.Value.Value}");
            }
            
            Console.WriteLine();
            Console.WriteLine("🎉 All tests passed! Redis connection is working properly.");
            
        }
        catch (RedisConnectionException ex)
        {
            Console.WriteLine($"❌ Redis connection failed: {ex.Message}");
            Console.WriteLine();
            Console.WriteLine("Troubleshooting tips:");
            Console.WriteLine("1. Ensure Redis server is running");
            Console.WriteLine("2. Check if the connection string is correct");
            Console.WriteLine("3. Verify firewall settings");
            Console.WriteLine("4. For Azure Redis, ensure SSL settings are correct");
            Environment.Exit(1);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Unexpected error: {ex.Message}");
            Environment.Exit(1);
        }
    }
}
