# Atlassian Marketplace Scraper

A Python-based service to scrape the Atlassian Marketplace for Server/Data Center apps and versions, download binaries, scrape full plugin descriptions, build search indices, and provide a web interface for browsing the collected data.

**Current Branch:** The `stable` branch contains the stable release. The `master` branch contains the latest features including Whoosh full-text search, Playwright description scraping, and enhanced UI.

## Features

- **Complete Marketplace Scraping**: Scrapes all apps across Jira, Confluence, Bitbucket, Bamboo, and Crowd
- **Dual API System**: Uses both Marketplace API v2 and v3 for comprehensive data collection
- **Version Filtering**: Filters versions by date (default: last 365 days), Server/Data Center hosting only
- **Binary Downloads**: Downloads JAR/OBR files with resume capability and concurrent downloads
- **Plugin Descriptions**: Downloads complete marketplace pages with Playwright (HTML, CSS, images, videos)
- **Full-Text Search**: Whoosh-based search across plugin descriptions and release notes
- **Web Interface**: Flask-based UI with REST API for browsing apps and versions
- **Checkpoint/Resume**: Robust checkpoint system for interrupted scraping operations
- **Concurrent Processing**: Multi-threaded version scraping and downloads with configurable workers
- **Metadata Storage**: SQLite database with WAL mode for concurrent access
- **Multi-Drive Support**: Distribute storage across multiple drives (per-product configuration)
- **Encrypted Credentials**: Optional encrypted credential storage with multiple account support
- **Management Interface**: Admin panel for managing tasks and viewing statistics

## Architecture

```
AtlassianMarketplaceScraper/
├── app.py                         # Flask web application
├── run_scraper.py                 # CLI: Scrape apps from marketplace
├── run_version_scraper.py         # CLI: Scrape version history
├── run_downloader.py              # CLI: Download binaries
├── run_description_downloader.py  # CLI: Scrape plugin descriptions with Playwright
├── run_index_search.py            # CLI: Build Whoosh search index
├── run_reindex.py                 # CLI: Sync storage metadata with filesystem
├── run_smoke_tests.py             # CLI: Run system smoke tests
├── config/                        # Configuration and product definitions
├── scraper/                       # Core scraping logic
│   ├── marketplace_api.py         # API v2 client (app discovery, versions)
│   ├── marketplace_api_v3.py      # API v3 client (compatibility data)
│   ├── app_scraper.py             # App discovery engine
│   ├── version_scraper.py         # Version fetching with dual API
│   ├── download_manager.py        # Binary download manager
│   ├── metadata_store_sqlite.py   # SQLite storage backend
│   └── filters.py                 # Date/hosting filters
├── models/                        # Data models (App, Version)
├── utils/                         # Utilities (logger, rate limiter, checkpoint, auth)
├── web/                           # Flask web interface
│   ├── routes.py                  # HTTP routes and API endpoints
│   ├── search_index_whoosh.py     # Whoosh search integration
│   ├── search_enhanced.py         # Enhanced search with metadata
│   ├── templates/                 # HTML templates
│   └── static/                    # CSS/JS assets
├── tests/                         # Smoke tests
└── data/                          # Downloaded data (git-ignored)
    ├── metadata/                  # SQLite database, checkpoints, descriptions
    │   ├── marketplace.db         # Apps and versions database
    │   ├── checkpoints/           # Resume checkpoints
    │   ├── versions/              # Version JSON files (legacy)
    │   └── descriptions/          # Plugin description pages
    │       └── .whoosh_index/     # Search index
    └── binaries/                  # JAR/OBR files by product
```

## Installation

### Prerequisites

- **Python 3.11+** (tested with 3.11, may work with 3.8+)
- **Atlassian Marketplace credentials** (optional for public data, required for full access)
- **Git** (for cloning the repository)
- **Docker** (optional, for containerized deployment)

### Quick Setup (Windows)

**Recommended: Use the Launcher Script**

Double-click `start.bat` or run in PowerShell:

```powershell
.\start.ps1
```

The launcher script will automatically:
- Check Python installation
- Create virtual environment if needed
- Install dependencies if needed
- Install Playwright Chromium browser
- Create `.env` file from `.env.example` if missing
- Launch Flask web application

