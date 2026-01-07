# Smoke Tests for Atlassian Marketplace Scraper

Smoke tests are basic tests that verify the main functions of the system work and the system is not broken.

## What smoke tests check

### 1. **MetadataStore** (`TestMetadataStore`)
- Metadata store initialization
- Getting app count
- Getting app list
- Finding app by key

### 2. **DownloadManager** (`TestDownloadManager`)
- Download manager initialization
- Getting storage statistics
- Getting detailed storage statistics

### 3. **Search Functionality** (`TestSearchFunctionality`)
- Import and initialization of EnhancedSearch
- Basic EnhancedSearch functionality
- Import and initialization of WhooshSearchIndex
- Checking if index needs rebuilding

### 4. **File System** (`TestFileSystem`)
- Existence of description directories
- Existence of metadata directories
- Existence of binary file directories

### 5. **Settings** (`TestSettings`)
- Settings loading
- Path correctness in settings

### 6. **Enhanced Search Detailed** (`TestSearchEnhancedDetailed`)
- Search by app names
- Search by vendor names
- Empty query handling
- Search result structure

### 7. **Storage Stats** (`TestStorageStats`)
- Basic storage statistics structure
- Detailed storage statistics structure

## Running tests

### Quick start

```bash
python run_smoke_tests.py
```

### With verbose output

```bash
python run_smoke_tests.py --verbose
```

### Only quick tests

```bash
python run_smoke_tests.py --quick
```

### Directly via unittest

```bash
python -m unittest tests.test_smoke
```

### Via pytest (if installed)

```bash
pytest tests/test_smoke.py -v
```

## Expected result

On successful execution of all tests you will see:

```
======================================================================
SMOKE TESTS - Atlassian Marketplace Scraper
======================================================================

Tests run: 25
Failures: 0
Errors: 0
Skipped: 0
======================================================================

✓ All smoke tests passed!
```

## Interpreting results

- **Tests run**: Number of tests executed
- **Failures**: Number of failed tests (assertion failed)
- **Errors**: Number of tests with errors (exceptions)
- **Skipped**: Number of skipped tests (e.g., if Whoosh is not installed)

## What to do if tests fail

1. **Check logs**: Errors contain traceback with detailed information
2. **Check dependencies**: Make sure all packages are installed (`pip install -r requirements.txt`)
3. **Check data**: Some tests require data in the database (apps, descriptions)
4. **Check paths**: Make sure paths in settings are correct

## Adding new tests

To add a new smoke test:

1. Open `tests/test_smoke.py`
2. Add a new class inheriting from `unittest.TestCase`
3. Add methods starting with `test_`
4. Add the class to the `test_classes` list in the `run_smoke_tests()` function

Example:

```python
class TestNewFeature(unittest.TestCase):
    """Test new feature."""

    def test_new_feature_basic(self):
        """Test basic new feature functionality."""
        # Your test code here
        self.assertTrue(True)
```

## Notes

- Smoke tests should execute quickly (a few seconds)
- Tests should not modify data (read-only)
- Tests should be independent of each other
- Some tests may be skipped if dependencies are unavailable
