const express = require('express');
const bodyParser = require('body-parser');
const net = require('net');

const app = express();

// Add CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

app.use(bodyParser.json()); // now expect JSON object from app

const ROBOT_IP = '192.168.4.1';
const ROBOT_PORT = 100;

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

app.post('/execute-sequence', async (req, res) => {
  const sequence = req.body?.data;
  console.log('Received sequence:', sequence);

  if (!Array.isArray(sequence)) {
    return res.status(400).send({ error: 'Payload must be an array of commands' });
  }

  const client = new net.Socket();
  let responseBuffer = '';

  client.connect(ROBOT_PORT, ROBOT_IP, async () => {
    console.log('Connected to robot. Executing sequence...');

    for (let i = 0; i < sequence.length; i++) {
      const step = sequence[i];
      const payload = JSON.stringify(step);

      console.log(`Sending step ${i + 1}/${sequence.length}:`, payload);
      client.write(payload);

      await sleep(step.T + 20|| 500);
    }

    console.log('Sequence complete, closing connection.');
    client.destroy();
    res.send({ status: 'Sequence completed' });
  });

  client.on('data', (data) => {
    responseBuffer += data.toString();
  });

  client.on('error', (err) => {
    console.error('TCP Error:', err.message);
    res.status(500).send({ error: err.message });
  });

  client.on('close', () => {
    console.log('Socket closed');
  });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