**Important:** On first run, the script will create `.env` file. Edit it with your credentials and storage paths before running scrapers:
- `MARKETPLACE_USERNAME` and `MARKETPLACE_API_TOKEN`
- `ADMIN_USERNAME` and `ADMIN_PASSWORD`
- Storage paths (optional, uses `./data` by default)

### Manual Setup (Linux/Mac/Windows)

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd AtlassianMarketplaceScraper
   ```

2. **Create and activate virtual environment:**
   ```bash
   python -m venv venv

   # Linux/Mac:
   source venv/bin/activate

   # Windows:
   venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Install Playwright browsers:**
   ```bash
   playwright install-deps
   playwright install chromium
   ```

5. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings (see Configuration section)
   ```

## Configuration

Edit `.env` file to customize behavior:

### Required Settings

```bash
# Atlassian Marketplace Credentials
# Get API token from: https://id.atlassian.com/manage-profile/security/api-tokens
MARKETPLACE_USERNAME=your-email@example.com
MARKETPLACE_API_TOKEN=your-api-token-here

# Admin credentials for management interface
ADMIN_USERNAME=admin
ADMIN_PASSWORD=change-this-secure-password

# Flask secret key (generate with: python -c "import secrets; print(secrets.token_hex(32))")
SECRET_KEY=change-this-to-a-random-secret-key
```

### Optional Settings

```bash
# Scraper Settings
SCRAPER_BATCH_SIZE=50              # Apps per API request
SCRAPER_REQUEST_DELAY=0.5          # Seconds between requests
VERSION_AGE_LIMIT_DAYS=365         # Version date filter (days)
MAX_CONCURRENT_DOWNLOADS=3         # Parallel binary downloads
MAX_VERSION_SCRAPER_WORKERS=10     # Parallel version scraper threads
MAX_RETRY_ATTEMPTS=3               # Retry failed requests

# Flask Settings
FLASK_PORT=5000
FLASK_DEBUG=True

# Storage Backend
USE_SQLITE=True                    # Recommended: True for SQLite storage

# Logging
LOG_LEVEL=INFO
```

### Advanced: Custom Storage Paths

Distribute data across multiple drives:

```bash
# Base directory for all data
DATA_BASE_DIR=/path/to/data

# Or set individually:
METADATA_DIR=/path/to/metadata
DATABASE_PATH=/path/to/marketplace.db
LOGS_DIR=/path/to/logs

# Product-specific binary storage (useful for large datasets)
BINARIES_DIR_JIRA=/mnt/disk1/jira
BINARIES_DIR_CONFLUENCE=/mnt/disk2/confluence
BINARIES_DIR_BITBUCKET=/mnt/disk3/bitbucket
BINARIES_DIR_BAMBOO=/mnt/disk4/bamboo
BINARIES_DIR_CROWD=/mnt/disk5/crowd
```

### Advanced: Encrypted Credentials

For multiple accounts with automatic rotation:

1. Leave `MARKETPLACE_USERNAME` and `MARKETPLACE_API_TOKEN` empty in `.env`
2. Create `.credentials.json` with encrypted credentials (see utils/credentials.py)
3. The system will automatically use encrypted credentials with round-robin rotation

## Usage

### Complete Workflow (4 Steps)

#### Step 1: Scrape Apps

Discover all apps from the Atlassian Marketplace:

```bash
python run_scraper.py
```

**Options:**
- `--resume` - Resume from last checkpoint after interruption

**Output:**
- Apps metadata saved to `data/metadata/marketplace.db`
- Progress checkpointed every 100 apps
- Logs in `logs/scraper.log`

#### Step 2: Scrape Versions

Fetch version history for all apps with compatibility data:

```bash
# All products
python run_version_scraper.py

# Specific product only
python run_version_scraper.py jira
python run_version_scraper.py confluence
```

**Features:**
- Uses dual API system (v2 + v3) for complete compatibility data
- Parallel processing with configurable worker threads
- Filters: Last 365 days, Server/DC only

**Output:**
- Version metadata with compatibility strings saved to database
- Example: "Jira Server 9.0.0 - 10.2.1"

#### Step 3: Download Binaries

Download JAR/OBR files for all versions:

```bash
# Download all products
python run_downloader.py

