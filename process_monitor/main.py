import sys
import traceback
from datetime import datetime
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
                            QPushButton, QTextEdit, QLabel, QSpinBox, QStatusBar, 
                            QComboBox, QGroupBox, QProgressBar, QMessageBox, QDialog,
                            QLineEdit, QFormLayout, QDialogButtonBox)
from PyQt6.QtCore import QTimer, Qt, pyqtSlot
from PyQt6.QtGui import QColor, QTextCursor, QFont, QIcon
from monitor import ProcessMonitor
from api_client import ApiClient

def check_qt_installation():
    try:
        from PyQt6.QtCore import QT_VERSION_STR
        print(f"PyQt6 version: {QT_VERSION_STR}")
        return True
    except ImportError as e:
        print("Error: PyQt6 not properly installed")
        print(f"Error details: {str(e)}")
        print("\nTry running setup.bat to fix dependencies")
        return False

class LoginDialog(QDialog):
    """Login dialog for user authentication"""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Login")
        self.setMinimumWidth(300)
        
        # Create form layout
        layout = QFormLayout(self)
        
        # Create widgets
        self.server_input = QComboBox()
        self.server_input.addItem("http://localhost:8081")
        self.server_input.setEditable(True)
        
        self.username_input = QLineEdit()
        self.username_input.setPlaceholderText("Enter your username")
        self.username_input.setText("Naqi111")  # Default for testing
        
        self.password_input = QLineEdit()
        self.password_input.setPlaceholderText("Enter your password")
        self.password_input.setEchoMode(QLineEdit.EchoMode.Password)
        self.password_input.setText("123niqi123111.com")  # Default for testing
        
        # Add widgets to form
        layout.addRow("Server:", self.server_input)
        layout.addRow("Username:", self.username_input)
        layout.addRow("Password:", self.password_input)
        
        # Add buttons
        self.button_box = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | 
                                          QDialogButtonBox.StandardButton.Cancel)
        self.button_box.accepted.connect(self.accept)
        self.button_box.rejected.connect(self.reject)
        layout.addRow(self.button_box)

    def get_credentials(self):
        """Return the server URL, username and password"""
        return (self.server_input.currentText(),
                self.username_input.text(), 
                self.password_input.text())

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Process Activity Monitor")
        self.setMinimumSize(800, 600)
        
        # Initialize components
        self.process_monitor = ProcessMonitor()
        self.api_client = ApiClient("http://localhost:8081") # This will be overridden in login
        self.max_batch_size = 3
        self.setup_ui()
        
        # Setup timers
        self.collection_timer = QTimer()
        self.collection_timer.timeout.connect(self.collect_processes)
        
        self.connection_timer = QTimer()
        self.connection_timer.timeout.connect(self.check_connection)
        self.connection_timer.start(5000)  # Check connection every 5 seconds
        
        # Initialize status
        self.update_connection_status("Not connected")
        
        # Show login dialog at startup
        QTimer.singleShot(100, self.show_login_dialog)
        
    def setup_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        
        # Settings group
        settings_group = QGroupBox("Settings")
        settings_layout = QHBoxLayout()
        
        # Server settings
        server_layout = QVBoxLayout()
        server_label = QLabel("Server URL:")
        self.server_combo = QComboBox()
        self.server_combo.addItem("http://localhost:8081")
        self.server_combo.setEditable(True)
        server_layout.addWidget(server_label)
        server_layout.addWidget(self.server_combo)
        
        # User settings
        user_layout = QVBoxLayout()
        user_label = QLabel("Logged in as:")
        self.user_label = QLabel("Not logged in")
        self.user_label.setStyleSheet("font-weight: bold; color: gray;")
        user_layout.addWidget(user_label)
        user_layout.addWidget(self.user_label)
        
        # Collection settings
        interval_layout = QVBoxLayout()
        interval_label = QLabel("Collection Interval:")
        self.interval_spin = QSpinBox()
        self.interval_spin.setRange(30, 300)
        self.interval_spin.setValue(60)
        self.interval_spin.setSuffix(" seconds")
        interval_layout.addWidget(interval_label)
        interval_layout.addWidget(self.interval_spin)
        
        # Batch settings
        batch_layout = QVBoxLayout()
        batch_label = QLabel("Batch Size:")
        self.batch_spin = QSpinBox()
        self.batch_spin.setRange(1, 10)
        self.batch_spin.setValue(3)
        self.batch_spin.setEnabled(False)  # Disable for now
        batch_layout.addWidget(batch_label)
        batch_layout.addWidget(self.batch_spin)
        
        settings_layout.addLayout(server_layout)
        settings_layout.addLayout(user_layout)
        settings_layout.addLayout(interval_layout)
        settings_layout.addLayout(batch_layout)
        settings_group.setLayout(settings_layout)
        main_layout.addWidget(settings_group)
        
        # Control group
        control_group = QGroupBox("Control")
        control_layout = QHBoxLayout()
        
        # Login/Logout button
        self.login_button = QPushButton("Login")
        self.login_button.clicked.connect(self.show_login_dialog)
        control_layout.addWidget(self.login_button)
        
        # Start/Stop buttons
        self.start_button = QPushButton("Start Monitoring")
        self.start_button.clicked.connect(self.start_monitoring)
        self.start_button.setEnabled(False)  # Disabled until connected
        control_layout.addWidget(self.start_button)
        
        self.stop_button = QPushButton("Stop Monitoring")
        self.stop_button.clicked.connect(self.stop_monitoring)
        self.stop_button.setEnabled(False)
        control_layout.addWidget(self.stop_button)
        
        control_group.setLayout(control_layout)
        main_layout.addWidget(control_group)
        
        # Status group
        status_group = QGroupBox("Status")
        status_layout = QVBoxLayout()
        
        # Connection status
        conn_layout = QHBoxLayout()
        conn_label = QLabel("Connection:")
        self.conn_status = QLabel("Not connected")
        self.conn_status.setStyleSheet("font-weight: bold; color: gray;")
        conn_layout.addWidget(conn_label)
        conn_layout.addWidget(self.conn_status)
        conn_layout.addStretch()
        
        # Monitoring status
        monitor_layout = QHBoxLayout()
        monitor_label = QLabel("Monitoring:")
        self.monitor_status = QLabel("Stopped")
        self.monitor_status.setStyleSheet("font-weight: bold; color: gray;")
        monitor_layout.addWidget(monitor_label)
        monitor_layout.addWidget(self.monitor_status)
        monitor_layout.addStretch()
        
        # Process count
        count_layout = QHBoxLayout()
        count_label = QLabel("Processes tracked:")
        self.count_value = QLabel("0")
        count_layout.addWidget(count_label)
        count_layout.addWidget(self.count_value)
        count_layout.addStretch()
        
        status_layout.addLayout(conn_layout)
        status_layout.addLayout(monitor_layout)
        status_layout.addLayout(count_layout)
        status_group.setLayout(status_layout)
        main_layout.addWidget(status_group)
        
        # Log output
        log_group = QGroupBox("Activity Log")
        log_layout = QVBoxLayout()
        self.log_output = QTextEdit()
        self.log_output.setReadOnly(True)
        self.log_output.setFont(QFont("Consolas", 10))
        self.log_output.setStyleSheet("background-color: #F0F0F0;")
        log_layout.addWidget(self.log_output)
        log_group.setLayout(log_layout)
        main_layout.addWidget(log_group, stretch=1)
        
        # Status bar
        self.status_bar = QStatusBar()
        self.setStatusBar(self.status_bar)
        self.status_bar.showMessage("Ready")
    
    def show_login_dialog(self):
        """Show login dialog and handle authentication"""
        dialog = LoginDialog(self)
        if dialog.exec():
            server, username, password = dialog.get_credentials()
            self.server_combo.setCurrentText(server)
            
            # Update server URL in API client
            self.api_client = ApiClient(server)
            
            # Attempt login
            self.log_message(f"Attempting to login as {username}...")
            self.status_bar.showMessage("Logging in...")
            
            success = self.api_client.login(username, password)
            if success:
                self.update_connection_status("Connected")
                self.login_button.setText("Logout")
                self.login_button.clicked.disconnect()
                self.login_button.clicked.connect(self.logout_user)
                self.start_button.setEnabled(True)
                
                # Update UI with user info
                self.user_label.setText(f"{username} (ID: {self.api_client.get_user_id()})")
                self.user_label.setStyleSheet("font-weight: bold; color: green;")
                
                self.log_message(f"Successfully logged in as {username}")
                self.status_bar.showMessage("Login successful")
            else:
                # Login failed
                self.update_connection_status("Failed")
                self.log_message("Login failed. Check credentials.", error=True)
                self.status_bar.showMessage("Login failed")
                
                # Show error message
                QMessageBox.warning(
                    self,
                    "Login Failed",
                    "Could not log in. Please check your credentials and try again.",
                    QMessageBox.StandardButton.Ok
                )
    
    def logout_user(self):
        """Log out the current user"""
        if self.collection_timer.isActive():
            # Stop monitoring first
            self.stop_monitoring()
            
        # Logout in API client
        if self.api_client.logout():
            self.update_connection_status("Not connected")
            self.login_button.setText("Login")
            self.login_button.clicked.disconnect()
            self.login_button.clicked.connect(self.show_login_dialog)
            self.start_button.setEnabled(False)
            
            # Update UI
            self.user_label.setText("Not logged in")
            self.user_label.setStyleSheet("font-weight: bold; color: gray;")
            
            self.log_message("Logged out successfully")
            self.status_bar.showMessage("Logged out")
        else:
            self.log_message("Failed to log out", error=True)
    
    def check_connection(self):
        """Periodically check connection status"""
        if self.api_client.server_status != self.conn_status.text():
            self.update_connection_status(self.api_client.server_status)
    
    def update_connection_status(self, status):
        """Update the connection status in the UI"""
        self.conn_status.setText(status)
        if status == "Connected":
            self.conn_status.setStyleSheet("font-weight: bold; color: green;")
        elif status == "Failed" or status == "Server unavailable":
            self.conn_status.setStyleSheet("font-weight: bold; color: red;")
        else:
            self.conn_status.setStyleSheet("font-weight: bold; color: gray;")
            
    def start_monitoring(self):
        try:
            # Check if connected
            if not self.api_client.token_validated:
                success = self.api_client.ensure_valid_token()
                if not success:
                    self.log_message("Not authenticated. Please log in.", error=True)
                    self.show_login_dialog()
                    return
                
            # Set the user ID from the logged in user
            user_id = self.api_client.get_user_id()
            if not user_id:
                self.log_message("No user ID available. Please log in again.", error=True)
                return
                
            self.process_monitor.set_user_id(int(user_id))
            interval = self.interval_spin.value() * 1000  # Convert to milliseconds
            self.collection_timer.start(interval)
            
            self.start_button.setEnabled(False)
            self.stop_button.setEnabled(True)
            self.interval_spin.setEnabled(False)
            self.login_button.setEnabled(False)  # Disable logout during monitoring
            
            self.monitor_status.setText("Running")
            self.monitor_status.setStyleSheet("font-weight: bold; color: green;")
            
            self.log_message(f"Process monitoring started (interval: {self.interval_spin.value()}s)")
            self.status_bar.showMessage("Monitoring active")
            
        except Exception as e:
            self.log_message(f"Error starting monitor: {str(e)}", error=True)
            
    def stop_monitoring(self):
        self.collection_timer.stop()
        
        self.start_button.setEnabled(True)
        self.stop_button.setEnabled(False)
        self.interval_spin.setEnabled(True)
        self.login_button.setEnabled(True)  # Re-enable logout
        
        self.monitor_status.setText("Stopped")
        self.monitor_status.setStyleSheet("font-weight: bold; color: gray;")
        
        self.log_message("Process monitoring stopped")
        self.status_bar.showMessage("Monitoring stopped")
        
    def collect_processes(self):
        """Collect and send process data to server"""
        try:
            processes = self.process_monitor.get_active_processes()
            self.count_value.setText(str(len(processes)))
            
            if not processes:
                self.log_message("No active processes found")
                return
                
            # Split processes into batches
            batches = [
                processes[i:i + self.max_batch_size] 
                for i in range(0, len(processes), self.max_batch_size)
            ]
            
            self.log_message(f"Collected {len(processes)} processes in {len(batches)} batches")
            
            sent_count = 0
            for i, batch in enumerate(batches):
                batch_data = self.process_monitor.prepare_batch(batch)
                success = self.api_client.send_batch(batch_data)
                
                if success:
                    sent_count += len(batch)
                else:
                    self.log_message(f"Failed to send batch {i+1}", error=True)
            
            if sent_count > 0:
                self.log_message(f"Successfully sent {sent_count} process records")
                
        except Exception as e:
            self.log_message(f"Error collecting processes: {str(e)}", error=True)
            
    def log_message(self, message, error=False):
        """Add a message to the log with timestamp"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        color = "red" if error else "black"
        
        self.log_output.append(
            f'<p style="margin: 0"><span style="color: gray">[{timestamp}]</span> '
            f'<span style="color: {color}">{message}</span></p>'
        )
        
        # Auto-scroll to bottom
        self.log_output.verticalScrollBar().setValue(
            self.log_output.verticalScrollBar().maximum()
        )
        
    def closeEvent(self, event):
        """Handle window close event"""
        if self.collection_timer.isActive():
            reply = QMessageBox.question(
                self, 
                'Confirm Exit',
                'Monitoring is still running. Do you want to stop and exit?',
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No, 
                QMessageBox.StandardButton.No
            )
            
            if reply == QMessageBox.StandardButton.Yes:
                self.stop_monitoring()
                event.accept()
            else:
                event.ignore()
        else:
            event.accept()

def main():
    if not check_qt_installation():
        return

    try:
        app = QApplication(sys.argv)
        
        # Set application style
        app.setStyle("Fusion")
        
        window = MainWindow()
        window.show()
        sys.exit(app.exec())

    except Exception as e:
        print("Error initializing application:")
        print(traceback.format_exc())
        return

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Fatal error: {str(e)}")
        print(traceback.format_exc())
