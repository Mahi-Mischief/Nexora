const http = require('http');

function testSignup() {
  const postData = JSON.stringify({
    username: 'testuser123',
    email: 'testuser123@test.com',
    password: 'password123',
    role: 'student'
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/signup',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': postData.length
    }
  };

  const req = http.request(options, (res) => {
    console.log(`Signup Status: ${res.statusCode}`);
    let data = '';

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      console.log('Signup Response:', data);
      try {
        const parsed = JSON.parse(data);
        console.log('\nUser data:', parsed.user);
        console.log('Token:', parsed.token ? 'Present' : 'Missing');
        
        // Now test login
        if (parsed.token) {
          setTimeout(() => testLogin(), 1000);
        }
      } catch (e) {
        console.log('Could not parse JSON');
      }
    });
  });

  req.on('error', (e) => {
    console.error(`Problem with signup request: ${e.message}`);
  });

  req.write(postData);
  req.end();
}

function testLogin() {
  const postData = JSON.stringify({
    usernameOrEmail: 'testuser123',
    password: 'password123'
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': postData.length
    }
  };

  const req = http.request(options, (res) => {
    console.log(`\nLogin Status: ${res.statusCode}`);
    let data = '';

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      console.log('Login Response:', data);
      try {
        const parsed = JSON.parse(data);
        console.log('\nUser data:', parsed.user);
        console.log('Token:', parsed.token ? 'Present' : 'Missing');
      } catch (e) {
        console.log('Could not parse JSON');
      }
      process.exit(0);
    });
  });

  req.on('error', (e) => {
    console.error(`Problem with login request: ${e.message}`);
    process.exit(1);
  });

  req.write(postData);
  req.end();
}

testSignup();
