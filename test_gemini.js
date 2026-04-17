const https = require('https');
const data = JSON.stringify({"contents":[{"parts":[{"text":"Hello"}]}]});
const options = {
  hostname: 'generativelanguage.googleapis.com',
  path: '/v1beta/models/gemini-2.5-flash:generateContent?key=REDACTED_KEY',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};
const req = https.request(options, res => {
  let resData = '';
  res.on('data', d => resData += d);
  res.on('end', () => console.log(res.statusCode, resData));
});
req.on('error', e => console.error(e));
req.write(data);
req.end();
