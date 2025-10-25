# Web Deployment Guide

## Overview
This Flutter app has been configured to run on web with a phone frame preview. The web version displays the mobile app inside an iPhone mockup for demo purposes, using mock data only.

## Features
- ✅ iPhone 13 Pro Max frame using `device_frame` package
- ✅ Simple landing page with header and footer
- ✅ Mock data mode (always enabled on web)
- ✅ Platform-specific handling for biometric auth (disabled on web)
- ✅ Responsive design

## Building for Web

### Prerequisites
- Flutter SDK (latest stable)
- Web browser (Chrome, Firefox, Safari, or Edge)

### Build Commands

#### Development Build (with debugging)
```bash
flutter run -d chrome
```

#### Production Build
```bash
flutter build web --release
```

The built files will be in the `build/web/` directory.

### Build Options

#### Choose Web Renderer
Flutter offers two web renderers:

1. **CanvasKit** (default, better performance, larger download):
```bash
flutter build web --web-renderer canvaskit --release
```

2. **HTML** (smaller download, better for simple UIs):
```bash
flutter build web --web-renderer html --release
```

3. **Auto** (Flutter chooses based on browser):
```bash
flutter build web --web-renderer auto --release
```

## Deployment to Shared Hosting

### Step 1: Build the App
```bash
flutter build web --release
```

### Step 2: Upload Files
Upload the entire contents of `build/web/` to your hosting provider:

- index.html
- main.dart.js
- flutter.js
- assets/
- canvaskit/ (if using CanvasKit renderer)
- icons/
- manifest.json
- favicon.png

### Step 3: Configure Server

#### Apache (.htaccess)
Create a `.htaccess` file in the web root:

```apache
# Enable GZIP compression
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/x-javascript application/json
</IfModule>

# Set caching headers
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType text/html "access plus 0 seconds"
  ExpiresByType text/css "access plus 1 week"
  ExpiresByType application/javascript "access plus 1 week"
  ExpiresByType image/png "access plus 1 month"
  ExpiresByType image/jpeg "access plus 1 month"
</IfModule>

# Handle Flutter routing
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^(.*)$ /index.html [L]
</IfModule>
```

#### Nginx (nginx.conf)
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/build/web;
    index index.html;

    # GZIP compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Handle Flutter routing
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Popular Hosting Options

#### 1. **Netlify** (Recommended)
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd build/web
netlify deploy --prod
```

Or drag and drop the `build/web` folder in the Netlify UI.

#### 2. **Vercel**
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd build/web
vercel --prod
```

#### 3. **Firebase Hosting**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init hosting

# Deploy
firebase deploy --only hosting
```

#### 4. **GitHub Pages**
```bash
# Build
flutter build web --release --base-href "/your-repo-name/"

# Copy to docs/ or gh-pages branch
cp -r build/web/* docs/

# Commit and push
git add docs/
git commit -m "Deploy to GitHub Pages"
git push
```

Then enable GitHub Pages in repository settings pointing to `docs/` folder.

#### 5. **Traditional Shared Hosting** (cPanel, etc.)
1. Build: `flutter build web --release`
2. Use FTP/SFTP client (FileZilla, Cyberduck)
3. Upload contents of `build/web/` to `public_html/` or `www/`
4. Ensure `.htaccess` is configured (see above)

## Environment Variables

The web version doesn't require `.env` configuration as it uses mock data. If you want to customize:

- Create a `.env` file in the project root (optional)
- Set `BACKEND_API_URL` if you have a backend (not used in demo mode)

## Testing Locally

### Python Simple Server
```bash
cd build/web
python -m http.server 8000
```
Visit: http://localhost:8000

### PHP Built-in Server
```bash
cd build/web
php -S localhost:8000
```
Visit: http://localhost:8000

## Platform-Specific Notes

### Mock Data
- The web version **always** uses mock data
- Charging statistics are generated randomly
- No real Tesla API calls are made
- This is intentional for security and demo purposes

### Biometric Authentication
- Biometric/Face ID is **not available** on web
- The app handles this gracefully
- Users can still use email/password login

### Limitations
- No vehicle control (safety feature for web demo)
- Mock charging data only
- No real-time vehicle updates

## Troubleshooting

### Issue: Blank white screen
- Check browser console for errors
- Ensure all files uploaded correctly
- Verify CORS headers if loading assets from CDN

### Issue: Assets not loading
- Check that `assets/` folder uploaded completely
- Verify base href in index.html matches deployment path

### Issue: Routing doesn't work
- Configure server to redirect all routes to index.html
- See Apache/Nginx config above

## Security Notes

- No API keys are stored in web build
- All vehicle operations are mock/simulated
- User data stored in browser localStorage only
- HTTPS recommended for production deployment

## Performance Tips

1. Use CanvasKit renderer for better graphics
2. Enable GZIP compression on server
3. Set proper cache headers for static assets
4. Consider CDN for global distribution
5. Minify and optimize images

## Support

For issues or questions:
- Check Flutter web docs: https://docs.flutter.dev/platform-integration/web
- Review device_frame package: https://pub.dev/packages/device_frame
