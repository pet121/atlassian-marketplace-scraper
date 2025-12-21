"""Credentials manager for storing sensitive data separately from .env file."""

import os
import json
import random
import threading
from typing import Optional, Dict, List
from utils.logger import get_logger

logger = get_logger('credentials')

# Credentials file (not in git)
CREDENTIALS_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.credentials.json')


def get_credentials() -> Dict[str, str]:
    """
    Get credentials from .credentials.json file.
    Supports both old format (single credentials) and new format (multiple accounts).
    
    Returns:
        Dictionary with credentials (username, api_token) or list of accounts
    """
    if not os.path.exists(CREDENTIALS_FILE):
        return {
            'username': '',
            'api_token': ''
        }
    
    try:
        with open(CREDENTIALS_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
            # Check if it's the new format with multiple accounts
            if isinstance(data, dict) and 'accounts' in data:
                # Return first account for backward compatibility
                accounts = data.get('accounts', [])
                if accounts:
                    return {
                        'username': accounts[0].get('username', ''),
                        'api_token': accounts[0].get('api_token', '')
                    }
                return {'username': '', 'api_token': ''}
            
            # Old format - single credentials
            return data
    except Exception as e:
        logger.error(f"Error reading credentials file: {str(e)}")
        return {
            'username': '',
            'api_token': ''
        }


def get_all_credentials() -> List[Dict[str, str]]:
    """
    Get all credentials from .credentials.json file.
    
    Returns:
        List of dictionaries with credentials (username, api_token)
    """
    if not os.path.exists(CREDENTIALS_FILE):
        return []
    
    try:
        with open(CREDENTIALS_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
            # Check if it's the new format with multiple accounts
            if isinstance(data, dict) and 'accounts' in data:
                return data.get('accounts', [])
            
            # Old format - single credentials, convert to list
            if isinstance(data, dict) and 'username' in data and data.get('username'):
                return [{
                    'username': data.get('username', ''),
                    'api_token': data.get('api_token', '')
                }]
            
            return []
    except Exception as e:
        logger.error(f"Error reading credentials file: {str(e)}")
        return []


def save_credentials(username: str, api_token: str) -> bool:
    """
    Save credentials to .credentials.json file.
    Maintains backward compatibility with old format.
    
    Args:
        username: Marketplace username
        api_token: Marketplace API token
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Try to preserve existing accounts if using new format
        existing_accounts = []
        if os.path.exists(CREDENTIALS_FILE):
            try:
                with open(CREDENTIALS_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    if isinstance(data, dict) and 'accounts' in data:
                        existing_accounts = data.get('accounts', [])
            except:
                pass
        
        # Check if account already exists
        account_exists = False
        for account in existing_accounts:
            if account.get('username') == username:
                account['api_token'] = api_token
                account_exists = True
                break
        
        if not account_exists:
            existing_accounts.append({
                'username': username,
                'api_token': api_token
            })
        
        credentials = {
            'accounts': existing_accounts
        }
        
        with open(CREDENTIALS_FILE, 'w', encoding='utf-8') as f:
            json.dump(credentials, f, indent=2)
        
        logger.info(f"Credentials saved successfully ({len(existing_accounts)} account(s))")
        return True
    except Exception as e:
        logger.error(f"Error saving credentials: {str(e)}")
        return False


def save_multiple_credentials(accounts: List[Dict[str, str]]) -> bool:
    """
    Save multiple credentials to .credentials.json file.
    
    Args:
        accounts: List of dictionaries with 'username' and 'api_token'
        
    Returns:
        True if successful, False otherwise
    """
    try:
        credentials = {
            'accounts': accounts
        }
        
        with open(CREDENTIALS_FILE, 'w', encoding='utf-8') as f:
            json.dump(credentials, f, indent=2)
        
        logger.info(f"Saved {len(accounts)} account(s) successfully")
        return True
    except Exception as e:
        logger.error(f"Error saving credentials: {str(e)}")
        return False


class CredentialsRotator:
    """Manages rotation of multiple API credentials for parallel requests."""
    
    def __init__(self):
        """Initialize credentials rotator."""
        self._lock = threading.Lock()
        self._accounts: List[Dict[str, str]] = []
        self._current_index = 0
        self._load_accounts()
    
    def _load_accounts(self):
        """Load accounts from credentials file."""
        with self._lock:
            self._accounts = get_all_credentials()
            if not self._accounts:
                # Fallback to single credentials for backward compatibility
                creds = get_credentials()
                if creds.get('username'):
                    self._accounts = [creds]
            self._current_index = 0
    
    def get_next(self) -> Optional[Dict[str, str]]:
        """
        Get next credentials in round-robin fashion.
        
        Returns:
            Dictionary with 'username' and 'api_token', or None if no accounts available
        """
        with self._lock:
            if not self._accounts:
                self._load_accounts()
            
            if not self._accounts:
                return None
            
            account = self._accounts[self._current_index]
            self._current_index = (self._current_index + 1) % len(self._accounts)
            return account.copy()
    
    def get_random(self) -> Optional[Dict[str, str]]:
        """
        Get random credentials.
        
        Returns:
            Dictionary with 'username' and 'api_token', or None if no accounts available
        """
        with self._lock:
            if not self._accounts:
                self._load_accounts()
            
            if not self._accounts:
                return None
            
            return random.choice(self._accounts).copy()
    
    def get_all(self) -> List[Dict[str, str]]:
        """
        Get all available credentials.
        
        Returns:
            List of dictionaries with 'username' and 'api_token'
        """
        with self._lock:
            if not self._accounts:
                self._load_accounts()
            return [acc.copy() for acc in self._accounts]
    
    def count(self) -> int:
        """Get number of available accounts."""
        with self._lock:
            if not self._accounts:
                self._load_accounts()
            return len(self._accounts)
    
    def reload(self):
        """Reload accounts from file."""
        with self._lock:
            self._load_accounts()


# Global instance
_rotator = None
_rotator_lock = threading.Lock()


def get_credentials_rotator() -> CredentialsRotator:
    """Get global credentials rotator instance."""
    global _rotator
    with _rotator_lock:
        if _rotator is None:
            _rotator = CredentialsRotator()
        return _rotator

