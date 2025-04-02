const express = require('express');
const path = require('path');
const app = express();
const port = 5000;

// Serve static files
app.use(express.static('public'));

// Serve the documentation page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`Salesforce FS Cloud documentation server running at http://0.0.0.0:${port}`);
});