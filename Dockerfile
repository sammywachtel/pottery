# Dockerfile

# --- Stage 1: Build Stage (Optional but good for managing dependencies) ---
# Use an official Python runtime as a parent image
FROM python:3.10-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /app

# Install build dependencies (if any, e.g., for compiling packages)
# RUN apt-get update && apt-get install -y --no-install-recommends build-essential

# Install Python dependencies
# Copy only requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


# --- Stage 2: Runtime Stage ---
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
# Set the default port Cloud Run expects (can be overridden by Cloud Run)
ENV PORT 8080
# Set PYTHONPATH if your project structure requires it (usually not needed with this flat structure)
# ENV PYTHONPATH /app

# Set work directory
WORKDIR /app

# Install runtime dependencies (if any, e.g., system libraries needed by Python packages)
# RUN apt-get update && apt-get install -y --no-install-recommends some-runtime-lib && rm -rf /var/lib/apt/lists/*

# Copy installed wheels from the builder stage
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .
# Install dependencies from wheels
RUN pip install --no-cache /wheels/*

# Copy the rest of the application code
COPY . .

# Expose the port the app runs on (matches ENV PORT)
EXPOSE 8080

# Command to run the application using Uvicorn
# Use the PORT environment variable provided by Cloud Run
# Use 0.0.0.0 to listen on all interfaces within the container
# Set the number of workers based on CPU availability (Cloud Run handles scaling)
# Gunicorn is often recommended as a process manager for Uvicorn in production
# CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "main:app", "--bind", "0.0.0.0:$PORT"]

# Simpler Uvicorn command (often sufficient for Cloud Run)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]

