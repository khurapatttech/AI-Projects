# Household Staff Management App - Requirements Specification

## 1. Project Overview

### 1.1 Purpose
A lightweight mobile application for iOS and Android to manage household staff attendance, payments, and scheduling without requiring backend services or APIs.

### 1.2 Key Principles
- Offline-first architecture with local data storage only
- Simple, intuitive user interface for daily operations
- Flexible scheduling to accommodate different staff patterns

## 2. User Stories & Functional Requirements

### 2.1 Employee Registration & Management

**As a user, I want to register new employees so that I can track their attendance and payments.**

#### Requirements:
- **Employee Profile Creation**
  - Name (required, text field)
  - Age (required, numeric field)
  - Contact details (phone number, optional email)
  - Monthly salary (required, numeric field with currency)
  
- **Work Schedule Configuration**
  - Number of daily visits (1 or 2 times per day)
  - For twice-daily staff: Morning and evening shift definitions
  - Weekly off days selection (flexible per employee)
  - Special cases handling (e.g., driver's Monday off instead of weekend)

- **Payment Tracking Setup**
  - Monthly salary baseline
  - Advance payment tracking capability
  - Payment history maintenance

### 2.2 Daily Attendance Management

**As a user, I want to mark daily attendance for all staff members so that I can track their work patterns.**

#### Requirements:
- **Main Dashboard**
  - Display all registered employees
  - Show today's attendance status for each employee
  - Quick access to mark attendance
  - Visual indicators for attended/not attended/partial attendance

- **Attendance Marking Logic**
  - Single visit employees: One attendance mark per day
  - Twice-daily employees:
    - Morning attendance: Available until 11:50 AM
    - Evening attendance: Available after 3:00 PM
  - Automatic disabling of attendance options based on time
  - Weekend/off-day handling per employee configuration

- **Attendance Details**
  - Check-in time (optional)
  - Check-out time (optional)
  - Daily comments (optional, text field)
  - Attendance status (Present/Absent/Half-day)

### 2.3 Attendance Correction & History

**As a user, I want to correct past attendance entries so that I can maintain accurate records.**

#### Requirements:
- **Correction Window**
  - 2-day correction period from the date attendance was marked
  - After 2 days, attendance becomes immutable
  - Timer starts from marking date, not actual attendance date

- **Past Entry Updates**
  - Access to previous days' attendance if not initially marked
  - Bulk update capability for missed entries
  - Clear visual indication of corrected entries

### 2.4 Financial Management

**As a user, I want to track all payments made to employees so that I can manage my household budget.**

#### Requirements:
- **Payment Recording**
  - Advance payment entries with date and amount
  - Monthly salary payment tracking
  - Payment method selection (cash/bank transfer/other)
  - Payment notes/comments

- **Financial Overview**
  - Total payments made per employee per month
  - Outstanding salary calculations
  - Advance payment deductions from monthly salary

### 2.5 Historical Data & Reporting

**As a user, I want to view historical data so that I can analyze attendance patterns and payment history.**

#### Requirements:
- **Attendance History**
  - Monthly attendance view per employee
  - Daily attendance details with comments
  - Attendance percentage calculations
  - Filter by date range and employee

- **Payment History**
  - Monthly payment summaries
  - Detailed payment transaction list
  - Year-to-date payment totals
  - Export capability (CSV/PDF)

## 3. Technical Requirements

### 3.1 Platform Support
- iOS (minimum version to be determined based on target audience)
- Android (minimum API level to be determined)
- Cross-platform development framework (React Native/Flutter recommended)

### 3.2 Data Storage
- **Local Storage Only**
  - SQLite database for structured data
  - No cloud synchronization
  - No external API dependencies
  - Data backup to device storage

### 3.3 Performance Requirements
- Lightweight application (< 50MB)
- Fast startup time (< 3 seconds)
- Smooth navigation between screens
- Efficient local data queries

### 3.4 Data Security
- Local data encryption
- App-level PIN/biometric protection (optional)
- Secure storage of sensitive information

## 4. User Interface Requirements

### 4.1 Navigation Structure
- **Tab-based navigation**
  - Home/Dashboard tab
  - Attendance tab
  - Employees tab
  - Reports/History tab
  - Settings tab

### 4.2 Screen Specifications

#### 4.2.1 Dashboard Screen
- Employee cards showing today's status
- Quick attendance marking buttons
- Summary statistics (present/absent counts)
- Navigation to detailed views

#### 4.2.2 Attendance Screen
- Daily attendance view
- Time-sensitive attendance options
- Comment addition interface
- Past entry correction access

#### 4.2.3 Employee Management Screen
- Employee list with basic info
- Add/Edit employee functionality
- Employee detail view with full profile
- Payment history per employee

#### 4.2.4 Reports Screen
- Monthly attendance reports
- Payment summaries
- Graphical representations (charts/graphs)
- Export functionality

## 5. Data Models

### 5.1 Employee Entity
```
- id (unique identifier)
- name (string)
- age (integer)
- phone (string)
- email (string, optional)
- monthly_salary (decimal)
- visits_per_day (1 or 2)
- off_days (array of day names)
- created_date (timestamp)
- active_status (boolean)
```

### 5.2 Attendance Entity
```
- id (unique identifier)
- employee_id (foreign key)
- date (date)
- shift_type (morning/evening/full_day)
- status (present/absent/half_day)
- check_in_time (time, optional)
- check_out_time (time, optional)
- comments (text, optional)
- marked_date (timestamp)
- is_corrected (boolean)
```

### 5.3 Payment Entity
```
- id (unique identifier)
- employee_id (foreign key)
- amount (decimal)
- payment_type (salary/advance)
- payment_date (date)
- payment_method (cash/transfer/other)
- notes (text, optional)
- created_date (timestamp)
```

## 6. Business Rules

### 6.1 Attendance Rules
- Attendance cannot be marked for future dates
- Morning attendance window: Start of day until 11:50 AM
- Evening attendance window: 3:00 PM until end of day
- Off-day attendance marking is disabled
- Correction window: 2 days from marking date

### 6.2 Payment Rules
- Advance payments are deducted from monthly salary
- Monthly salary is pro-rated based on attendance
- Payment history must be maintained for audit purposes

### 6.3 Data Integrity Rules
- Employee names must be unique
- Attendance records cannot be duplicated for same employee/date/shift
- All financial calculations must be accurate to 2 decimal places

## 7. Future Enhancement Considerations
- Data export/import functionality
- Basic analytics and insights
- Notification/reminder system
- Multiple household support
- Photo capture for attendance verification

## 8. Acceptance Criteria Summary
- Successfully register and manage up to 10+ employees
- Mark attendance for different shift patterns accurately
- Correct past attendance within defined timeframe
- Track all payment transactions
- Generate monthly reports
- Maintain data locally without external dependencies
- Support both iOS and Android platforms
- Maintain responsive UI across different screen sizes