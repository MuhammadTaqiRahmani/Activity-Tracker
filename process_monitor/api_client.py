import requests
import time
from datetime import datetime

class ApiClient:
    def __init__(self, base_url):
        self.base_url = base_url
        self.token = None
        self.token_refresh_interval = 300  # 5 minutes
        self.last_token_refresh = None
        self.headers = {'Content-Type': 'application/json'}
        self.max_retries = 3
        self.token_validated = False
        self.server_status = "Not connected"
        self.username = None
        self.user_id = None      # Store user_id when authenticated
        self.role = None         # Store user role when authenticated
        self.permissions = {}    # Store user permissions when authenticated
        
    def ensure_valid_token(self, force_refresh=False):
        """Check if token needs refreshing and refresh if needed"""
        current_time = datetime.now()
        needs_refresh = True if force_refresh else False

        if not needs_refresh and self.last_token_refresh:
            elapsed = (current_time - self.last_token_refresh).total_seconds()
            needs_refresh = elapsed >= self.token_refresh_interval

        if needs_refresh or not self.token or not self.token_validated:
            print(f"Token needs refresh. Force: {force_refresh}")
            
            # If we have stored credentials, use them
            if self.username and hasattr(self, 'password') and self.password:
                success = self.login(self.username, self.password)
                if success:
                    self.last_token_refresh = current_time
                    print("Token refreshed and headers updated")
                return success
            else:
                # No stored credentials, can't refresh
                print("No stored credentials, can't refresh token")
                return False
        return True

    def login(self, username, password, retry_count=0):
        """Authenticate with the server and get JWT token"""
        try:
            print("Attempting authentication...")
            
            # Save credentials for token refreshing
            self.username = username
            self.password = password  # Note: In a production app, consider more secure storage
            
            response = requests.post(
                f"{self.base_url}/api/users/login",
                json={'username': username, 'password': password},
                headers={'Content-Type': 'application/json'},
                timeout=10  # Add timeout to prevent hanging
            )
            
            if response.status_code == 200:
                data = response.json()
                self.token = data.get('token')
                
                # Store additional user info if available
                if 'userId' in data:
                    self.user_id = data.get('userId')
                if 'role' in data:
                    self.role = data.get('role')
                if 'permissions' in data:
                    self.permissions = data.get('permissions', {})
                    
                if self.token:
                    self.headers['Authorization'] = f'Bearer {self.token}'
                    self.token_validated = True
                    self.server_status = "Connected"
                    print(f"Authentication successful for user {username}")
                    print(f"Role: {self.role}")
                    self.last_token_refresh = datetime.now()
                    return True
                else:
                    self.token_validated = False
                    print("No token received in response")
                    return False
            else:
                self.token_validated = False
                error_msg = f"Authentication failed. Status code: {response.status_code}"
                try:
                    error_data = response.json()
                    if 'error' in error_data:
                        error_msg += f", Error: {error_data['error']}"
                except:
                    error_msg += f", Response: {response.text}"
                
                print(error_msg)
                
                # Retry logic for network/temporary errors but not for auth errors
                if response.status_code >= 500 and retry_count < self.max_retries:
                    retry_count += 1
                    print(f"Server error, retrying ({retry_count}/{self.max_retries})...")
                    time.sleep(2 ** retry_count)  # Exponential backoff
                    return self.login(username, password, retry_count)
                return False
        except requests.exceptions.RequestException as e:
            self.token_validated = False
            print(f"Connection error during login: {str(e)}")
            
            # Retry on connection errors
            if retry_count < self.max_retries:
                retry_count += 1
                print(f"Connection error, retrying ({retry_count}/{self.max_retries})...")
                time.sleep(2 ** retry_count)  # Exponential backoff
                return self.login(username, password, retry_count)
            return False

    def check_permission(self, permission_key):
        """Check if the user has a specific permission"""
        if not self.permissions:
            return False
        return self.permissions.get(permission_key, False)
            
    def is_admin(self):
        """Check if current user has admin privileges"""
        if not self.role:
            return False
        return self.role.upper() in ('ADMIN', 'SUPERADMIN')
    
    def is_superadmin(self):
        """Check if current user has superadmin privileges"""
        if not self.role:
            return False
        return self.role.upper() == 'SUPERADMIN'
        
    def logout(self):
        """Clear user session and token"""
        self.token = None
        self.username = None
        if hasattr(self, 'password'):
            del self.password
        self.token_validated = False
        self.server_status = "Not connected"
        self.last_token_refresh = None
        self.user_id = None
        self.role = None
        self.permissions = {}
        self.headers = {'Content-Type': 'application/json'}
        return True
            
    def send_batch(self, batch, retry_count=0):
        """Send process data batch to server with retry logic"""
        try:
            if not self.ensure_valid_token():
                return False
            
            # Handle empty batch
            if not batch:
                print("Empty batch, nothing to send")
                return True

            # Ensure proper JSON formatting for single item batches
            json_body = batch
            
            print(f"Sending batch with {len(batch)} items...")
            response = requests.post(
                f"{self.base_url}/api/logs/batch",
                json=json_body,
                headers=self.headers,
                timeout=15  # Add timeout to prevent hanging
            )
            
            if response.status_code == 403 and retry_count < self.max_retries:
                print("Token rejected (403), forcing refresh...")
                self.token_validated = False
                if self.ensure_valid_token(force_refresh=True):
                    return self.send_batch(batch, retry_count + 1)
                return False
                
            if response.status_code != 200:
                print(f"Error sending batch: {response.status_code} - {response.text}")
                if retry_count < self.max_retries:
                    print(f"Retrying batch send (attempt {retry_count + 1})...")
                    time.sleep(2 * (retry_count + 1))
                    return self.send_batch(batch, retry_count + 1)
                return False
                
            return True
            
        except requests.ConnectionError as e:
            print(f"Connection error sending batch: {str(e)}")
            if retry_count < self.max_retries:
                print(f"Retrying batch send (attempt {retry_count + 1})...")
                time.sleep(2 * (retry_count + 1))
                return self.send_batch(batch, retry_count + 1)
            return False
        except Exception as e:
            print(f"Error sending batch: {str(e)}")
            if retry_count < self.max_retries:
                print(f"Retrying batch send (attempt {retry_count + 1})...")
                time.sleep(2 * (retry_count + 1))
                return self.send_batch(batch, retry_count + 1)
            return False
    
    def check_server_status(self):
        """Check if the server is available"""
        try:
            response = requests.get(f"{self.base_url}/api/test/tracking", timeout=5)
            return response.status_code == 200
        except:
            return False

    def get_user_id(self):
        """Get the authenticated user's ID"""
        return self.user_id
