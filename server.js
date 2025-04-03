const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = process.env.PORT || 5000;

// Function to determine content type based on file extension
const getContentType = (filePath) => {
  const extname = path.extname(filePath).toLowerCase();
  const contentTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'text/javascript',
    '.json': 'application/json',
    '.svg': 'image/svg+xml',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif'
  };
  
  return contentTypes[extname] || 'text/plain';
};

// Create an HTTP server
const server = http.createServer((req, res) => {
  // Normalize URL (remove query parameters and normalize slashes)
  let url = req.url.split('?')[0];
  
  // Handle root URL
  if (url === '/') {
    url = '/index.html';
  }
  
  // Construct the file path
  const filePath = path.join(__dirname, 'docs', url);
  
  // Check if the file exists
  fs.access(filePath, fs.constants.F_OK, (err) => {
    if (err) {
      // If file doesn't exist, return 404
      res.writeHead(404, { 'Content-Type': 'text/html' });
      res.end('404 Not Found');
      return;
    }
    
    // Read the file
    fs.readFile(filePath, (err, content) => {
      if (err) {
        // If error reading the file, return 500
        res.writeHead(500, { 'Content-Type': 'text/html' });
        res.end('500 Internal Server Error');
        return;
      }
      
      // Set the content type based on file extension
      res.writeHead(200, { 'Content-Type': getContentType(filePath) });
      res.end(content);
    });
  });
});

// Start the server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`FS Cloud Documentation server is running on port ${PORT}`);
  console.log(`Open http://localhost:${PORT} to view the documentation`);
});