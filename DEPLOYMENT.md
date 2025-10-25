# Deployment Guide - GitHub Actions to Shared Hosting

This guide explains how to deploy both the Flutter frontend and Laravel backend to shared hosting using GitHub Actions.

## Overview

The deployment pipeline automatically:
1. **Builds** the Flutter web frontend
2. **Prepares** the Laravel backend with optimizations
3. **Deploys** both to your shared hosting via FTP/SFTP
4. **Runs** database migrations
5. **Notifies** you of the deployment status

The deployment is triggered automatically when code is merged to the `main` or `master` branch.

## Prerequisites

### Shared Hosting Requirements

Your shared hosting should have:
- **PHP 8.2+** (for Laravel backend)
- **MySQL 8.0+** database
- **FTP/SFTP access**
- **Composer** (optional, dependencies are pre-installed during deployment)
- **Two separate directories**:
  - One for the frontend (e.g., `public_html/` or `www/`)
  - One for the backend (e.g., `api/` or `backend/`)

### GitHub Repository Setup

1. **Fork or clone** this repository
2. **Enable GitHub Actions** in your repository settings
3. **Set up GitHub Secrets** (see below)

## Step 1: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secrets:

### FTP/SFTP Credentials

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `FTP_SERVER` | Your FTP/SFTP server address | `ftp.yourdomain.com` |
| `FTP_USERNAME` | FTP/SFTP username | `your-ftp-user` |
| `FTP_PASSWORD` | FTP/SFTP password | `your-secure-password` |
| `FTP_FRONTEND_DIR` | Frontend directory on server (must end with `/`) | `/public_html/` or `/www/` |
| `FTP_BACKEND_DIR` | Backend directory on server (must end with `/`) | `/api/` or `/backend/` |

### Laravel Backend Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `LARAVEL_APP_KEY` | Laravel application key | `base64:random-32-char-string` |
| `DB_HOST` | Database host | `localhost` or `127.0.0.1` |
| `DB_PORT` | Database port | `3306` |
| `DB_DATABASE` | Database name | `tessie_db` |
| `DB_USERNAME` | Database username | `db_user` |
| `DB_PASSWORD` | Database password | `db_password` |

### Generating Laravel App Key

Run this command locally in your backend directory:
```bash
cd backend
php artisan key:generate --show
```

Copy the output (e.g., `base64:xyz...`) and add it as `LARAVEL_APP_KEY` secret.

## Step 2: Prepare Your Shared Hosting

### Create Directory Structure

On your shared hosting, create two directories:

```
/
├── public_html/          # Frontend (Flutter web)
│   └── (will contain index.html, assets/, etc.)
└── api/                  # Backend (Laravel)
    ├── app/
    ├── bootstrap/
    ├── config/
    ├── database/
    ├── public/
    ├── routes/
    ├── storage/
    └── vendor/
```

### Set Permissions

Ensure the following directories are writable (755 or 775):
```bash
chmod -R 755 api/storage
chmod -R 755 api/bootstrap/cache
```

### Configure Database

1. **Create a MySQL database** via cPanel or hosting control panel
2. **Create a database user** with all privileges
3. **Note down** the credentials for GitHub Secrets

### Configure Web Server

#### For Frontend (public_html/)

Create `.htaccess` file:
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

#### For Backend (api/)

Point your subdomain (e.g., `api.yourdomain.com`) to the `api/public` directory.

Create `.htaccess` in `api/public/`:
```apache
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
```

## Step 3: Deploy

### Automatic Deployment

The pipeline automatically runs when you:
1. **Merge** a pull request to `main` or `master`
2. **Push** directly to `main` or `master`

### Manual Deployment

You can also trigger deployment manually:
1. Go to **Actions** tab in GitHub
2. Select **Deploy to Shared Hosting** workflow
3. Click **Run workflow**
4. Select the branch
5. Click **Run workflow** button

## Step 4: Verify Deployment

### Check GitHub Actions

1. Go to **Actions** tab in your repository
2. Click on the latest workflow run
3. Verify all jobs completed successfully:
   - ✅ Build and Deploy Frontend
   - ✅ Build and Deploy Backend
   - ✅ Run Database Migrations
   - ✅ Notify Deployment Status

### Check Frontend

Visit your website: `https://yourdomain.com`

You should see the Flutter app running in an iPhone frame.

### Check Backend

Visit your API health endpoint: `https://api.yourdomain.com/api/v1/health`

You should see:
```json
{
  "status": "ok",
  "message": "Tessie Backend API is running"
}
```

### Check Database

SSH into your server (if available) or use phpMyAdmin:
```bash
mysql -u db_user -p db_name -e "SHOW TABLES;"
```

You should see:
- `charging_sessions`
- `face_enrollments`
- `face_auth_sessions`
- `migrations`

## Troubleshooting

### Deployment Fails - FTP Connection

