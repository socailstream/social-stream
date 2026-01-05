# Environment Variables Setup

Copy the following to your `.env` file and fill in your values.

## Required Environment Variables

```env
# ===========================================
# Social Stream Backend Environment Variables
# ===========================================

# Server Configuration
NODE_ENV=development
PORT=5000
BASE_URL=http://localhost:5000
CLIENT_URL=http://localhost:3000

# ===========================================
# MongoDB Configuration
# ===========================================
MONGODB_URI=mongodb://localhost:27017/social-stream

# ===========================================
# Firebase Configuration
# ===========================================
# Path to Firebase service account key JSON file
FIREBASE_CREDENTIALS_PATH=./config/serviceAccountKey.json

# ===========================================
# Facebook/Meta Configuration
# ===========================================
# Get these from: https://developers.facebook.com/apps/
FB_APP_ID=your_facebook_app_id
FB_APP_SECRET=your_facebook_app_secret
FB_REDIRECT_URI=http://localhost:5000/api/social/facebook/callback

# ===========================================
# Pinterest Configuration  
# ===========================================
# Get these from: https://developers.pinterest.com/apps/
PINTEREST_CLIENT_ID=your_pinterest_client_id
PINTEREST_CLIENT_SECRET=your_pinterest_client_secret
PINTEREST_REDIRECT_URI=http://localhost:5000/api/social/pinterest/callback

# ===========================================
# Storage Configuration
# ===========================================
# Options: 'firestore' or 'mongodb'
SOCIAL_STORAGE=mongodb
```

## Getting API Credentials

### Facebook/Instagram

1. Go to [Facebook Developers](https://developers.facebook.com/apps/)
2. Create a new app or select existing app
3. Go to **Settings > Basic**
   - Copy **App ID** → `FB_APP_ID` 
   - Copy **App Secret** → `FB_APP_SECRET`

4. **Setup Facebook Login Product:**
   - Click **Add Product** and select **Facebook Login**
   - Go to **Facebook Login > Settings**
   - Add to **Valid OAuth Redirect URIs**:
     - For local dev: `http://localhost:5000/api/social/facebook/callback`
     - For production: `https://yourdomain.com/api/social/facebook/callback`
   - Click **Save Changes**

5. **Important:** Make sure your BASE_URL environment variable matches the redirect URI you configured

**Facebook Permissions Setup:**

*For Development/Testing (no App Review needed):*
- `public_profile` - Basic user profile
- `pages_show_list` - List pages user manages

*For Production (requires Facebook App Review):*
- `pages_read_engagement` - Read page insights
- `pages_manage_posts` - Post to Facebook pages
- `instagram_basic` - Instagram profile access
- `instagram_content_publish` - Post to Instagram

**Important Notes:**
- Your Facebook App must be in **Development Mode** to test with your account
- Add your Facebook account as a **Test User** or **Developer** in the app settings
- For production, you must submit your app for **App Review** to use advanced permissions
- Switch app to **Live Mode** only after permissions are approved
- Some permissions may be deprecated or renamed by Facebook over time

### Pinterest

1. Go to [Pinterest Developers](https://developers.pinterest.com/apps/)
2. Create a new app
3. Copy **App ID** → `PINTEREST_CLIENT_ID`
4. Copy **App Secret** → `PINTEREST_CLIENT_SECRET`
5. Add your callback URL in OAuth settings

**Required Pinterest Scopes:**
- `boards:read`
- `boards:write`
- `pins:read`
- `pins:write`
- `user_accounts:read`

## Production Setup

For production, update these values:

```env
NODE_ENV=production
BASE_URL=https://yourdomain.com
FB_REDIRECT_URI=https://yourdomain.com/api/social/facebook/callback
PINTEREST_REDIRECT_URI=https://yourdomain.com/api/social/pinterest/callback
```

