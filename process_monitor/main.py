import sys
import traceback
from datetime import datetime
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
                            QPushButton, QTextEdit, QLabel, QSpinBox, QStatusBar, 
                            QComboBox, QGroupBox, QProgressBar, QMessageBox)
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

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Process Activity Monitor")
        self.setMinimumSize(800, 600)
        
        # Initialize components
        self.process_monitor = ProcessMonitor()
        self.api_client = ApiClient("http://localhost:8081")
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
        user_label = QLabel("User ID:")
        self.user_spin = QSpinBox()
        self.user_spin.setRange(1, 999)
        self.user_spin.setValue(20)
        user_layout.addWidget(user_label)
        user_layout.addWidget(self.user_spin)
        
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
        
        # Connect button
        self.connect_button = QPushButton("Connect to Server")
        self.connect_button.clicked.connect(self.connect_to_server)
        control_layout.addWidget(self.connect_button)
        
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
        
    def connect_to_server(self):
        """Attempt to connect to the server"""
        server_url = self.server_combo.currentText()
        self.api_client = ApiClient(server_url)
        
        self.status_bar.showMessage("Connecting to server...")
        self.log_message(f"Connecting to {server_url}...")
        
        # Disable UI during connection attempt
        self.connect_button.setEnabled(False)
        self.connect_button.setText("Connecting...")
        
        # Try to connect and authenticate
        success = self.api_client.login("Naqi111", "123niqi123111.com")
        
        if success:
            self.update_connection_status("Connected")
            self.connect_button.setText("Reconnect")
            self.connect_button.setEnabled(True)
            self.start_button.setEnabled(True)
            self.log_message(f"Successfully connected to {server_url}")
            self.status_bar.showMessage("Connected to server")
        else:
            self.update_connection_status("Failed")
            self.connect_button.setText("Connect to Server")
            self.connect_button.setEnabled(True)
            self.start_button.setEnabled(False)
            self.log_message(f"Failed to connect to {server_url}", error=True)
            self.status_bar.showMessage("Connection failed")
            
            # Show error message
            QMessageBox.warning(
                self,
                "Connection Failed",
                "Could not connect to the server. Make sure the server is running and the URL is correct.",
                QMessageBox.StandardButton.Ok
            )
    
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
                    self.log_message("Authentication failed. Please reconnect.", error=True)
                    return
                
            self.process_monitor.set_user_id(self.user_spin.value())
            interval = self.interval_spin.value() * 1000  # Convert to milliseconds
            self.collection_timer.start(interval)
            
            self.start_button.setEnabled(False)
            self.stop_button.setEnabled(True)
            self.interval_spin.setEnabled(False)
            self.user_spin.setEnabled(False)
            
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
        self.user_spin.setEnabled(True)
        
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
