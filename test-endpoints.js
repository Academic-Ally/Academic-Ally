// Simple test script for API endpoint discovery

const fetch = require('node-fetch');

// Define the endpoint and fallbacks
const API_ENDPOINTS = {
  primary: 'https://academicallyapp.netlify.app/.netlify/functions/chat/initiate',
  fallback1: 'https://academicallyapp.netlify.app/.netlify/functions/chat/message',
  netlify3: 'https://academicallyapp.netlify.app/.netlify/functions/chat',
};

// Test basic endpoint connectivity
async function testEndpoints() {
  console.log('Testing basic API endpoints...');
  
  const testRequest = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ 
      action: 'ping',
      timestamp: Date.now(),
      userId: '4FFPZFEqinOi7uj3FWkYEoiVrnr1'
    }),
  };
  
  for (const [key, endpoint] of Object.entries(API_ENDPOINTS)) {
    try {
      console.log(`\nTesting endpoint: ${endpoint}`);
      const response = await fetch(endpoint, testRequest);
      
      console.log(`Status: ${response.status}`);
      
      // Try to get response text
      const responseText = await response.text();
      console.log(`Response: ${responseText.substring(0, 200)}`);
      
      // If we get any response other than 404, consider it working
      if (response.status !== 404) {
        console.log(`✅ Endpoint ${endpoint} seems to be working (status ${response.status})`);
      } else {
        console.log(`❌ Endpoint ${endpoint} returned 404 Not Found`);
      }
    } catch (error) {
      console.log(`❌ Endpoint ${endpoint} test failed: ${error.message}`);
    }
  }
  
  console.log('\nBasic endpoint testing complete!');
}

// Test the document upload scenario
async function testDocumentUpload() {
  console.log('\nTesting document upload scenario...');
  
  const docId = "rKQxkLsKdDMdcoORENQz_9a5607dc-1b2f-4d77-bc36-965ebe320ad1";
  const userId = "4FFPZFEqinOi7uj3FWkYEoiVrnr1";
  
  const uploadRequest = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ 
      userId: userId,
      fileUrl: "https://link.storjshare.io/s/jvn6w5kdxgoqla5jw3umlrspv7zq/academic-ally/sample-url-for-test",
      documentId: docId,
      sourceId: "rKQxkLsKdDMdcoORENQz",
    }),
  };
  
  try {
    console.log(`\nTesting document upload to: ${API_ENDPOINTS.primary}`);
    const response = await fetch(API_ENDPOINTS.primary, uploadRequest);
    
    console.log(`Status: ${response.status}`);
    
    // Try to get response text
    const responseText = await response.text();
    console.log(`Response: ${responseText.substring(0, 200)}`);
    
    if (response.status !== 404) {
      console.log(`✅ Document upload endpoint seems to be working (status ${response.status})`);
    } else {
      console.log(`❌ Document upload endpoint returned 404 Not Found`);
    }
  } catch (error) {
    console.log(`❌ Document upload test failed: ${error.message}`);
  }
}

// Test the chat scenario
async function testChat() {
  console.log('\nTesting chat scenario...');
  
  const docId = "rKQxkLsKdDMdcoORENQz_9a5607dc-1b2f-4d77-bc36-965ebe320ad1";
  const userId = "4FFPZFEqinOi7uj3FWkYEoiVrnr1";
  
  const chatRequest = {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ 
      userId: userId,
      docId: docId,
      sourceId: "rKQxkLsKdDMdcoORENQz",
      date: new Date(),
      message: "Hello, can you summarize this document?"
    }),
  };
  
  try {
    console.log(`\nTesting chat with: ${API_ENDPOINTS.fallback1}`);
    const response = await fetch(API_ENDPOINTS.fallback1, chatRequest);
    
    console.log(`Status: ${response.status}`);
    
    // Try to get response text
    const responseText = await response.text();
    console.log(`Response: ${responseText.substring(0, 200)}`);
    
    if (response.status !== 404) {
      console.log(`✅ Chat endpoint seems to be working (status ${response.status})`);
    } else {
      console.log(`❌ Chat endpoint returned 404 Not Found`);
    }
  } catch (error) {
    console.log(`❌ Chat test failed: ${error.message}`);
  }
}

// Run all tests
async function runAllTests() {
  await testEndpoints();
  await testDocumentUpload();
  await testChat();
  console.log('\nAll testing complete!');
}

runAllTests().catch(error => {
  console.error('Error in test:', error);
}); 