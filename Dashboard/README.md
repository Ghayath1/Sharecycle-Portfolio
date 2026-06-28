# ShareCycle Admin Dashboard & Landing Page
This is a React-based frontend application for ShareCycle, a bicycle rental and sharing platform. The project provides two main interfaces:

A public-facing Landing Page to attract users and promote the app.

An authenticated Admin Dashboard for managing users, bicycles, orders, and viewing platform statistics.

This project is built with React, Vite, Material-UI (MUI), and React Router.

## Project Functionality
1. Public Landing Page
The landing page (/) is the public gateway to the platform. It is a static, multi-section page designed for marketing and user acquisition. Its features include:

- Hero Banner: Main promotional content.

- Mission & Vision: Describes the project's goals.

- About Us: Details about the ShareCycle service.

- App Installation: Promotes the mobile app with QR codes and store links.

- Contact Form: A form for user inquiries.

- Login: A link to the authentication page.

2. Admin Dashboard
The dashboard is a secure area for platform administrators, accessible after logging in.

Authentication:

- A dedicated Login Page (/login) validates admin credentials against the backend (/api/auth/login).
- On success, a JSON Web Token (JWT) is saved to localStorage and used for all subsequent API requests.
- The system checks the user's role; ADMIN roles are redirected to the /summary dashboard.

Core Dashboard Features:

- Summary (/summary): The main dashboard homepage. It displays key statistics via StatCards (Total Users, Orders, Bicycles, and Income), a LastOrdersTable, and a LastPaymentsTable.

- User Management (/users): Displays a UserTable listing all registered platform users, fetched from /api/user/all.

- Bicycle Management (/ads): Shows all bicycle listings as BikeCards.

- Bicycle Editor (/edit-ad/:id): A form (BikeEditForm) that allows admins to update a bicycle's details (name, price, location, image, etc.).

- Order Management (/orders): An OrderTable showing all orders placed on the platform.

- Order Editor (/view-order): A detailed form (OrderEditForm) for admins to review, modify rental dates, or cancel specific orders.

- Chat (/chat): A ChatLayout that lists all chat rooms and allows an admin to view messages between users.

- Admin Profile (/profile): Allows the logged-in admin to update their own profile information (username, email, photo) or delete their account.

3. Internationalization (i18n)
The application supports multiple languages (English and German) using react-i18next.

Text translations are stored in src/Language/en.json and src/Language/de.json.

A language toggle component is available in the navigation bar to switch languages dynamically.

## Getting Started
Prerequisites:
- Node.js (v18 or later)
- npm (v8 or later)
- A running instance of the ShareCycle Backend API. This frontend is configured to send all requests to http://localhost:8080.

## Installation & Setup
Clone the repository:
```Bash
git clone https://github.com/mostafa7000/dashboard-cycleshare.git
cd dashboard-cycleshare
``` 

Install dependencies:
```Bash
npm install
```

Run the development server:

```Bash
npm run dev
```
The application will be available at http://localhost:3000.


Available Scripts
`npm run dev`: Starts the Vite development server on port 3000.

`npm run build`: Bundles the application for production.

`npm run lint`: Runs ESLint to check for code quality and style issues.

`npm run preview`: Serves the production build locally.

Project Structure
The project follows a standard React application structure, separating concerns into components, pages, and layouts.

/
├── docs/
│   └── openapi.json         # API documentation for the backend
├── public/                  # Static assets
├── src/
│   ├── Component/           # Reusable React components (e.g., BikeCards, UserTable)
│   ├── Language/            # i18n configuration and translation files
│   ├── Routs/               # React Router configuration
│   ├── assets/              # Images, icons, and other static assets
│   ├── layouts/             # Layout components (e.g., MainLayout with admin navbar)
│   ├── pages/               # Top-level page components (e.g., HomePage, UserPage)
│   ├── App.jsx              # Root component, renders Routs
│   └── main.jsx             # Application entry point
├── .gitignore               # Files to ignore in Git
├── eslint.config.js         # ESLint configuration
├── index.html               # Main HTML template
├── package.json             # Project dependencies and scripts
└── vite.config.js           # Vite configuration

## Development Process
### Adding a New Dashboard Page
Create the Component(s): Build your primary UI logic as one or more components in src/Component/.

Use Material-UI (@mui/material) components for UI elements.

Use React hooks (useState, useEffect) for state management.

Fetch data from the http://localhost:8080 API using fetch, remembering to include the auth token:

```JavaScript
const token = localStorage.getItem('token');
const response = await fetch(`${BACKEND_URL}/api/endpoint`, {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```
Create the Page: Create a new page file in src/pages/YourPageName/Index.jsx. This file should import and assemble the components you created.

Add Translations: Add any new text labels to src/Language/en.json and src/Language/de.json. Use the useTranslation hook in your component:

```JavaScript
import { useTranslation } from 'react-i18next';
const { t } = useTranslation();
// ...
return <Typography>{t('your.translation.key')}</Typography>;
```
Add the Route: Open src/Routs/Routs.jsx. Import your new page and add a <Route> for it. To include the admin sidebar and navbar, add the route inside the MainLayout element:

```JavaScript
// src/Routs/Routs.jsx
import YourPageName from '../pages/YourPageName/Index';
// ...
<Route element={<MainLayout />}>
  {/* ... other routes */}
  <Route path="/your-new-path" element={<YourPageName />} />
</Route>
```
## API & Backend
This frontend is stateless and relies entirely on the backend API at http://localhost:8080.

Ensure the backend server is running before starting development.

A full OpenAPI 3.0 specification for the backend API is available in docs/openapi.json. Use this file to understand available endpoints, request bodies, and response schemas.