/**
 * Test Cloudinary Upload Integration
 * Run this script to test the Cloudinary configuration
 */

require('dotenv').config();
const cloudinary = require('./config/cloudinary');

async function testCloudinaryConnection() {
  console.log('\n🧪 Testing Cloudinary Integration...\n');
  
  // Test 1: Configuration
  console.log('1️⃣ Testing Configuration:');
  console.log('   Cloud Name:', process.env.CLOUDINARY_CLOUD_NAME || '❌ Not set');
  console.log('   API Key:', process.env.CLOUDINARY_API_KEY ? '✅ Set' : '❌ Not set');
  console.log('   API Secret:', process.env.CLOUDINARY_API_SECRET ? '✅ Set' : '❌ Not set');
  
  // Test 2: Connection
  console.log('\n2️⃣ Testing Connection:');
  try {
    const pingResult = await cloudinary.api.ping();
    console.log('   ✅ Connection successful!');
    console.log('   Status:', pingResult.status);
    console.log('   Rate limit:', `${pingResult.rate_limit_remaining}/${pingResult.rate_limit_allowed}`);
  } catch (error) {
    console.log('   ❌ Connection failed:', error.message);
    return;
  }
  
  // Test 3: Upload capability (using a sample image URL)
  console.log('\n3️⃣ Testing Upload (using sample image):');
  try {
    const testImageUrl = 'https://via.placeholder.com/300x200.png?text=Test+Image';
    const uploadResult = await cloudinary.uploader.upload(testImageUrl, {
      folder: 'social-stream/test',
      public_id: 'test_image_' + Date.now()
    });
    
    console.log('   ✅ Upload successful!');
    console.log('   URL:', uploadResult.secure_url);
    console.log('   Public ID:', uploadResult.public_id);
    console.log('   Format:', uploadResult.format);
    console.log('   Size:', (uploadResult.bytes / 1024).toFixed(2), 'KB');
    
    // Test 4: Delete the test image
    console.log('\n4️⃣ Testing Delete:');
    const deleteResult = await cloudinary.uploader.destroy(uploadResult.public_id);
    
    if (deleteResult.result === 'ok') {
      console.log('   ✅ Delete successful!');
    } else {
      console.log('   ⚠️  Delete returned:', deleteResult.result);
    }
    
  } catch (error) {
    console.log('   ❌ Upload/Delete test failed:', error.message);
  }
  
  console.log('\n✨ All tests completed!\n');
}

// Run tests
testCloudinaryConnection();
