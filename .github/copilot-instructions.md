# AI Agent Instructions for Household Staff Management App

## Project Overview
This is a household staff management application built with Flutter and HTML/CSS for web interface. The project consists of:
- A Flutter mobile app for staff management (`household_staff_app/`)
- A web interface prototype (`three_page_app_design.html`)

## Architecture

### Web Interface (`three_page_app_design.html`)
- Single-page application with three main views: Dashboard, Attendance, and Employee Management
- Uses vanilla JavaScript for state management and DOM manipulation
- Key components:
  - Header with navigation and time display
  - Dashboard with attendance stats and quick actions
  - Attendance tracking with time windows and date selection
  - Employee management with detailed profiles
  - Payment recording and monthly reporting

### Mobile App Structure (`household_staff_app/`)
```
lib/
  ├── models/          # Data models for staff, attendance, payments
  ├── screens/         # UI screens organized by feature
  ├── services/        # Business logic and data services  
  └── widgets/         # Reusable UI components
```

## Development Workflows

### Web Interface
- All styling is contained in a single `<style>` tag at the top of `three_page_app_design.html`
- JavaScript functions are organized by feature area in the `<script>` tag
- Modal dialogs are used for forms (payments, advances)
- Uses CSS Grid and Flexbox for responsive layouts

### Key Patterns
1. **State Management**:
   - Global variables track current page and form states
   - Functions prefixed with `show` handle modal visibility
   - Functions prefixed with `update` handle data changes

2. **Navigation**:
   - `switchPage(page)` handles main view transitions
   - `navigateToPage(page, title, subtitle)` updates header
   - Back button history managed via `pageHistory` array

3. **UI Components**:
   - Status badges for attendance (present/absent/pending)
   - Action cards for quick access to common tasks
   - Form validation with user feedback
   - Touch feedback animations for mobile interaction

## Testing and Debugging
- Console messages indicate app initialization status
- Keyboard shortcuts for navigation (1=Home, 2=Attendance, 3=Employees)
- Time window validation for attendance marking
- Form validation with user feedback messages

## Conventions
- BEM-style CSS class naming (e.g., `employee-card`, `employee-card__header`)
- JavaScript functions follow verb-noun naming (e.g., `showPaymentForm`, `updateAttendance`)
- Color scheme uses Material Design colors
- Responsive design breakpoint at 375px width
