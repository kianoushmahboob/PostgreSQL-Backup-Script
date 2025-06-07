# PostgreSQL-Backup-Script

A **secure** and **flexible** Bash script to automate PostgreSQL database backups with support for:

- Compressed backups using `pg_dump` custom format (`.dump`)
- Loading database credentials securely from a `.env` file
- Optional cleanup of old backups based on age (`-d` option)
- Optional deletion of all backups except the latest with user confirmation (`-c` option)
- Logging of backup and cleanup activities

---

## Features

- **Easy configuration** via environment variables stored in `.env`
- **Safe password handling** by exporting `PGPASSWORD` only during `pg_dump`
- **Flexible retention policy**: Delete backups older than specified days
- **Full cleanup option**: Delete all backups except the most recent one, with interactive confirmation
- **Robust error handling** with strict bash options
- **Detailed logging** to a configurable log file

---

## Requirements

- PostgreSQL client utilities (`pg_dump`) installed and accessible in the shell
- Bash shell (tested with `bash` on Linux)
- `find` command for cleanup
- Write permissions for backup directory and log file

---

## Usage

1. **Prepare `.env` file**

Create a `.env` file in the script directory, containing the following variables:

```env
DB_NAME=your_database_name
DB_USER=your_database_user
DATABASES_PASSWORD=your_database_password
DB_HOST=localhost             # optional, defaults to localhost
DB_PORT=5432                  # optional, defaults to 5432
BACKUP_DIR=/path/to/backups   # optional, defaults to ./backups
