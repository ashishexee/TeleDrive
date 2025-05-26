# 📦 TeleDrive Backend

A **Node.js backend server** that leverages **Telegram's API** for cloud storage functionality, allowing users to store and manage files using Telegram as the storage backend.

---

## 📜 Overview

This backend service acts as an intermediary between the TeleDrive frontend application and Telegram's API. It handles user authentication, file uploads, downloads, and management through a Telegram bot, effectively turning Telegram into a personal cloud storage solution.

---

## 🚀 Features

* **Telegram Authentication:** Secure login using Telegram's authentication system
* **File Management:** Upload, download, delete, and restore files
* **Recycle Bin:** Soft delete functionality with restore capability
* **Thumbnails:** Automatic thumbnail generation for image files
* **Direct Download:** Download files directly from Telegram to device
* **Category Support:** Special handling for various file types (images, documents, videos, audio)

---

## 🔧 Setup & Installation

### Prerequisites

* Node.js (v14+)
* NPM or Yarn
* Telegram Bot Token (from @BotFather)

### Installation Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/telegram_drive
   cd telegram_drive/backend
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Create a `.env` file in the project root with the following content:

   ```
   TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
   PORT=3000
   ```

4. Start the server:

   ```bash
   npm start
   ```

---

### 🔒 Environment Variables

| Variable             | Description                                      | Required |
| -------------------- | ------------------------------------------------ | -------- |
| TELEGRAM\_BOT\_TOKEN | Your Telegram bot token from BotFather           | Yes      |
| PORT                 | Port for the server to run on (defaults to 3000) | No       |

---

## 🌐 API Endpoints

### Authentication

* **POST** `/api/verify` - Verify the 6-digit code received from Telegram bot

### File Management

* **POST** `/api/upload` - Upload a file to Telegram
* **GET** `/api/files` - Get all files for a user
* **GET** `/api/file/:fileId` - Download a file directly
* **GET** `/api/download/:fileId` - Send a file to user's Telegram chat
* **DELETE** `/api/file/:fileId` - Move a file to the Recycle Bin

### Thumbnails

* **GET** `/api/thumbnail/:fileId` - Get thumbnail for an image file

### Recycle Bin

* **GET** `/api/bin` - List files in recycle bin
* **POST** `/api/bin/restore/:fileId` - Restore a file from recycle bin
* **DELETE** `/api/bin/:fileId` - Permanently delete a file
* **DELETE** `/api/bin/empty` - Empty the recycle bin

---

## 📂 Project Structure

```
backend/
├── server.js          # Main server file
├── uploads/           # Temporary storage for file uploads
├── data/
│   ├── userFiles.json # User file metadata storage
├── thumbnails/        # Cache directory for generated thumbnails
├── .env               # Environment variables
```

---

## 🔐 Security Features

* **Verification Code:** 6-digit time-limited verification code for authentication
* **File ID Validation:** Ensures users can only access their own files
* **Temporary File Storage:** Files are stored temporarily during processing
* **Error Handling:** Comprehensive error handling with appropriate status codes

---

## ⚡ Performance Optimizations

* **Thumbnail Caching:** Generated thumbnails are cached to reduce processing load
* **Scheduled Cleanup:** Automatic cleanup of old cached thumbnails
* **Periodic Data Saving:** Automatic saving of file metadata
* **Graceful Shutdown:** Ensures data is saved before server shutdown

---

## 🛠️ Troubleshooting

### Common Issues

#### ❌ `ECONNRESET` Errors

* Usually indicates network instability or Telegram API rate limiting.
* The server includes automatic reconnection logic.

#### 🔐 `ETELEGRAM: 401 Unauthorized` Error

* Verify that your Telegram bot token in the `.env` file is correct and active.
* Make sure the bot hasn't been banned or disabled.

#### 📦 File Size Limitations

* Default file size limit is 50MB.
* To increase, adjust the `fileSize` limit in the `multer` middleware configuration.

---

## 📦 Deployment

### Production Recommendations

1. Use a process manager like PM2:

   ```bash
   npm install -g pm2
   pm2 start server.js --name telegram-drive
   ```

2. Set up a reverse proxy (Nginx/Apache) for SSL termination

3. Configure appropriate firewall rules and monitor server logs

---

## 📘 License

MIT © \[ashishexee]
