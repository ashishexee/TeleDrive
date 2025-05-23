const TelegramBot = require('node-telegram-bot-api');
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;
require('dotenv').config();

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const bot = new TelegramBot(BOT_TOKEN, { polling: true });

const uploadsDir = path.join(__dirname, 'uploads');
const dataDir = path.join(__dirname, 'data');
const userFilesPath = path.join(dataDir, 'userFiles.json');
const sharp = require('sharp');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

const thumbnailsDir = path.join(__dirname, 'thumbnails');
if (!fs.existsSync(thumbnailsDir)) {
  fs.mkdirSync(thumbnailsDir);
}

if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir);
}

const verificationCodes = {};

let userFiles = {};

try {
  if (fs.existsSync(userFilesPath)) {
    const fileData = fs.readFileSync(userFilesPath, 'utf8');
    userFiles = JSON.parse(fileData);
    console.log(`Loaded file metadata for ${Object.keys(userFiles).length} users`);
  }
} catch (error) {
  console.error('Error loading saved file data:', error);
}

function saveUserFilesData() {
  try {
    fs.writeFileSync(userFilesPath, JSON.stringify(userFiles, null, 2));
    console.log('File metadata saved successfully');
  } catch (error) {
    console.error('Error saving file metadata:', error);
  }
}

app.use(express.json({ limit: '2000mb' }));
app.use(express.urlencoded({ extended: true, limit: '2000mb' }));

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 2000 * 1024 * 1024 
  }
});

app.use(cors());

function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

bot.onText(/\/start (.+)/, async (msg, match) => {
  const telegramId = msg.from.id;
  const username = msg.from.username;
  const startParam = match[1];

  console.log(`User started the bot: ${telegramId}, username: @${username}`);

  const verificationCode = generateVerificationCode();
  
  verificationCodes[verificationCode] = {
    telegramId: String(telegramId),
    username: username || 'Unknown',
    createdAt: Date.now()
  };
  
  setTimeout(() => {
    if (verificationCodes[verificationCode]) {
      delete verificationCodes[verificationCode];
    }
  }, 10 * 60 * 1000);

  bot.sendMessage(telegramId, 
    `Your verification code is: *${verificationCode}*\n\nEnter this code in the app to complete your authentication.`, 
    { parse_mode: 'Markdown' }
  );
});

app.post('/api/verify', (req, res) => {
  const { code } = req.body;
  
  if (!code || !verificationCodes[code]) {
    return res.status(400).json({ 
      success: false, 
      message: 'Invalid or expired verification code' 
    });
  }
  
  const userData = verificationCodes[code];
  
  if (Date.now() - userData.createdAt > 10 * 60 * 1000) {
    delete verificationCodes[code];
    return res.status(400).json({ 
      success: false, 
      message: 'Verification code has expired' 
    });
  }
  
  if (!userFiles[userData.telegramId]) {
    userFiles[userData.telegramId] = [];
  }
  
  const response = {
    success: true,
    telegramId: userData.telegramId,
    username: userData.username
  };
  
  delete verificationCodes[code];
  
  res.json(response);
});