**Problem:** FTP connection timeout or authentication failed

**Solutions:**
1. Verify FTP credentials in GitHub Secrets
2. Check if FTP server allows connections from GitHub Actions IPs
3. Try using SFTP instead by updating the workflow:
   ```yaml
   protocol: sftp
   port: 22
   ```

### Laravel App Key Missing

**Problem:** "No application encryption key has been specified"

**Solutions:**
1. Generate a new app key:
   ```bash
   php artisan key:generate --show
   ```
2. Add it to GitHub Secrets as `LARAVEL_APP_KEY`

### Database Connection Failed

**Problem:** Backend can't connect to database

**Solutions:**
1. Verify database credentials in GitHub Secrets
2. Check if database host is correct (`localhost` vs IP)
3. Ensure database user has proper privileges
4. Check if your hosting allows remote connections

### Frontend Shows 404 Errors

**Problem:** Flutter routes not working

**Solutions:**
1. Ensure `.htaccess` is uploaded to frontend directory
2. Verify mod_rewrite is enabled on server
3. Check file permissions (644 for files, 755 for directories)

### Backend Shows 500 Error

**Problem:** Laravel returns 500 Internal Server Error

**Solutions:**
1. Check storage directory permissions:
   ```bash
   chmod -R 755 storage bootstrap/cache
   ```
2. Clear caches:
   ```bash
   php artisan cache:clear
   php artisan config:clear
   php artisan route:clear
   ```
3. Check error logs in `storage/logs/laravel.log`

### Migrations Failed

**Problem:** Database migrations don't run

**Solutions:**
1. Run migrations manually via SSH:
   ```bash
   cd api
   php artisan migrate --force
   ```
2. Check database credentials
3. Ensure migrations table exists

## Advanced Configuration

### Using SFTP Instead of FTP

Update `.github/workflows/deploy.yml`:

```yaml
- name: Deploy Frontend to Shared Hosting
  uses: SamKirkland/FTP-Deploy-Action@v4.3.5
  with:
    server: ${{ secrets.FTP_SERVER }}
    username: ${{ secrets.FTP_USERNAME }}
    password: ${{ secrets.FTP_PASSWORD }}
    protocol: sftp
    port: 22
    local-dir: ./build/web/
    server-dir: ${{ secrets.FTP_FRONTEND_DIR }}
```

### Custom Build Options

Modify the Flutter build command in the workflow:

```yaml
# Use HTML renderer instead of CanvasKit (smaller size)
- name: Build Flutter Web
  run: flutter build web --release --web-renderer html

# Or use auto renderer
- name: Build Flutter Web
  run: flutter build web --release --web-renderer auto
```

### Environment-Specific Deployments

Create separate workflows for staging and production:

1. Create `.github/workflows/deploy-staging.yml`
2. Use different secrets for staging
3. Deploy to different directories

### Notifications

Add Slack/Discord notifications:

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

## Security Best Practices

1. **Never commit** `.env` files with real credentials
2. **Use strong passwords** for FTP and database
3. **Enable HTTPS** on your domain (Let's Encrypt)
4. **Restrict database** access to localhost only
5. **Use SSH keys** instead of passwords for SFTP (if supported)
6. **Regularly update** dependencies and PHP version
7. **Enable firewall** rules on your server
8. **Backup database** regularly

## Monitoring

### Set Up Health Checks

Use services like:
- **UptimeRobot** - Free monitoring
- **Pingdom** - Advanced monitoring
- **StatusCake** - Website monitoring

Monitor these endpoints:
- `https://yourdomain.com` (Frontend)
- `https://api.yourdomain.com/api/v1/health` (Backend)

### Log Monitoring

Check Laravel logs regularly:
- Location: `api/storage/logs/laravel.log`
- Set up log rotation
- Consider using external logging (Papertrail, Loggly)

## Cost Estimate

### GitHub Actions Usage

- **Free tier**: 2,000 minutes/month for private repos
- **Estimated usage**: ~5-10 minutes per deployment
- **Monthly deployments**: 200-400 deployments free

### Shared Hosting

Typical costs:
- **Basic shared hosting**: $3-10/month
- **Includes**: PHP, MySQL, FTP, domain
- **Examples**: Hostinger, Bluehost, SiteGround

## Support

### Documentation

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Laravel Deployment](https://laravel.com/docs/deployment)

### Getting Help

1. Check workflow logs in GitHub Actions tab
2. Review server error logs
3. Test locally before deploying
4. Open an issue in the repository

## Summary

✅ **Automated deployment** on merge to main branch
✅ **Builds and optimizes** both frontend and backend
✅ **Deploys via FTP/SFTP** to shared hosting
✅ **Runs database migrations** automatically
✅ **Production-ready** configuration
✅ **Easy to configure** with GitHub Secrets

---

**Need help?** Check the troubleshooting section or open an issue!
