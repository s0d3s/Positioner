import os
import sys
from enum import StrEnum
from datetime import datetime, timedelta

from loguru import logger


def prepare_logger():
    def rotation_by_time_and_size(message, file):
        # --- 1. Rotate daily ---
        file_creation_time = datetime.fromtimestamp(os.path.getctime(file.name))
        if datetime.now() - file_creation_time >= timedelta(days=1):
            return True
        
        try:
            stats = os.stat(file.name)
        except FileNotFoundError:
            return False

        # --- 2. Rotate if file exceeds 1 MB ---
        if stats.st_size > 1 * 1024 * 1024:  # 1 MB
            return True

        return False
    
    global SCRIPT_DIR, LOGS_DIR
    try:
        #Added by cx_Freeze
        import BUILD_CONSTANTS

        SCRIPT_DIR = os.path.dirname(os.path.abspath(sys.executable))

    except ImportError:
        SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    LOGS_DIR = os.path.join(SCRIPT_DIR, "logs")

    os.makedirs(LOGS_DIR, exist_ok=True)

    # logger.remove()
    # logger.add(sys.stdout, level="TRACE")
    logger.add(
        os.path.join(
            LOGS_DIR,
            "runtime.log"
        ),
        rotation=rotation_by_time_and_size,
        retention="30 days",
        encoding="utf-8",
        level="TRACE",
    )


class LogLevel(StrEnum):
    TRACE = "TRACE"
    DEBUG = "DEBUG"
    INFO = "INFO"
    SUCCESS = "SUCCESS"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class StreamToLogger:
    """
    Stub to redirects its write method to Loguru's logger.
    """
    def __init__(self, level=LogLevel.DEBUG):
        self._level = level

    def write(self, buffer):
        for line in buffer.rstrip().splitlines():
            logger.opt(depth=1).log(self._level, line.rstrip())

    def flush(self):
        pass


prepare_logger()