app.post('/api/upload', upload.single('file'), async (req, res) => {
  try {
    const { telegramId } = req.body;
    const file = req.file;
    
    console.log(`Uploading file: ${file.originalname}, size: ${file.size}, type: ${file.mimetype}`);
    
    const isAudio = file.mimetype.startsWith('audio/');
    
    if (isAudio) {
      console.log('Processing audio file');
    }
    
    if (!file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }
    
    const filePath = req.file.path;
    const fileName = req.body.filename || req.file.originalname;
    const fileSize = req.file.size;
    
    if (!telegramId) {
      fs.unlinkSync(filePath);
      return res.status(400).json({ success: false, message: 'Telegram ID is required' });
    }

    try {
      const sentFile = await bot.sendDocument(telegramId, filePath, {
        caption: `📁 File uploaded from TeleDrive: ${fileName}`
      });

      const fileId = sentFile.document ? sentFile.document.file_id : null;
      
      if (!fileId) {
        return res.status(500).json({ success: false, message: 'Failed to get file ID from Telegram' });
      }

      const fileMetadata = {
        id: fileId,
        name: fileName,
        size: fileSize,
        uploadDate: new Date().toISOString(),
        telegramMessageId: sentFile.message_id
      };
      
      if (!userFiles[telegramId]) {
        userFiles[telegramId] = [];
      }
      
      userFiles[telegramId].push(fileMetadata);
      
      saveUserFilesData();
      
      fs.unlinkSync(filePath);
      
      res.json({ success: true, fileId, message: 'File uploaded successfully' });
      
    } catch (error) {
      console.error('Upload error:', error);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
      res.status(500).json({ success: false, message: `Upload failed: ${error.message}` });
    }
  } catch (error) {
    console.error('Upload error details:', error);
    return res.status(500).json({ 
      success: false, 
      message: `Error uploading file: ${error.message}` 
    });
  }
});

