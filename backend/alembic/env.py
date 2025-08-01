from logging.config import fileConfig
import os
import sys
from sqlalchemy import engine_from_config, pool, create_engine
from alembic import context
from dotenv import load_dotenv

# Load .env variables
load_dotenv()

# Get DATABASE_URL
DB_URL = os.getenv("DATABASE_URL")

# Add app to Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Import your Base metadata
from app.models import Base

# Alembic config object
config = context.config

# Set DB URL in Alembic config dynamically
config.set_main_option("sqlalchemy.url", DB_URL)

# Logging setup
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Set your model metadata
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = DB_URL  # Use loaded env URL
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = create_engine(
        DB_URL, poolclass=pool.NullPool
    )  # Use create_engine directly
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


# Choose offline or online mode
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