# Download specific product
python run_downloader.py jira
python run_downloader.py confluence
```

**Features:**
- Concurrent downloads (default: 3 parallel)
- Automatic retry on failure (max 3 attempts)
- Resume capability for interrupted downloads
- Automatic storage reindexing before download

**Output:**
- Files organized: `data/binaries/{product}/{addon_key}/{version_id}/`
- Failed downloads logged to `logs/failed_downloads.log`

#### Step 4 (Optional): Download Plugin Descriptions

Scrape full marketplace pages with Playwright:

```bash
python run_description_downloader.py
```

**Features:**
- Downloads complete HTML pages with inline styles
- Captures all assets (images, CSS, JS, fonts)
- Extracts release notes for all versions
- Saves vendor documentation URLs

**Output:**
- Descriptions saved to `data/metadata/descriptions/{addon_key}/`
- Structure: `full_page/index.html` + `full_page/assets/`

**Requires:** Playwright Chromium browser (`playwright install chromium`)

#### Step 5 (Optional): Build Search Index

Build Whoosh search index for full-text search:

```bash
python run_index_search.py
```

**Output:**
- Search index built in `data/metadata/descriptions/.whoosh_index/`
- Enables full-text search in web interface

### Additional Commands

#### Reindex Storage

Sync metadata with actual files on disk:

```bash
python run_reindex.py
python run_reindex.py --clean-orphaned  # Also remove untracked files
```

**Use when:**
- Files manually deleted/moved
- Downloaded flags incorrect
- Storage inconsistencies

#### Run Smoke Tests

Verify system health:

```bash
python run_smoke_tests.py
python run_smoke_tests.py --verbose   # Detailed output
python run_smoke_tests.py --quick     # Skip slow tests
```

**Tests:**
- MetadataStore initialization
- DownloadManager functionality
- Search system (Whoosh + EnhancedSearch)
- File system structure
- API endpoints

### Web Interface

Launch Flask web application:

```bash
python app.py
```

**Access:** http://localhost:5000

**Features:**
- Dashboard with statistics (apps, versions, downloads)
- App catalog with search and pagination
- Full-text search across descriptions and release notes
- App detail pages with version history and release notes
- Binary file downloads
- Management console (admin-only)
- REST API endpoints

**Main Routes:**
- `/` - Dashboard
- `/apps` - App listing
- `/apps/<addon_key>` - App detail page
- `/search` - Full-text search UI
- `/manage` - Management console (requires auth)

**API Endpoints:**
- `GET /api/apps` - JSON app list (supports `?product=` and `?search=` filters)
- `GET /api/apps/<addon_key>` - JSON app details with versions
- `GET /api/stats` - Statistics summary
- `GET /api/storage/stats` - Detailed storage statistics (slow, file system scan)
- `GET /api/products` - Product list
- `GET /api/search?q=query` - Full-text search
- `POST /api/search/rebuild-index` - Rebuild search index (admin-only)
- `GET /download/<product>/<addon_key>/<version_id>` - Binary file download

## Docker Deployment

### Quick Start

Build and start the web interface:

```bash
docker-compose up -d web
```

**Access:** http://localhost:5000

### Running Scrapers

All scraper services use `profiles: [scraping]` for manual-only execution:

```bash
# Step 1: Scrape apps
docker-compose run --rm scraper

# Step 2: Scrape versions
docker-compose run --rm version-scraper

# Step 3: Download binaries
docker-compose run --rm downloader

# Step 4: Download descriptions (requires Playwright)
docker-compose run --rm description-downloader

# Step 5: Build search index
docker-compose run --rm search-indexer
```

### Useful Commands

```bash
# View logs
docker-compose logs -f web

# Rebuild images (required after code changes)
docker-compose build --no-cache

# Stop all services
docker-compose down

# Run reindex inside container
docker-compose run --rm web python run_reindex.py

