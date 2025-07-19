# Household Staff Management App - Development Plan

## Overview
This plan outlines the step-by-step development process for the Household Staff Management App, following a story-by-story approach. Each story will be developed, demoed, and only then will the team move to the next story. The plan is based on the requirements, user stories, and technical specifications provided.

---

## Story-by-Story Development Plan

### Story #1: Project Setup & Basic Navigation (P0)
**Goal:** Set up the Flutter project, implement tab navigation, and ensure the app runs on both iOS and Android with a basic folder structure and SQLite integration.

**Tasks:**
- [ ] Initialize Flutter project (`flutter create household_staff_app`)
- [ ] Set up recommended folder structure (`lib/screens/`, `lib/models/`, `lib/services/`, etc.)
- [ ] Add dependencies: `sqflite`, `path`, `intl`
- [ ] Implement bottom tab navigation with 5 tabs (Home, Attendance, Employees, Reports, Settings)
- [ ] Each tab shows a placeholder screen
- [ ] Configure SQLite database connection (testable)
- [ ] Ensure the app builds and runs on both platforms
- [ ] Demo: Show navigation and database connection

---

### Story #2: Database Schema & Models (P0)
**Goal:** Implement the database schema and data models for Employee, Attendance, and Payment.

**Tasks:**
- [ ] Create model classes for Employee, Attendance, Payment
- [ ] Implement SQLite table creation scripts
- [ ] Build database helper/service class for CRUD operations
- [ ] Add data validation logic
- [ ] Test database initialization and migrations
- [ ] Demo: Show model classes and database CRUD

---

### Story #3: Employee Registration Form (P0)
**Goal:** Build the UI and logic for registering new employees.

**Tasks:**
- [ ] Create employee registration form with all required fields and validation
- [ ] Save employee data to the database
- [ ] Handle duplicate names and validation errors
- [ ] UI feedback for success/failure
- [ ] Navigation back to employee list after save
- [ ] Demo: Register a new employee and show data saved

---

### Story #4: Employee List View (P0)
**Goal:** Display a list of all registered employees with basic info and navigation to details.

**Tasks:**
- [ ] Implement employee list screen
- [ ] Show employee name, visits per day, and status
- [ ] Add "New Employee" button
- [ ] Handle empty state and search/filter
- [ ] Navigation to employee detail view
- [ ] Demo: Show employee list and navigation

---

### Story #5: Employee Detail & Edit (P1)
**Goal:** Allow viewing and editing of employee details.

**Tasks:**
- [ ] Implement employee detail screen
- [ ] Add edit functionality for employee data
- [ ] Save changes to database
- [ ] Demo: Edit employee and show updates

---

### Story #6: Daily Attendance Management (P1)
**Goal:** Enable marking and viewing daily attendance for all staff.

**Tasks:**
- [ ] Implement attendance marking UI and logic
- [ ] Handle single and twice-daily staff logic
- [ ] Visual indicators for attendance status
- [ ] Store attendance in database
- [ ] Demo: Mark attendance and show status

---

### Story #7: Attendance Correction & History (P1)
**Goal:** Allow correction of past attendance entries within the allowed window.

**Tasks:**
- [ ] Implement attendance correction logic (2-day window)
- [ ] UI for correcting past entries
- [ ] Visual indication of corrected entries
- [ ] Demo: Correct attendance and show history

---

### Story #8: Financial Management (P1)
**Goal:** Track payments, advances, and salary for employees.

**Tasks:**
- [ ] Implement payment entry UI and logic
- [ ] Track advances and salary payments
- [ ] Calculate outstanding salary
- [ ] Demo: Record and view payments

---

### Story #9: Historical Data & Reporting (P1)
**Goal:** Provide reports on attendance and payments.

**Tasks:**
- [ ] Implement attendance and payment history screens
- [ ] Add filters and export options
- [ ] Show summary statistics and charts
- [ ] Demo: Generate and export reports

---

### Story #10+: Future Enhancements (P2/P3)
- Data export/import
- Analytics and insights
- Notifications
- Multiple household support
- Photo capture for attendance

---

## Process
- Complete one story at a time
- Demo after each story
- Move to next story only after demo and acceptance

---

## Notes
- All development will follow the offline-first, local storage, and cross-platform principles outlined in the requirements.
- The plan will be updated as new requirements or feedback arise. 