import psutil
import os
from datetime import datetime, timedelta

class ProcessMonitor:
    def __init__(self):
        self.user_id = None  # Initialize as None, will be set after login
        self.process_count = 0
        self.categories = self.initialize_categories()
        
    def set_user_id(self, user_id):
        """Set the user ID for process monitoring"""
        if user_id is None:
            raise ValueError("User ID cannot be None")
        
        self.user_id = user_id
        print(f"Process monitor user ID set to: {self.user_id}")
        
    def get_active_processes(self):
        """Get a list of active processes with window titles"""
        if self.user_id is None:
            raise ValueError("User ID is not set. Please log in first.")
            
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'exe']):
            try:
                # Only include processes with window titles
                if proc.info['name']:
                    # Add window title information
                    window_title = self.get_window_title(proc.pid, proc.info['name'])
                    if window_title:  # Only include processes with window titles
                        proc_info = proc.info.copy()
                        proc_info['window_title'] = window_title
                        processes.append(proc_info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        self.process_count = len(processes)
        return processes
        
    def get_window_title(self, pid, fallback_name):
        """Get window title for a process - platform specific implementation"""
        try:
            # Windows implementation
            import ctypes
            from ctypes import wintypes
            
            user32 = ctypes.windll.user32
            
            # Define necessary Windows API functions and types
            EnumWindows = user32.EnumWindows
            EnumWindowsProc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
            GetWindowText = user32.GetWindowTextW
            GetWindowTextLength = user32.GetWindowTextLengthW
            IsWindowVisible = user32.IsWindowVisible
            GetWindowThreadProcessId = user32.GetWindowThreadProcessId
            
            titles = []
            
            def foreach_window(hwnd, lParam):
                if IsWindowVisible(hwnd):
                    length = GetWindowTextLength(hwnd)
                    if length > 0:
                        buff = ctypes.create_unicode_buffer(length + 1)
                        GetWindowText(hwnd, buff, length + 1)
                        process_id = wintypes.DWORD()
                        GetWindowThreadProcessId(hwnd, ctypes.byref(process_id))
                        if process_id.value == pid:
                            titles.append(buff.value)
                return True
                
            EnumWindows(EnumWindowsProc(foreach_window), 0)
            
            if titles:
                return titles[0]  # Return the first window title found
                
        except Exception:
            pass
            
        return fallback_name  # Fallback to process name if window title not found
        
    def prepare_batch(self, processes):
        """Convert process information to the format expected by the server"""
        if self.user_id is None:
            raise ValueError("User ID is not set. Please log in first.")
            
        current_time = datetime.now()
        
        batch = []
        for proc in processes:
            try:
                process_name = proc['name']
                window_title = proc.get('window_title', process_name)
                application_path = proc.get('exe', '') or ''
                
                # Create the process data record
                process_data = {
                    'userId': self.user_id,
                    'processName': process_name,
                    'windowTitle': window_title,
                    'processId': str(proc['pid']),
                    'applicationPath': application_path,
                    'startTime': current_time.isoformat(),
                    'endTime': (current_time + timedelta(minutes=1)).isoformat(),
                    'durationSeconds': 60,
                    'category': self.categorize_process(process_name, window_title, application_path),
                    'isProductiveApp': self.is_productive_app(process_name, window_title),
                    'activityType': 'PROCESS_MONITORING',
                    'description': f"Process monitoring: {process_name}",
                    'workspaceType': 'LOCAL',
                    'applicationCategory': self.get_application_category(process_name, window_title)
                }
                batch.append(process_data)
            except Exception as e:
                print(f"Error preparing process data: {str(e)}")
                continue
                
        return batch
        
    def initialize_categories(self):
        """Initialize process categories"""
        return {
            'browsers': ['chrome', 'firefox', 'msedge', 'opera', 'iexplore', 'brave'],
            'development': ['code', 'idea', 'pycharm', 'visual studio', 'eclipse', 'android studio', 'xcode'],
            'productivity': ['excel', 'word', 'powerpoint', 'outlook', 'onenote', 'acrobat', 'notepad'],
            'communication': ['teams', 'slack', 'zoom', 'skype', 'discord', 'telegram'],
            'entertainment': ['spotify', 'netflix', 'vlc', 'itunes', 'steam', 'epic'],
            'system': ['explorer', 'cmd', 'powershell', 'task manager', 'control panel', 'settings']
        }
        
    def categorize_process(self, process_name, window_title, app_path):
        """Categorize a process based on name, window title and path"""
        name_lower = process_name.lower()
        title_lower = window_title.lower()
        
        # Check in browser category
        if any(browser in name_lower or browser in title_lower for browser in self.categories['browsers']):
            return 'BROWSER'
            
        # Check in development category
        if any(dev_tool in name_lower or dev_tool in title_lower for dev_tool in self.categories['development']):
            return 'DEVELOPMENT'
            
        # Check in productivity category
        if any(prod_tool in name_lower or prod_tool in title_lower for prod_tool in self.categories['productivity']):
            return 'PRODUCTIVITY'
            
        # Check in communication category
        if any(comm_tool in name_lower or comm_tool in title_lower for comm_tool in self.categories['communication']):
            return 'COMMUNICATION'
            
        # Check in entertainment category
        if any(ent_tool in name_lower or ent_tool in title_lower for ent_tool in self.categories['entertainment']):
            return 'ENTERTAINMENT'
            
        # Check in system category
        if any(sys_tool in name_lower or sys_tool in title_lower for sys_tool in self.categories['system']):
            return 'SYSTEM'
            
        # Default category
        return 'OTHER'
        
    def is_productive_app(self, process_name, window_title):
        """Determine if an application is generally productive"""
        category = self.categorize_process(process_name, window_title, '')
        productive_categories = ['DEVELOPMENT', 'PRODUCTIVITY', 'COMMUNICATION']
        return category in productive_categories
        
    def get_application_category(self, process_name, window_title):
        """Get application category for reporting"""
        return self.categorize_process(process_name, window_title, '')