# Run smoke tests
docker-compose run --rm web python run_smoke_tests.py
```

### Docker Configuration

**Services:**
- `web` - Flask web application (auto-starts)
- `scraper` - App scraper (manual-only)
- `version-scraper` - Version scraper (manual-only)
- `downloader` - Binary downloader (manual-only)
- `description-downloader` - Description scraper (manual-only)
- `search-indexer` - Search index builder (manual-only)

**Volume Mounts (configurable via .env):**

All storage paths are configurable via environment variables:

```bash
# Simple mode (defaults - single drive)
METADATA_PATH=./data/metadata    # Metadata, database, descriptions
LOGS_PATH=./logs                 # Log files
BINARIES_PATH=./data/binaries    # Binary files (JAR/OBR)
```

**Multi-Drive Setup:**

Distribute storage across multiple drives for better I/O performance:

```bash
# Example 1: Everything on external drive
METADATA_PATH=/mnt/external/marketplace/metadata
LOGS_PATH=/mnt/external/marketplace/logs
BINARIES_PATH=/mnt/external/marketplace/binaries

# Example 2: Metadata on SSD, binaries on HDD
METADATA_PATH=/mnt/ssd/marketplace/metadata
LOGS_PATH=/mnt/ssd/marketplace/logs
BINARIES_PATH=/mnt/hdd/marketplace-binaries
```

For per-product binaries on separate drives, create a `docker-compose.override.yml` file. See examples in `docker-compose.yml` comments.

**Environment Variables:**
- All `.env` variables work in Docker (credentials, settings, etc.)
- Docker-specific: `METADATA_PATH`, `LOGS_PATH`, `BINARIES_PATH` (host paths)
- App-internal: `METADATA_DIR`, `LOGS_DIR`, `BINARIES_DIR_*` (container paths)

**Features:**
- Playwright browser pre-installed for description scraping
- Health checks for web service
- Automatic restart policy for web service
- Custom bridge network for service communication
- YAML anchor for DRY volume configuration

## Data Storage

### Metadata

```
data/metadata/
├── marketplace.db              # SQLite: Apps, versions, compatibility data
├── checkpoints/                # Resume checkpoints (pickle files)
│   └── scrape_checkpoint.pkl
├── versions/                   # Per-app version JSON (legacy, if not using SQLite)
│   └── {addon_key}_versions.json
└── descriptions/               # Plugin descriptions (HTML, JSON, assets)
    ├── {addon_key}/
    │   ├── full_page/
    │   │   ├── index.html
    │   │   └── assets/
    │   ├── {timestamp}.json
    │   └── {timestamp}.html
    └── .whoosh_index/          # Search index
```

### Binaries

```
data/binaries/
├── jira/
│   └── com.example.app/
│       └── 12345/              # version_id
│           └── app-1.0.0.jar
├── confluence/
├── bitbucket/
├── bamboo/
└── crowd/
```

### Database Schema

**apps table:**
- `addon_key` (PRIMARY KEY) - Unique app identifier
- `name` - Display name
- `vendor` - Vendor name
- `app_id` - Numeric ID (required for download URLs)
- `products` - JSON array of products
- `hosting` - JSON array of hosting types
- `marketplace_url` - Marketplace page URL

**versions table:**
- `id` (PRIMARY KEY) - Auto-increment
- `addon_key` (FOREIGN KEY) - Reference to apps table
- `version_id` - Version identifier
- `version_name` - Display version (e.g., "1.0.0")
- `release_date` - ISO format date
- `compatibility` - Human-readable compatibility string
- `download_url` - Binary download URL
- `downloaded` - Boolean flag
- `file_path` - Local file path if downloaded

**parent_software_versions table:**
- Cached build number → version string mappings
- Reduces API v3 calls during version scraping

## Logging

Logs are written to `logs/` directory:

- `scraper.log` - General scraping activity (apps, versions)
- `download.log` - Download operations and progress
- `failed_downloads.log` - Failed download errors for retry
- `web.log` - Flask web interface logs
- `indexer.log` - Search index building logs

## Error Handling

- **API Rate Limiting**: Adaptive delay with exponential backoff
- **Network Failures**: Automatic retry with configurable attempts (default: 3)
- **Interrupted Scraping**: Pickle-based checkpoint system for resume
- **Download Failures**: Logged to `failed_downloads.log` for manual retry
- **Database Locking**: SQLite WAL mode for concurrent reads/writes
- **Thread Safety**: ThreadPoolExecutor with locks for shared resources

## Performance

### Expected Times

- **Apps scraping**: ~5-10 minutes for all products (~7,000 apps)
- **Versions scraping**: ~1-2 hours (depends on total apps and workers)
- **Binary downloads**: Varies by file sizes and network speed (can be TBs of data)
- **Description scraping**: ~10-15 hours (Playwright browser automation, ~7,000 apps)
- **Search indexing**: ~5-10 minutes (depends on number of descriptions)

### Storage Requirements

- **Metadata**: ~100-500 MB (database + checkpoints)
- **Descriptions**: ~2-5 GB (HTML pages + assets)
- **Binaries**: 10 GB - 10+ TB (depends on products and version age limit)

**Tip:** Use product-specific storage paths to distribute binaries across multiple drives.

### Optimization Tips

1. **Increase workers** for faster version scraping:
   ```bash
   MAX_VERSION_SCRAPER_WORKERS=20  # Default: 10
   ```

2. **Increase concurrent downloads**:
   ```bash
   MAX_CONCURRENT_DOWNLOADS=5  # Default: 3
   ```

3. **Reduce version age limit** to download less data:
   ```bash
   VERSION_AGE_LIMIT_DAYS=180  # Default: 365
   ```

4. **Use multiple drives** for better I/O performance:
   ```bash
   BINARIES_DIR_JIRA=/mnt/ssd1/jira
   BINARIES_DIR_CONFLUENCE=/mnt/ssd2/confluence
   ```

## Troubleshooting

### No apps found
- Check internet connection
- Verify Marketplace API is accessible (`https://marketplace.atlassian.com/rest/2`)
- Check credentials in `.env` file
- Review logs in `logs/scraper.log`

