# Telegram Drive

A cloud storage application that leverages Telegram's infrastructure for file storage and management.

## Tech Stack

### Frontend
- **Flutter**: Cross-platform UI framework for building natively compiled applications
- Responsive design for mobile and desktop platforms
- Clean architecture implementation

### Backend
- **Node.js**: JavaScript runtime environment
- **Express**: Web application framework for Node.js
- RESTful API design for communication with frontend

## Features

### User Authentication
- Secure login and registration
- JWT token-based authentication
- Password recovery options
- OAuth integration with Telegram

### File Management
- Upload files directly to Telegram's servers
- Organize files into folders and categories
- File preview for images, documents, and media
- Advanced search functionality

### Sharing & Collaboration
- Share files with other users
- Public and private file sharing options
- Generate shareable links with expiration dates
- Manage permissions for shared files

### Synchronization
- Automatic file synchronization across devices
- Offline access to downloaded files
- Background synchronization
- Bandwidth optimization

### Security
- End-to-end encryption for sensitive files
- Two-factor authentication
- Encrypted storage of user credentials
- Auto-logout for inactive sessions

### Analytics & Storage Management
- Storage usage statistics
- File access history
- Storage quota management
- Activity reports and notifications

## Installation

### Frontend Setup
```bash
# Clone the repository
git clone https://github.com/username/telegram_drive.git

# Navigate to the frontend directory
cd telegram_drive/frontend

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### Backend Setup
```bash
# Navigate to the backend directory
cd telegram_drive/backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env

# Run the server
npm start
```

## Project Structure

### Frontend
```
frontend/
├── lib/
│   ├── core/         # Core functionality, constants, theme
│   ├── data/         # Data layer, repositories, models
│   ├── presentation/ # UI components, screens, widgets
│   ├── services/     # Services for API calls, storage
│   └── main.dart     # Entry point
├── assets/           # Static assets like images
└── test/             # Unit and widget tests
```

### Backend
```
backend/
├── controllers/      # Request handlers
├── models/           # Data models
├── routes/           # API endpoints
├── middleware/       # Custom middleware
├── services/         # Business logic
├── util/             # Utility functions
└── server.js         # Entry point
```

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.