app.get('/api/files', (req, res) => {
  const { telegramId } = req.query;
  if (!telegramId) {
    return res.status(400).json({ success: false, message: 'Telegram ID is required' });
  }

  try {
    if (!userFiles[telegramId]) {
      userFiles[telegramId] = [];
      return res.json({ success: true, files: [] });
    }

    const activeFiles = userFiles[telegramId].filter(file => !file.isDeleted);
    
    res.json({ success: true, files: activeFiles });
  } catch (error) {
    console.error('Error getting files:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

app.get('/api/download/:fileId', async (req, res) => {
  const { fileId } = req.params;
  const { telegramId } = req.query;
  
  if (!telegramId || !fileId) {
    return res.status(400).json({ 
      success: false, 
      message: 'Telegram ID and file ID are required' 
    });
  }
  
  try {
    const userFileList = userFiles[telegramId] || [];
    const fileMetadata = userFileList.find(file => file.id === fileId);
    
    if (!fileMetadata) {
      return res.status(404).json({ success: false, message: 'File not found' });
    }
    
    await bot.sendDocument(telegramId, fileId, {
      caption: `📥 Here's your requested file: ${fileMetadata.name}`
    });
    
    res.json({ 
      success: true, 
      message: 'File sent to your Telegram chat' 
    });
    
  } catch (error) {
    console.error('Download error:', error);
    res.status(500).json({ success: false, message: `Download failed: ${error.message}` });
  }
});

app.get('/api/file/:fileId', async (req, res) => {
  const { fileId } = req.params;
  const { telegramId } = req.query;
  
  if (!telegramId || !fileId) {
    return res.status(400).json({ 
      success: false, 
      message: 'Telegram ID and file ID are required' 
    });
  }
  
  try {
    const userFileList = userFiles[telegramId] || [];
    const fileMetadata = userFileList.find(file => file.id === fileId);
    
    if (!fileMetadata) {
      return res.status(404).json({ success: false, message: 'File not found' });
    }
    
    console.log(`Serving file: ${fileMetadata.name} (ID: ${fileId})`);
    
    const fileInfo = await bot.getFile(fileId);
    const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${fileInfo.file_path}`;
    
    const response = await fetch(fileUrl);
    
    if (!response.ok) {
      throw new Error(`Failed to fetch file: ${response.statusText}`);
    }
    
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Disposition', `attachment; filename="${fileMetadata.name}"`);
    
    const buffer = await response.arrayBuffer();
    res.end(Buffer.from(buffer));
    
  } catch (error) {
    console.error('File download error:', error);
    res.status(500).json({ success: false, message: `Download failed: ${error.message}` });
  }
});

app.get('/api/thumbnail/:fileId', async (req, res) => {
  const { fileId } = req.params;
  const { telegramId } = req.query;
  
  if (!telegramId || !fileId) {
    return res.status(400).json({ 
      success: false, 
      message: 'Telegram ID and file ID are required' 
    });
  }
  
  try {
    const userFileList = userFiles[telegramId] || [];
    const fileMetadata = userFileList.find(file => file.id === fileId);
    
    if (!fileMetadata) {
      return res.status(404).json({ success: false, message: 'File not found' });
    }
    
    // Check if file is an image based on name
    const fileExt = path.extname(fileMetadata.name).toLowerCase();
    const isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].includes(fileExt);
    
    if (!isImage) {
      return res.status(400).json({ success: false, message: 'Not an image file' });
    }
    
    const thumbnailPath = path.join(thumbnailsDir, `${fileId}_thumb${fileExt}`);
    
    if (fs.existsSync(thumbnailPath)) {
      console.log(`Serving cached thumbnail for: ${fileMetadata.name}`);
      res.sendFile(thumbnailPath);
      return;
    }
    
    console.log(`Generating thumbnail for: ${fileMetadata.name}`);
    
    const fileInfo = await bot.getFile(fileId);
    const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${fileInfo.file_path}`;
    
    const response = await fetch(fileUrl);
    
    if (!response.ok) {
      throw new Error(`Failed to fetch file: ${response.statusText}`);
    }
    
    const buffer = await response.arrayBuffer();
    const imageBuffer = Buffer.from(buffer);
    
    const thumbnail = await sharp(imageBuffer)
      .resize(300, 300, { fit: 'cover' })
      .toBuffer();
      
    fs.writeFileSync(thumbnailPath, thumbnail);
    
    let contentType = 'image/jpeg';
    switch (fileExt) {
      case '.png': contentType = 'image/png'; break;
      case '.gif': contentType = 'image/gif'; break;
      case '.webp': contentType = 'image/webp'; break;
      case '.bmp': contentType = 'image/bmp'; break;
    }
    
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache for 24 hours
    res.end(thumbnail);
    
  } catch (error) {
    console.error('Thumbnail generation error:', error);
    res.status(500).json({ success: false, message: `Thumbnail generation failed: ${error.message}` });
  }
});

setInterval(() => {
  try {
    const now = Date.now();
    fs.readdir(thumbnailsDir, (err, files) => {
      if (err) return;
      
      files.forEach(file => {
        const filePath = path.join(thumbnailsDir, file);
        fs.stat(filePath, (err, stats) => {
          if (err) return;
          
          if (now - stats.mtime.getTime() > 7 * 24 * 60 * 60 * 1000) {
            fs.unlink(filePath, () => {});
          }
        });
      });
    });
  } catch (err) {
    console.error('Error cleaning thumbnail cache:', err);
  }
}, 24 * 60 * 60 * 1000); 

setInterval(saveUserFilesData, 5 * 60 * 1000);

process.on('SIGINT', () => {
  console.log('Saving data before shutdown...');
  saveUserFilesData();
  process.exit(0);
});

app.delete('/api/file/:fileId', (req, res) => {
  const { fileId } = req.params;
  const { telegramId } = req.query;
  
  if (!telegramId || !fileId) {
    return res.status(400).json({ 
      success: false, 
      message: 'Telegram ID and file ID are required' 
    });
  }

  try {
    if (!userFiles[telegramId]) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }
    
    const fileIndex = userFiles[telegramId].findIndex(file => file.id === fileId);
    if (fileIndex === -1) {
      return res.status(404).json({ 
        success: false, 
        message: 'File not found' 
      });
    }
    
    userFiles[telegramId][fileIndex].isDeleted = true;
    userFiles[telegramId][fileIndex].deletedAt = new Date().toISOString();
    
    fs.writeFileSync(userFilesPath, JSON.stringify(userFiles, null, 2));
    
    return res.json({ 
      success: true, 
      message: 'File moved to recycle bin' 
    });
  } catch (error) {
    console.error('Error moving file to recycle bin:', error);
    res.status(500).json({ 
      success: false, 
      message: `Error: ${error.message}` 
    });
  }
});

app.get('/api/bin', (req, res) => {
  const { telegramId } = req.query;
  
  if (!telegramId) {
    return res.status(400).json({ 
      success: false, 
      message: 'Telegram ID is required' 
    });
  }

  try {
    if (!userFiles[telegramId]) {
      return res.json({ 
        success: true, 
        files: [] 
      });
    }
    
    const deletedFiles = userFiles[telegramId]
      .filter(file => file.isDeleted)
      .map(file => ({
        ...file,
        deletedAt: file.deletedAt || new Date().toISOString()
      }));
    
    return res.json({ 
      success: true, 
      files: deletedFiles 
    });
  } catch (error) {
    console.error('Error getting deleted files:', error);
    res.status(500).json({ 
      success: false, 
      message: `Error: ${error.message}` 
    });
  }
});

app.post('/api/bin/restore/:fileId', (req, res) => {
  const { fileId } = req.params;
  const { telegramId } = req.query;
  
  if (!telegramId || !fileId) {
    return res.status(400).json({ 
      success: false, 
      message: 'Telegram ID and file ID are required' 
    });
  }

  try {
    if (!userFiles[telegramId]) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }
    
    const fileIndex = userFiles[telegramId].findIndex(file => file.id === fileId);
    if (fileIndex === -1) {
      return res.status(404).json({ 
        success: false, 
        message: 'File not found' 
      });
    }
    
    // Unmark the file as deleted
    userFiles[telegramId][fileIndex].isDeleted = false;
    delete userFiles[telegramId][fileIndex].deletedAt;
    
    // Save updated user files data
    fs.writeFileSync(userFilesPath, JSON.stringify(userFiles, null, 2));
    
    return res.json({ 
      success: true, 
      message: 'File restored successfully' 
    });
  } catch (error) {
    console.error('Error restoring file:', error);
    res.status(500).json({ 
      success: false, 
      message: `Error: ${error.message}` 
    });
  }
});

app.delete('/api/bin/:fileId', (req, res) => {
  const { fileId } = req.params;
  const { telegramId } = req.query;
  
  if (!telegramId || !fileId) {
    return res.status(400).json({ 
      success: false, 
      message: 'Telegram ID and file ID are required' 
    });
  }

  try {
    if (!userFiles[telegramId]) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }
    
    const initialLength = userFiles[telegramId].length;
    userFiles[telegramId] = userFiles[telegramId].filter(file => file.id !== fileId);
    
    if (userFiles[telegramId].length === initialLength) {
      return res.status(404).json({ 
        success: false, 
        message: 'File not found' 
      });
    }
    
    fs.writeFileSync(userFilesPath, JSON.stringify(userFiles, null, 2));
    
    return res.json({ 
      success: true, 
      message: 'File permanently deleted' 
    });
  } catch (error) {
    console.error('Error permanently deleting file:', error);
    res.status(500).json({ 
      success: false, 
      message: `Error: ${error.message}` 
    });
  }
});

app.delete('/api/bin/empty', (req, res) => {
  const { telegramId } = req.query;
  
  if (!telegramId) {
    return res.status(400).json({ 
      success: false, 
      message: 'Telegram ID is required' 
    });
  }

  try {
    if (!userFiles[telegramId]) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }
    
    userFiles[telegramId] = userFiles[telegramId].filter(file => !file.isDeleted);
    
    fs.writeFileSync(userFilesPath, JSON.stringify(userFiles, null, 2));
    
    return res.json({ 
      success: true, 
      message: 'Recycle bin emptied successfully' 
    });
  } catch (error) {
    console.error('Error emptying bin:', error);
    res.status(500).json({ 
      success: false, 
      message: `Error: ${error.message}` 
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT} and accessible at http://localhost:${PORT}`);
});