### 404 errors during download
- Run app scraper to populate `app_id` field in database
- The numeric `app_id` is required for download URLs (not `addon_key`)
- If using Docker, rebuild images: `docker-compose build --no-cache`

### Version scraping is slow
- Increase `MAX_VERSION_SCRAPER_WORKERS` in `.env` (default: 10, can go up to 20+)
- Check network latency to Marketplace API
- Review logs for rate limiting issues

### Download statistics incorrect
- Run storage reindex: `python run_reindex.py`
- This syncs metadata `downloaded` flags with actual files on disk

### Database locked errors
- Rare with WAL mode, but ensure only one write operation at a time
- Check for stale lock files in `data/metadata/`

### Compatibility data missing
- Ensure `USE_SQLITE=True` in `.env` (required for parent software version caching)
- Re-run version scraper to fetch compatibility data from API v3

### Search not working
- Build search index: `python run_index_search.py`
- Index is not built automatically, must be triggered manually
- Check for errors in `logs/indexer.log`

### Playwright browser not found
- Install Chromium: `playwright install chromium`
- On Windows, use launcher scripts which auto-install
- On Docker, rebuild image (Playwright is pre-installed in latest Dockerfile)

### Web interface errors
- Ensure database exists: `data/metadata/marketplace.db`
- Check Flask logs in console or `logs/web.log`
- Verify SECRET_KEY is set in `.env`

## Development

### Testing

Run smoke tests to verify system health:

```bash
python run_smoke_tests.py
python run_smoke_tests.py --verbose
python -m unittest tests.test_smoke
pytest tests/test_smoke.py -v  # If pytest installed
```

### Code Structure

- **config/**: Settings, product definitions, path management
- **scraper/**: Core scraping components (API clients, scrapers, storage)
- **models/**: Data models (App, Version, DownloadStatus)
- **utils/**: Utilities (logger, rate limiter, checkpoint, auth, credentials)
- **web/**: Flask application (routes, templates, static files, search)
- **tests/**: Smoke tests for core functionality

### Key Implementation Patterns

- **Dual API System**: Combines Marketplace API v2 (apps, versions) + v3 (compatibility)
- **Checkpoint/Resume**: Pickle-based state persistence for interruption recovery
- **Rate Limiting**: Adaptive delays with exponential backoff on HTTP errors
- **Thread Safety**: WAL mode for SQLite, ThreadPoolExecutor for parallel processing
- **Storage Abstraction**: MetadataStoreSQLite with consistent interface

## License

This project is for personal/educational use. Respect Atlassian's Terms of Service when scraping their marketplace.

## Contributing

This is a personal project. For issues or suggestions, please open an issue in the repository.
