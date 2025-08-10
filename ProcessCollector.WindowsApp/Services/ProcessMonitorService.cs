using System.Diagnostics;
using System.Net.Http.Headers;
using Newtonsoft.Json;

namespace ProcessCollector.WindowsApp.Services
{
    public class ProcessMonitorService
    {
        private readonly HttpClient _httpClient;
        private long _userId;
        private string _authToken;

        public ProcessMonitorService(string baseUrl)
        {
            _httpClient = new HttpClient { BaseAddress = new Uri(baseUrl) };
        }

        public async Task Initialize(long userId)
        {
            _userId = userId;
            await Authenticate();
        }

        private async Task Authenticate()
        {
            var loginData = new
            {
                username = "testuser_211178658",
                password = "password123"
            };

            var response = await _httpClient.PostAsync("/api/users/login",
                new StringContent(JsonConvert.SerializeObject(loginData), System.Text.Encoding.UTF8, "application/json"));
            
            response.EnsureSuccessStatusCode();
            
            var result = JsonConvert.DeserializeObject<Dictionary<string, string>>(
                await response.Content.ReadAsStringAsync());
            
            _authToken = result["token"];
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _authToken);
        }

        public async Task<(int ProcessCount, int BatchCount)> CollectAndSendProcesses()
        {
            var processes = GetCurrentProcesses();
            var batches = processes.Chunk(3).ToList();
            
            foreach (var batch in batches)
            {
                await SendProcessBatch(batch);
            }

            return (processes.Count, batches.Count);
        }

        private List<Dictionary<string, object>> GetCurrentProcesses()
        {
            var currentTime = DateTime.Now;
            
            return Process.GetProcesses()
                .Where(p => !string.IsNullOrEmpty(p.MainWindowTitle))
                .Select(p => new Dictionary<string, object>
                {
                    ["userId"] = _userId,
                    ["processName"] = p.ProcessName,
                    ["windowTitle"] = p.MainWindowTitle,
                    ["processId"] = p.Id.ToString(),
                    ["applicationPath"] = GetProcessPath(p),
                    ["startTime"] = currentTime.ToString("yyyy-MM-ddTHH:mm:ss"),
                    ["endTime"] = currentTime.AddMinutes(1).ToString("yyyy-MM-ddTHH:mm:ss"),
                    ["durationSeconds"] = 60,
                    ["category"] = "SYSTEM",
                    ["isProductiveApp"] = true,
                    ["activityType"] = "PROCESS_MONITORING",
                    ["description"] = $"Process: {p.ProcessName}",
                    ["workspaceType"] = "LOCAL",
                    ["applicationCategory"] = "SYSTEM"
                })
                .ToList();
        }

        private string GetProcessPath(Process process)
        {
            try
            {
                return process.MainModule?.FileName ?? string.Empty;
            }
            catch
            {
                return string.Empty;
            }
        }

        private async Task SendProcessBatch(IEnumerable<Dictionary<string, object>> batch)
        {
            var response = await _httpClient.PostAsync("/api/logs/batch",
                new StringContent(JsonConvert.SerializeObject(batch), System.Text.Encoding.UTF8, "application/json"));
            
            response.EnsureSuccessStatusCode();
        }
    }
}
