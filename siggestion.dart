<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Attendance Page Design</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
            padding: 20px;
        }

        .phone-container {
            max-width: 375px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
            overflow: hidden;
        }

        .app-header {
            background: linear-gradient(135deg, #2196F3, #1976D2);
            color: white;
            padding: 20px;
            text-align: center;
        }

        .app-header h1 {
            font-size: 20px;
            margin-bottom: 5px;
        }

        .current-time {
            font-size: 14px;
            opacity: 0.9;
        }

        .time-window-indicator {
            background: rgba(255,255,255,0.2);
            padding: 8px 12px;
            border-radius: 15px;
            margin-top: 10px;
            font-size: 12px;
            display: inline-block;
        }

        .content {
            padding: 20px;
            max-height: 600px;
            overflow-y: auto;
        }

        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e0e0e0;
        }

        .section-title {
            font-size: 18px;
            font-weight: bold;
            color: #333;
        }

        .employee-count {
            background: #2196F3;
            color: white;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
        }

        .employee-card {
            background: white;
            border: 1px solid #e0e0e0;
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .employee-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
        }

        .employee-info {
            flex: 1;
        }

        .employee-name {
            font-size: 16px;
            font-weight: bold;
            color: #333;
            margin-bottom: 4px;
        }

        .employee-role {
            font-size: 12px;
            color: #666;
            background: #f0f0f0;
            padding: 2px 8px;
            border-radius: 8px;
            display: inline-block;
        }

        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-left: 10px;
        }

        .status-present { background: #4CAF50; }
        .status-absent { background: #f44336; }
        .status-pending { background: #FF9800; }
        .status-off { background: #9E9E9E; }

        .attendance-controls {
            display: flex;
            gap: 8px;
            margin-bottom: 10px;
        }

        .shift-container {
            flex: 1;
            background: #f8f9fa;
            border-radius: 8px;
            padding: 12px;
        }

        .shift-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }

        .shift-label {
            font-size: 12px;
            font-weight: bold;
            color: #666;
        }

        .shift-time {
            font-size: 10px;
            color: #999;
        }

        .attendance-buttons {
            display: flex;
            gap: 6px;
        }

        .btn {
            padding: 8px 12px;
            border: none;
            border-radius: 6px;
            font-size: 12px;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.2s;
        }

        .btn-present {
            background: #4CAF50;
            color: white;
        }

        .btn-absent {
            background: #f44336;
            color: white;
        }

        .btn-disabled {
            background: #e0e0e0;
            color: #999;
            cursor: not-allowed;
        }

        .btn-selected {
            transform: scale(0.95);
            box-shadow: inset 0 2px 4px rgba(0,0,0,0.2);
        }

        .time-input-row {
            display: flex;
            gap: 8px;
            margin-top: 8px;
            align-items: center;
        }

        .time-input {
            flex: 1;
            padding: 6px 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 12px;
        }

        .comments-section {
            margin-top: 10px;
        }

        .comments-input {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 12px;
            resize: none;
            min-height: 40px;
        }

        .off-day-card {
            background: #f5f5f5;
            border: 1px dashed #ccc;
            opacity: 0.7;
        }

        .off-day-label {
            text-align: center;
            color: #666;
            font-style: italic;
            padding: 20px;
        }

        .disabled-time {
            background: #f0f0f0;
            color: #999;
        }

        .summary-bar {
            background: #e3f2fd;
            padding: 12px 16px;
            margin: -20px -20px 20px -20px;
            border-bottom: 1px solid #bbdefb;
        }

        .summary-stats {
            display: flex;
            justify-content: space-around;
            font-size: 12px;
        }

        .stat-item {
            text-align: center;
        }

        .stat-number {
            font-size: 18px;
            font-weight: bold;
            color: #1976D2;
        }

        .stat-label {
            color: #666;
            margin-top: 2px;
        }

        .fab {
            position: fixed;
            bottom: 80px;
            right: 20px;
            width: 56px;
            height: 56px;
            background: #2196F3;
            border-radius: 50%;
            border: none;
            color: white;
            font-size: 24px;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(33, 150, 243, 0.4);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .correction-badge {
            background: #FF9800;
            color: white;
            padding: 2px 6px;
            border-radius: 8px;
            font-size: 10px;
            margin-left: 8px;
        }

        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }

        .btn-present.btn-selected {
            animation: pulse 1s;
        }
    </style>
</head>
<body>
    <div class="phone-container">
        <!-- Header -->
        <div class="app-header">
            <h1>Attendance</h1>
            <div class="current-time">Today, July 19, 2025 - 10:30 AM</div>
            <div class="time-window-indicator">Morning Window Active (until 11:50 AM)</div>
        </div>

        <!-- Content -->
        <div class="content">
            <!-- Summary Stats -->
            <div class="summary-bar">
                <div class="summary-stats">
                    <div class="stat-item">
                        <div class="stat-number">5</div>
                        <div class="stat-label">Total Staff</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number">2</div>
                        <div class="stat-label">Present</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number">1</div>
                        <div class="stat-label">Absent</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-number">2</div>
                        <div class="stat-label">Pending</div>
                    </div>
                </div>
            </div>

            <!-- Single Visit Employees -->
            <div class="section-header">
                <h2 class="section-title">Daily Staff</h2>
                <span class="employee-count">3</span>
            </div>

            <!-- Employee 1 - Present -->
            <div class="employee-card">
                <div class="employee-header">
                    <div class="employee-info">
                        <div class="employee-name">Priya Sharma</div>
                        <div class="employee-role">Daily • House Cleaning</div>
                    </div>
                    <div class="status-indicator status-present"></div>
                </div>
                
                <div class="attendance-controls">
                    <div class="shift-container">
                        <div class="shift-header">
                            <span class="shift-label">Today's Attendance</span>
                        </div>
                        <div class="attendance-buttons">
                            <button class="btn btn-present btn-selected">Present</button>
                            <button class="btn btn-absent">Absent</button>
                        </div>
                        <div class="time-input-row">
                            <input type="time" class="time-input" value="09:30" placeholder="Check-in">
                            <input type="time" class="time-input" value="17:00" placeholder="Check-out">
                        </div>
                    </div>
                </div>
                
                <div class="comments-section">
                    <textarea class="comments-input" placeholder="Optional comments...">Completed all tasks on time</textarea>
                </div>
            </div>

            <!-- Employee 2 - Absent -->
            <div class="employee-card">
                <div class="employee-header">
                    <div class="employee-info">
                        <div class="employee-name">Ravi Kumar</div>
                        <div class="employee-role">Daily • Gardening</div>
                    </div>
                    <div class="status-indicator status-absent"></div>
                </div>
                
                <div class="attendance-controls">
                    <div class="shift-container">
                        <div class="shift-header">
                            <span class="shift-label">Today's Attendance</span>
                        </div>
                        <div class="attendance-buttons">
                            <button class="btn btn-present">Present</button>
                            <button class="btn btn-absent btn-selected">Absent</button>
                        </div>
                        <div class="time-input-row">
                            <input type="time" class="time-input disabled-time" disabled placeholder="Check-in">
                            <input type="time" class="time-input disabled-time" disabled placeholder="Check-out">
                        </div>
                    </div>
                </div>
                
                <div class="comments-section">
                    <textarea class="comments-input" placeholder="Optional comments...">Called in sick</textarea>
                </div>
            </div>

            <!-- Employee 3 - Off Day -->
            <div class="employee-card off-day-card">
                <div class="employee-header">
                    <div class="employee-info">
                        <div class="employee-name">Sunita Devi</div>
                        <div class="employee-role">Daily • Cooking</div>
                    </div>
                    <div class="status-indicator status-off"></div>
                </div>
                <div class="off-day-label">
                    📅 Off Day (Sunday)
                </div>
            </div>

            <!-- Twice Daily Employees -->
            <div class="section-header">
                <h2 class="section-title">Twice Daily Staff</h2>
                <span class="employee-count">2</span>
            </div>

            <!-- Employee 4 - Twice Daily -->
            <div class="employee-card">
                <div class="employee-header">
                    <div class="employee-info">
                        <div class="employee-name">Amit Singh</div>
                        <div class="employee-role">Twice Daily • Driver</div>
                    </div>
                    <div class="status-indicator status-present"></div>
                </div>
                
                <div class="attendance-controls">
                    <!-- Morning Shift -->
                    <div class="shift-container">
                        <div class="shift-header">
                            <span class="shift-label">Morning</span>
                            <span class="shift-time">7:00-11:50 AM</span>
                        </div>
                        <div class="attendance-buttons">
                            <button class="btn btn-present btn-selected">Present</button>
                            <button class="btn btn-absent">Absent</button>
                        </div>
                        <div class="time-input-row">
                            <input type="time" class="time-input" value="08:00" placeholder="Check-in">
                            <input type="time" class="time-input" value="11:30" placeholder="Check-out">
                        </div>
                    </div>
                    
                    <!-- Evening Shift -->
                    <div class="shift-container">
                        <div class="shift-header">
                            <span class="shift-label">Evening</span>
                            <span class="shift-time">3:00-8:00 PM</span>
                        </div>
                        <div class="attendance-buttons">
                            <button class="btn btn-disabled" disabled>Present</button>
                            <button class="btn btn-disabled" disabled>Absent</button>
                        </div>
                        <div class="time-input-row">
                            <input type="time" class="time-input disabled-time" disabled placeholder="Check-in">
                            <input type="time" class="time-input disabled-time" disabled placeholder="Check-out">
                        </div>
                    </div>
                </div>
                
                <div class="comments-section">
                    <textarea class="comments-input" placeholder="Optional comments...">Picked up groceries</textarea>
                </div>
            </div>

            <!-- Employee 5 - Twice Daily with Correction -->
            <div class="employee-card">
                <div class="employee-header">
                    <div class="employee-info">
                        <div class="employee-name">Maya Patel</div>
                        <div class="employee-role">Twice Daily • Child Care</div>
                        <span class="correction-badge">Corrected</span>
                    </div>
                    <div class="status-indicator status-pending"></div>
                </div>
                
                <div class="attendance-controls">
                    <!-- Morning Shift -->
                    <div class="shift-container">
                        <div class="shift-header">
                            <span class="shift-label">Morning</span>
                            <span class="shift-time">7:00-11:50 AM</span>
                        </div>
                        <div class="attendance-buttons">
                            <button class="btn btn-present">Present</button>
                            <button class="btn btn-absent">Absent</button>
                        </div>
                        <div class="time-input-row">
                            <input type="time" class="time-input" placeholder="Check-in">
                            <input type="time" class="time-input" placeholder="Check-out">
                        </div>
                    </div>
                    
                    <!-- Evening Shift -->
                    <div class="shift-container">
                        <div class="shift-header">
                            <span class="shift-label">Evening</span>
                            <span class="shift-time">3:00-8:00 PM</span>
                        </div>
                        <div class="attendance-buttons">
                            <button class="btn btn-disabled" disabled>Present</button>
                            <button class="btn btn-disabled" disabled>Absent</button>
                        </div>
                        <div class="time-input-row">
                            <input type="time" class="time-input disabled-time" disabled placeholder="Check-in">
                            <input type="time" class="time-input disabled-time" disabled placeholder="Check-out">
                        </div>
                    </div>
                </div>
                
                <div class="comments-section">
                    <textarea class="comments-input" placeholder="Optional comments..."></textarea>
                </div>
            </div>
        </div>

        <!-- Floating Action Button -->
        <button class="fab" title="View History">📅</button>
    </div>

    <script>
        // Simulate time-based UI updates
        function updateTimeWindow() {
            const now = new Date();
            const hour = now.getHours();
            const minute = now.getMinutes();
            
            const timeIndicator = document.querySelector('.time-window-indicator');
            
            if (hour < 11 || (hour === 11 && minute <= 50)) {
                timeIndicator.textContent = `Morning Window Active (until 11:50 AM)`;
                timeIndicator.style.background = 'rgba(76, 175, 80, 0.3)';
            } else if (hour >= 15) {
                timeIndicator.textContent = `Evening Window Active (until 8:00 PM)`;
                timeIndicator.style.background = 'rgba(255, 152, 0, 0.3)';
            } else {
                timeIndicator.textContent = `Transition Period (3:00 PM for evening)`;
                timeIndicator.style.background = 'rgba(244, 67, 54, 0.3)';
            }
        }

        // Add button click handlers
        document.querySelectorAll('.btn').forEach(btn => {
            btn.addEventListener('click', function() {
                if (this.disabled) return;
                
                // Remove selected class from siblings
                const siblings = this.parentElement.querySelectorAll('.btn');
                siblings.forEach(sib => sib.classList.remove('btn-selected'));
                
                // Add selected class to clicked button
                this.classList.add('btn-selected');
                
                // Enable/disable time inputs based on selection
                const timeInputs = this.closest('.shift-container').querySelectorAll('.time-input');
                if (this.textContent === 'Present') {
                    timeInputs.forEach(input => {
                        input.disabled = false;
                        input.classList.remove('disabled-time');
                    });
                } else {
                    timeInputs.forEach(input => {
                        input.disabled = true;
                        input.classList.add('disabled-time');
                        input.value = '';
                    });
                }
                
                // Update status indicator
                const statusIndicator = this.closest('.employee-card').querySelector('.status-indicator');
                if (this.textContent === 'Present') {
                    statusIndicator.className = 'status-indicator status-present';
                } else {
                    statusIndicator.className = 'status-indicator status-absent';
                }
            });
        });

        // Initialize time window
        updateTimeWindow();
        
        // Update time window every minute
        setInterval(updateTimeWindow, 60000);
    </script>
</body>
</html>