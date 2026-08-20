-- Add updated_at column to uploaded_files if missing
ALTER TABLE uploaded_files ADD COLUMN updated_at TEXT;
