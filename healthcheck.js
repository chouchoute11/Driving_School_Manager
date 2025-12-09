const http = require('http');

const options = {
  hostname: 'localhost',
  port: 4000,
  path: '/health',
  timeout: 2000
};

const request = http.request(options, (response) => {
  if (response.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

request.on('error', () => {
  process.exit(1);
});

request.on('timeout', () => {
  request.destroy();
  process.exit(1);
});

request.end();
