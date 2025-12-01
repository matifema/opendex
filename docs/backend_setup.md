# Backend Setup Instructions

The Pet Battler app uses a containerized Python backend to handle image generation (currently a mock generator).

## Prerequisites

- Docker
- Docker Compose

## Project Structure

```
/
├── backend/
│   ├── app.py              # FastAPI application
│   ├── Dockerfile          # Container definition
│   └── requirements.txt    # Python dependencies
├── docker-compose.yml      # Orchestration
└── ...
```

## Running the Backend

1.  **Navigate to the project root**:
    ```bash
    cd /path/to/project
    ```

2.  **Configure Environment**:
    Open `docker-compose.yml` and replace `your_api_key_here` with your actual Google API Key.
    ```yaml
    environment:
      - GOOGLE_API_KEY=AIzaSy...
    ```

3.  **Start the container**:
    ```bash
    docker-compose up --build
    ```
    
    The backend will start on `http://localhost:8000`.

4.  **Verify it's running**:
    Open your browser or use curl:
    ```bash
    curl http://localhost:8000/health
    # Expected output: {"status":"ok"}
    ```

## Connecting the App

When running the Flutter app, you need to point it to your backend.

### For Android Emulator
Use `10.0.2.2` to access the host machine's localhost.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### For iOS Simulator / Desktop
Use `localhost`.

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

### For Physical Devices
Ensure your phone and computer are on the same Wi-Fi, and use your computer's local IP address (e.g., `192.168.1.x`).

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000
```

## Customizing Image Generation

The backend uses Google's Nano Banana (Imagen) model via the `google-genai` SDK.
Ensure your `GOOGLE_API_KEY` has access to the Gemini API.
