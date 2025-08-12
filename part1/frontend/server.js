const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const app = express();

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// Backend URL from environment variable or default
const BACKEND_URL = process.env.BACKEND_URL || 'http://backend-service:5000';

app.get('/', (req, res) => {
  res.send(`
    <form method="POST" action="/submit">
      <input name="name" placeholder="Enter your name" />
      <input name="age" placeholder="Enter your age" />
      <button type="submit">Submit</button>
    </form>
  `);
});

app.post('/submit', async (req, res) => {
  const { name, age } = req.body;
  try {
    const response = await axios.post(`${BACKEND_URL}/submit`, { name, age });
    res.send(response.data);
  } catch (error) {
    console.error('Error connecting to backend:', error.message);
    res.status(500).send("Error connecting to backend.");
  }
});

// Use environment PORT or default 3000
const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', () => {
  console.log(`Frontend listening on port ${port}`);
});
