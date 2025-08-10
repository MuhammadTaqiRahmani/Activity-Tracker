using System.Windows.Forms;
using ProcessCollector.WindowsApp.Services;
using Newtonsoft.Json;

namespace ProcessCollector.WindowsApp
{
    public partial class MainForm : Form
    {
        private readonly ProcessMonitorService _monitorService;
        private readonly Timer _collectionTimer;
        private bool _isMonitoring;
        
        // UI Controls
        private RichTextBox _logBox;
        private Button _startButton;
        private Button _stopButton;
        private Label _statusLabel;
        private TextBox _userIdBox;
        private NumericUpDown _intervalBox;

        public MainForm()
        {
            InitializeComponent();
            SetupUI();
            
            _monitorService = new ProcessMonitorService("http://localhost:8081");
            _collectionTimer = new Timer();
            _collectionTimer.Tick += CollectionTimer_Tick;
        }

        private void SetupUI()
        {
            // Form settings
            this.Text = "Process Activity Monitor";
            this.Size = new Size(800, 600);
            this.MinimumSize = new Size(600, 400);

            // Create layout panel
            var panel = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 1,
                RowCount = 3
            };

            // Settings panel
            var settingsPanel = new FlowLayoutPanel { Dock = DockStyle.Top };
            
            // User ID input
            settingsPanel.Controls.Add(new Label { Text = "User ID:" });
            _userIdBox = new TextBox { Text = "20", Width = 50 };
            settingsPanel.Controls.Add(_userIdBox);

            // Interval input
            settingsPanel.Controls.Add(new Label { Text = "Interval (seconds):" });
            _intervalBox = new NumericUpDown 
            { 
                Value = 60,
                Minimum = 30,
                Maximum = 300,
                Width = 60
            };
            settingsPanel.Controls.Add(_intervalBox);

            // Control buttons
            _startButton = new Button
            {
                Text = "Start Monitoring",
                Width = 120
            };
            _startButton.Click += StartButton_Click;
            settingsPanel.Controls.Add(_startButton);

            _stopButton = new Button
            {
                Text = "Stop Monitoring",
                Width = 120,
                Enabled = false
            };
            _stopButton.Click += StopButton_Click;
            settingsPanel.Controls.Add(_stopButton);

            // Status label
            _statusLabel = new Label
            {
                Text = "Status: Stopped",
                Dock = DockStyle.Fill
            };
            settingsPanel.Controls.Add(_statusLabel);

            // Log box
            _logBox = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.Black,
                ForeColor = Color.Lime,
                Font = new Font("Consolas", 10)
            };

            // Add controls to panel
            panel.Controls.Add(settingsPanel);
            panel.Controls.Add(_logBox);
            this.Controls.Add(panel);
        }

        private async void StartButton_Click(object sender, EventArgs e)
        {
            try
            {
                if (!long.TryParse(_userIdBox.Text, out long userId))
                {
                    MessageBox.Show("Please enter a valid User ID", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                await _monitorService.Initialize(userId);
                _collectionTimer.Interval = (int)_intervalBox.Value * 1000;
                _collectionTimer.Start();
                
                _isMonitoring = true;
                _startButton.Enabled = false;
                _stopButton.Enabled = true;
                _statusLabel.Text = "Status: Running";
                
                LogMessage("Process monitoring started");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error starting monitor: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void StopButton_Click(object sender, EventArgs e)
        {
            _collectionTimer.Stop();
            _isMonitoring = false;
            _startButton.Enabled = true;
            _stopButton.Enabled = false;
            _statusLabel.Text = "Status: Stopped";
            LogMessage("Process monitoring stopped");
        }

        private async void CollectionTimer_Tick(object sender, EventArgs e)
        {
            try
            {
                var result = await _monitorService.CollectAndSendProcesses();
                LogMessage($"Sent {result.ProcessCount} processes in {result.BatchCount} batches");
            }
            catch (Exception ex)
            {
                LogMessage($"Error: {ex.Message}", true);
            }
        }

        private void LogMessage(string message, bool isError = false)
        {
            if (_logBox.InvokeRequired)
            {
                _logBox.Invoke(new Action(() => LogMessage(message, isError)));
                return;
            }

            string timestamp = DateTime.Now.ToString("HH:mm:ss");
            string logEntry = $"[{timestamp}] {message}{Environment.NewLine}";

            _logBox.SelectionStart = _logBox.TextLength;
            _logBox.SelectionLength = 0;
            _logBox.SelectionColor = isError ? Color.Red : Color.Lime;
            _logBox.AppendText(logEntry);
            _logBox.ScrollToCaret();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (_isMonitoring)
            {
                var result = MessageBox.Show(
                    "Process monitoring is still running. Do you want to stop and exit?",
                    "Confirm Exit",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question
                );

                if (result == DialogResult.No)
                {
                    e.Cancel = true;
                    return;
                }
            }

            _collectionTimer.Stop();
            base.OnFormClosing(e);
        }
    }
}
