@echo off
echo Testing Docker installation...
echo.

echo 1. Checking Docker version:
docker --version
echo.

echo 2. Checking Docker Compose version:
docker compose version
echo.

echo 3. Testing Docker with hello-world:
docker run --rm hello-world
echo.

echo 4. Testing our n8n stack validation:
cd n8n-production
docker compose config
echo.

echo Docker installation test complete!
pause
