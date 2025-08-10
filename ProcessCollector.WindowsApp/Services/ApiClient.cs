using System.Net.Http.Headers;
using Newtonsoft.Json;

namespace ProcessCollector.WindowsApp.Services
{
    public class ApiClient
    {
        private readonly HttpClient _httpClient;
        private string _authToken;

        public ApiClient(string baseUrl)
        {
            _httpClient = new HttpClient { BaseAddress = new Uri(baseUrl) };
        }

        public async Task Authenticate(string username, string password)
        {
            var loginData = new { username, password };
            var response = await _httpClient.PostAsJsonAsync("/api/users/login", loginData);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<LoginResponse>();
            _authToken = result.Token;
            _httpClient.DefaultRequestHeaders.Authorization = 
                new AuthenticationHeaderValue("Bearer", _authToken);
        }

        public async Task SendProcessBatch(List<ProcessData> batch)
        {
            var response = await _httpClient.PostAsJsonAsync("/api/logs/batch", batch);
            response.EnsureSuccessStatusCode();
        }

        private class LoginResponse
        {
            public string Token { get; set; }
        }
    }
}
