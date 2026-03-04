import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
load_dotenv()
raw_database_url = os.getenv("DATABASE_URL")
if not raw_database_url:
    raise RuntimeError("DATABASE_URL is not set")

if raw_database_url.startswith("postgres://"):
    raw_database_url = raw_database_url.replace("postgres://", "postgresql://", 1)

if raw_database_url.startswith("postgresql://") and not raw_database_url.startswith("postgresql+asyncpg://"):
    raw_database_url = raw_database_url.replace("postgresql://", "postgresql+asyncpg://", 1)

DATABASE_URL = raw_database_url

echo = (os.getenv("SQLALCHEMY_ECHO") or "").lower() in {"1", "true", "yes"}
engine = create_async_engine(DATABASE_URL, echo=echo)

AsyncSessionLocal = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

Base = declarative_base()
