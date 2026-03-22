"""Google Cloud Storage service for plant photo uploads."""

import logging
import os
from datetime import timedelta

from google.cloud import storage

logger = logging.getLogger(__name__)

DEFAULT_BUCKET = "healthy-plant-uploads"
SIGNED_URL_EXPIRATION_MINUTES = 30


class StorageService:
    """Service for generating signed upload URLs and public URLs for GCS."""

    def __init__(self):
        self.bucket_name = os.getenv("GCS_BUCKET_NAME", DEFAULT_BUCKET)
        try:
            self.client = storage.Client()
            self.bucket = self.client.bucket(self.bucket_name)
            logger.info(f"Storage client initialized for bucket: {self.bucket_name}")
        except Exception as e:
            logger.warning(f"Failed to initialize Storage client: {e}")
            self.client = None
            self.bucket = None

    def generate_upload_url(self, user_id: str, filename: str) -> str:
        """
        Generate a signed URL for uploading a file to GCS.

        Args:
            user_id: The authenticated user's ID.
            filename: The original filename (used to determine content type and path).

        Returns:
            A signed URL string that the client can PUT to directly.
        """
        if not self.bucket:
            raise RuntimeError("Storage service not initialized")

        blob_path = f"users/{user_id}/plants/{filename}"
        blob = self.bucket.blob(blob_path)

        # Determine content type from extension
        content_type = _get_content_type(filename)

        url = blob.generate_signed_url(
            version="v4",
            expiration=timedelta(minutes=SIGNED_URL_EXPIRATION_MINUTES),
            method="PUT",
            content_type=content_type,
        )

        logger.info(f"Generated upload URL for {blob_path}")
        return url

    def get_public_url(self, user_id: str, filename: str) -> str:
        """
        Get the public URL for an uploaded file.

        Assumes the bucket or object has public read access configured,
        or the URL is accessed with appropriate credentials.

        Args:
            user_id: The user's ID.
            filename: The filename in storage.

        Returns:
            The public HTTPS URL for the object.
        """
        blob_path = f"users/{user_id}/plants/{filename}"
        return f"https://storage.googleapis.com/{self.bucket_name}/{blob_path}"


def _get_content_type(filename: str) -> str:
    """Determine content type from file extension."""
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    content_types = {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "gif": "image/gif",
        "webp": "image/webp",
        "heic": "image/heic",
        "heif": "image/heif",
    }
    return content_types.get(ext, "application/octet-stream")
