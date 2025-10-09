# oaCamBridge Workflow Diagrams

Comprehensive workflow documentation for camera streaming service, data flow patterns, and AI service integration.

## Camera Data Flow Architecture

### Core Camera Streaming Pipeline

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[Camera Device] --> B[OpenCV Capture]
    B --> C[Frame Processing]
    C --> D[Dual Output Pipeline]

    D --> E[HTTP/MJPEG Streaming]
    D --> F[Frame File Output]

    E --> E1[HTTP Server: Port 8086]
    E1 --> E2["Stream Endpoint"]
    E2 --> E3[MJPEG Video Stream]
    E3 --> E4[Web Browser Clients]

    F --> F1[Frame Directory: /tmp/webcam/]
    F1 --> F2[JPEG File Generation]
    F2 --> F3[Sequential Frame Files]
    F3 --> F4[AI Service Consumption]

    F4 --> G[oaTracker: Human Detection]
    F4 --> H[oaParkingMonitor: Vehicle Detection]

    G --> G1[Human Detection Results]
    H --> H1[Parking Analysis Results]

    style A fill:#3b82f6,color:#f8fafc
    style C fill:#f59e0b,color:#f8fafc
    style E4 fill:#10b981,color:#f8fafc
    style G fill:#10b981,color:#f8fafc
    style H fill:#10b981,color:#f8fafc
```

### Frame Processing Workflow

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#f59e0b',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[Camera Initialization] --> B{Camera Available?}
    B -->|No| C[Retry Connection]
    C --> B
    B -->|Yes| D[Start Frame Capture]

    D --> E[Capture Raw Frame]
    E --> F[Frame Validation]
    F --> G{Valid Frame?}
    G -->|No| H[Skip Frame]
    H --> E
    G -->|Yes| I[Frame Processing]

    I --> J[Resolution Scaling]
    J --> K[Quality Compression]
    K --> L[Frame Locking]

    L --> M[Streaming Buffer Update]
    L --> N[File Output Queue]

    M --> O[HTTP Stream Ready]
    N --> P[Generate Frame Filename]
    P --> Q[Save JPEG File]
    Q --> R[Update Frame Counter]

    O --> S[Client Request Handling]
    S --> T[MJPEG Stream Response]
    T --> U[Frame Transmission]

    R --> V[AI Service Polling]
    V --> W[Frame Available for Processing]
    W --> X[AI Service Consumption]

    style A fill:#10b981,color:#f8fafc
    style D fill:#3b82f6,color:#f8fafc
    style I fill:#f59e0b,color:#f8fafc
    style U fill:#10b981,color:#f8fafc
    style X fill:#10b981,color:#f8fafc
```

## HTTP API Structure and Streaming

### HTTP Server Architecture

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
sequenceDiagram
    participant Client as HTTP Client
    participant Server as HTTP Server
    participant Streamer as CameraStreamer
    participant Camera as Camera Device

    Client->>Server: GET /stream
    Server->>Streamer: Request Latest Frame
    Streamer->>Camera: Capture Frame
    Camera-->>Streamer: Raw Frame Data
    Streamer->>Streamer: Process Frame
    Streamer-->>Server: Processed Frame
    Server->>Client: MJPEG Header

    loop Streaming Session
        Server->>Streamer: Request Next Frame
        Streamer->>Camera: Capture Frame
        Camera-->>Streamer: Raw Frame Data
        Streamer->>Streamer: Process Frame
        Streamer-->>Server: JPEG Frame
        Server->>Client: MJPEG Frame Data
    end

    Client->>Server: GET /frame
    Server->>Streamer: Request Single Frame
    Streamer->>Camera: Capture Frame
    Camera-->>Streamer: Raw Frame Data
    Streamer->>Streamer: Process Frame
    Streamer-->>Server: JPEG Frame
    Server-->>Client: Single JPEG Response

    Client->>Server: GET /status
    Server->>Streamer: Get Service Status
    Streamer-->>Server: Status Information
    Server-->>Client: JSON Status Response
```

### API Endpoint Processing

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[HTTP Request] --> B[Route Processing]
    B --> C{Endpoint Type}

    C -->|/stream| D[MJPEG Streaming Handler]
    C -->|/frame| E[Single Frame Handler]
    C -->|/status| F[Status Handler]

    D --> D1[Set MJPEG Headers]
    D1 --> D2[Enter Streaming Loop]
    D2 --> D3[Get Latest Frame]
    D3 --> D4[Send Frame Data]
    D4 --> D5{Client Connected?}
    D5 -->|Yes| D3
    D5 -->|No| D6[Close Stream]

    E --> E1[Get Current Frame]
    E1 --> E2[Set JPEG Headers]
    E2 --> E3[Send Single Frame]
    E3 --> E4[Close Connection]

    F --> F1[Collect Service Metrics]
    F1 --> F2[Get Frame Statistics]
    F2 --> F3[Get Configuration Info]
    F3 --> F4[Generate JSON Response]
    F4 --> F5[Send Status Data]

    D6 --> G[Request Complete]
    E4 --> G
    F5 --> G

    style A fill:#3b82f6,color:#f8fafc
    style G fill:#10b981,color:#f8fafc
    style D fill:#f59e0b,color:#f8fafc
    style E fill:#f59e0b,color:#f8fafc
    style F fill:#f59e0b,color:#f8fafc
```

## AI Service Integration Patterns

### oaTracker Integration Workflow

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
sequenceDiagram
    participant Tracker as oaTracker
    participant CamBridge as oaCamBridge
    participant FileSystem as File System
    participant Model as AI Model

    loop Detection Cycle
        Tracker->>CamBridge: Check for new frames
        CamBridge->>FileSystem: Scan /tmp/webcam/
        FileSystem-->>CamBridge: List frame files
        CamBridge-->>Tracker: Latest frame info

        alt New Frame Available
            Tracker->>FileSystem: Read latest frame
            FileSystem-->>Tracker: JPEG frame data
            Tracker->>Tracker: Preprocess frame
            Tracker->>Model: Run human detection
            Model-->>Tracker: Detection results
            Tracker->>Tracker: Process results
            Note over Tracker: Bounding boxes, confidence scores
        else No New Frame
            Tracker->>Tracker: Wait for next poll
        end
    end

    Tracker->>Tracker: Aggregate detection data
    Tracker->>Tracker: Update analytics
```

### oaParkingMonitor Integration Workflow

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
sequenceDiagram
    participant Parking as oaParkingMonitor
    participant CamBridge as oaCamBridge
    participant FileSystem as File System
    participant Model as YOLO Model
    participant Dashboard as Dashboard Client

    loop Parking Analysis Cycle
        Parking->>CamBridge: Request snapshot
        CamBridge->>FileSystem: Get latest frame
        FileSystem-->>CamBridge: Frame file path
        CamBridge-->>Parking: Frame data

        Parking->>Parking: Preprocess for parking
        Note over Parking: Resize, normalize, format
        Parking->>Model: Run vehicle detection
        Model-->>Parking: Vehicle detections

        Parking->>Parking: Analyze parking spots
        Note over Parking: Spot occupancy, vacancy status
        Parking->>Parking: Calculate occupancy rates
        Parking->>Parking: Update parking database

        alt External Request
            Dashboard->>Parking: GET /detections
            Parking-->>Dashboard: Current parking status
        end
    end

    Parking->>Parking: Generate analytics report
    Parking->>Parking: Log parking patterns
```

### Multi-Service Frame Distribution

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[oaCamBridge Frame Generation] --> B[Frame Storage: /tmp/webcam/]
    B --> C[Frame File: img_XXXXXX.jpg]

    C --> D[Service Detection Layer]
    D --> E{Frame Consumption Pattern}

    E -->|Polling| F[oaTracker]
    E -->|Request-Response| G[oaParkingMonitor]
    E -->|Streaming| H[Web Clients]

    F --> F1[Periodic Frame Poll]
    F1 --> F2[Frame Processing]
    F2 --> F3[Human Detection]
    F3 --> F4[Detection API]

    G --> G1[Snapshot Request]
    G1 --> G2[Frame Processing]
    G2 --> G3[Vehicle Detection]
    G3 --> G4[Parking API]

    H --> H1[HTTP/MJPEG Stream]
    H1 --> H2[Real-time Viewing]
    H2 --> H3[Browser Display]

    F4 --> I[Detection Results]
    G4 --> I
    I --> J[oaDashboard Integration]

    style A fill:#3b82f6,color:#f8fafc
    style C fill:#f59e0b,color:#f8fafc
    style I fill:#10b981,color:#f8fafc
    style J fill:#10b981,color:#f8fafc
    style F fill:#10b981,color:#f8fafc
    style G fill:#10b981,color:#f8fafc
    style H fill:#10b981,color:#f8fafc
```

## Camera Permission Handling (macOS)

### macOS Camera Permission Flow

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#f59e0b',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[oaCamBridge Startup] --> B[Camera Initialization]
    B --> C{Camera Access Attempt}

    C -->|Permission Granted| D[Camera Successfully Opened]
    C -->|Permission Denied| E[Permission Error]

    D --> F[Start Frame Capture]
    F --> G[Service Active]

    E --> H{Access Method}

    H -->|Direct Terminal| I[Permission Dialog Appears]
    H -->|SSH Session| J[No Dialog Triggered]

    I --> K[User Clicks OK]
    K --> L[Permission Granted]
    L --> D

    J --> M[Permission Error Logged]
    M --> N[Manual Grant Required]

    N --> O[VNC/Direct Access Required]
    O --> P[Run in Terminal]
    P --> Q[Trigger Permission Dialog]
    Q --> K

    style A fill:#10b981,color:#f8fafc
    style G fill:#10b981,color:#f8fafc
    style C fill:#f59e0b,color:#f8fafc
    style H fill:#f59e0b,color:#f8fafc
    style E fill:#ef4444,color:#f8fafc
    style N fill:#ef4444,color:#f8fafc
```

### Permission Troubleshooting Workflow

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#f59e0b',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[Camera Access Issue] --> B[Check Error Message]
    B --> C{Error Type}

    C -->|Permission Denied| D[Check System Settings]
    C -->|Device Not Found| E[Check Camera Hardware]
    C -->|Resource Busy| F[Check Other Applications]

    D --> G[Open System Preferences]
    G --> H[Privacy & Security]
    H --> I[Camera Settings]
    I --> J{Terminal Enabled?}

    J -->|No| K[Enable Terminal Camera Access]
    K --> L[Restart oaCamBridge]
    L --> M[Test Camera Access]

    J -->|Yes| N[Reset Camera Permissions]
    N --> O[tccutil reset Camera]
    O --> P[Restart Terminal]
    P --> Q[Run oaCamBridge Again]
    Q --> R[Grant Permission When Prompted]

    E --> E1[Check Physical Connection]
    E1 --> E2[Check System Information]
    E2 --> E3[Verify Camera Recognition]
    E3 --> M

    F --> F1[Check Running Applications]
    F1 --> F2[Close Camera Apps]
    F2 --> F3[Restart Camera Service]
    F3 --> M

    M --> N1{Camera Working?}
    N1 -->|Yes| N2[Issue Resolved]
    N1 -->|No| N3[Advanced Troubleshooting]

    style A fill:#ef4444,color:#f8fafc
    style N2 fill:#10b981,color:#f8fafc
    style C fill:#f59e0b,color:#f8fafc
    style J fill:#f59e0b,color:#f8fafc
    style N1 fill:#f59e0b,color:#f8fafc
    style N3 fill:#ef4444,color:#f8fafc
```

## Performance and Reliability Patterns

### Frame Management and Storage

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#f59e0b',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[Frame Capture Thread] --> B[Frame Processing]
    B --> C[Frame Counter Increment]
    C --> D[Filename Generation]

    D --> E[Frame Format: img_XXXXXX.jpg]
    E --> F[File Write Operation]
    F --> G[Disk Storage: /tmp/webcam/]

    G --> H[Update Frame Registry]
    H --> I[Frame Available for AI Services]

    I --> J[Storage Monitoring]
    J --> K{Disk Space Check}

    K -->|Sufficient| L[Continue Capture]
    K -->|Low| M[Warning Logged]
    K -->|Critical| N[Stop New Frame Generation]

    M --> O[Cleanup Old Frames]
    O --> P[Free Disk Space]
    P --> L

    N --> Q[Alert System]
    Q --> R[Notify Administrators]
    R --> S[Manual Intervention Required]

    L --> T[Next Frame Capture]
    T --> A

    style A fill:#3b82f6,color:#f8fafc
    style G fill:#f59e0b,color:#f8fafc
    style I fill:#10b981,color:#f8fafc
    style K fill:#f59e0b,color:#f8fafc
    style N fill:#ef4444,color:#f8fafc
    style Q fill:#ef4444,color:#f8fafc
```

### Service Recovery and Error Handling

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#ef4444',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
stateDiagram-v2
    [*] --> ServiceStarting

    state ServiceStarting {
        [*] --> InitializeCamera
        InitializeCamera --> StartHTTPServer
        StartHTTPServer --> StartFrameCapture
        StartFrameCapture --> ServiceActive
    }

    ServiceActive --> CameraError: Camera Failure
    ServiceActive --> HTTPServerError: HTTP Server Issue
    ServiceActive --> StorageError: Disk Space Issue

    state CameraError {
        [*] --> LogError
        LogError --> AttemptReconnect
        AttemptReconnect --> ReconnectSuccess
        ReconnectSuccess --> ServiceActive: Success
        ReconnectSuccess --> CameraFailure: Failure
        CameraFailure --> WaitForManualRecovery
    }

    state HTTPServerError {
        [*] --> RestartServer
        RestartServer <<choice>> --> ServerStarted{Server Started?}
        ServerStarted -->|Yes| ServiceActive
        ServerStarted -->|No| ServerFailure
        ServerFailure --> WaitForManualRecovery
    }

    state StorageError {
        [*] --> CheckDiskSpace
        CheckDiskSpace <<choice>> --> SpaceAvailable{Space Available?}
        SpaceAvailable -->|Yes| CleanupFrames
        SpaceAvailable -->|No| StorageFull
        CleanupFrames --> ServiceActive
        StorageFull --> WaitForManualRecovery
    }

    ServiceActive --> ServiceStopped: Manual Stop
    WaitForManualRecovery --> ServiceStopped: Manual Intervention
    ServiceStopped --> [*]
```

## Configuration and Deployment

### Service Configuration Management

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[Configuration File: config.json] --> B[Configuration Validation]
    B --> C{Configuration Valid?}

    C -->|No| D[Load Default Values]
    D --> E[Log Configuration Errors]
    E --> F[Continue with Defaults]

    C -->|Yes| G[Apply Configuration]
    G --> H[Camera Settings]
    G --> I[HTTP Server Settings]
    G --> J[Frame Output Settings]

    H --> H1[Camera Index/Path]
    H --> H2[Resolution: 1280x720]
    H --> H3[Frame Rate: 10 fps]
    H --> H4[Quality: 95%]

    I --> I1[HTTP Port: 8086]
    I --> I2[Thread Pool Size]
    I --> I3[Client Timeout]
    I --> I4[CORS Settings]

    J --> J1[Frame Directory: /tmp/webcam/]
    J --> J2[Frame Format: JPEG]
    J --> J3[Frame FPS: 5 fps]
    J --> J4[No Cleanup Policy]

    F --> K[Service Initialization]
    H1 --> K
    H2 --> K
    H3 --> K
    H4 --> K
    I1 --> K
    I2 --> K
    I3 --> K
    I4 --> K
    J1 --> K
    J2 --> K
    J3 --> K
    J4 --> K

    K --> L[Service Ready]

    style A fill:#3b82f6,color:#f8fafc
    style L fill:#10b981,color:#f8fafc
    style C fill:#f59e0b,color:#f8fafc
    style H fill:#f59e0b,color:#f8fafc
    style I fill:#f59e0b,color:#f8fafc
    style J fill:#f59e0b,color:#f8fafc
```

### LaunchAgent Service Deployment

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[LaunchAgent Installation] --> B[Copy plist File]
    B --> C[~/Library/LaunchAgents/]
    C --> D[com.orangead.cambridge.plist]

    D --> E[Load LaunchAgent]
    E --> F[launchctl load]
    F --> G{Load Success?}

    G -->|No| H[Check plist Syntax]
    H --> I[Validate Paths]
    I --> J[Fix Configuration]
    J --> E

    G -->|Yes| K[Service Auto-Start]
    K --> L[Camera Initialization]
    L --> M[HTTP Server Start]
    M --> N[Frame Capture Active]

    N --> O[Service Monitoring]
    O --> P[Health Checks]
    P --> Q[Automatic Restart]

    Q --> R{Service Healthy?}
    R -->|No| S[Log Error]
    S --> T[Restart Service]
    T --> O
    R -->|Yes| U[Continue Monitoring]

    U --> V[Manual Control]
    V --> W[launchctl start/stop]
    W --> X[Service Management]

    style A fill:#10b981,color:#f8fafc
    style N fill:#10b981,color:#f8fafc
    style G fill:#f59e0b,color:#f8fafc
    style R fill:#f59e0b,color:#f8fafc
    style H fill:#ef4444,color:#f8fafc
    style S fill:#ef4444,color:#f8fafc
```

## Integration Testing and Validation

### End-to-End Testing Workflow

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
flowchart TD
    A[Test Suite Initiation] --> B[Service Health Check]
    B --> C{Service Running?}

    C -->|No| D[Start oaCamBridge]
    D --> E[Wait for Service Ready]
    E --> B

    C -->|Yes| F[Camera Access Test]
    F --> G{Camera Available?}

    G -->|No| H[Check Camera Permissions]
    H --> I[Grant Permissions]
    I --> F

    G -->|Yes| J[HTTP API Testing]

    J --> K[GET /status Test]
    K --> L[GET /frame Test]
    L --> M[GET /stream Test]

    K --> N{Status Response OK?}
    L --> O{Frame Response OK?}
    M --> P{Stream Response OK?}

    N -->|No| Q[Status Test Failed]
    O -->|No| R[Frame Test Failed]
    P -->|No| S[Stream Test Failed]

    Q --> T[Log Failure Details]
    R --> T
    S --> T

    N -->|Yes| U[Status Test Passed]
    O -->|Yes| V[Frame Test Passed]
    P -->|Yes| W[Stream Test Passed]

    U --> X[AI Service Integration Test]
    V --> X
    W --> X

    X --> Y[Frame File Generation Test]
    Y --> Z[AI Service Consumption Test]
    Z --> AA[End-to-End Validation]

    T --> BB[Test Suite Failed]
    AA --> CC[Test Suite Passed]

    style A fill:#3b82f6,color:#f8fafc
    style CC fill:#10b981,color:#f8fafc
    style BB fill:#ef4444,color:#f8fafc
    style C fill:#f59e0b,color:#f8fafc
    style G fill:#f59e0b,color:#f8fafc
    style N fill:#f59e0b,color:#f8fafc
    style O fill:#f59e0b,color:#f8fafc
    style P fill:#f59e0b,color:#f8fafc
```

### AI Service Integration Testing

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#4b5563',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#374151',
    'altSectionBkgColor': '#1f2937',
    'gridColor': '#4b5563',
    'secondaryColor': '#10b981',
    'secondaryTextColor': '#f8fafc',
    'tertiaryColor': '#3b82f6',
    'tertiaryTextColor': '#f8fafc',
    'background': '#111827',
    'fontFamily': 'monospace'
  }
}}%%
sequenceDiagram
    participant Test as Test Framework
    participant CamBridge as oaCamBridge
    participant Tracker as oaTracker
    participant Parking as oaParkingMonitor
    participant FileSystem as File System

    Test->>CamBridge: Start frame generation
    CamBridge->>FileSystem: Create test frames
    FileSystem-->>CamBridge: Frame files ready

    Test->>Tracker: Start detection polling
    loop Frame Processing Test
        Tracker->>FileSystem: Read latest frame
        FileSystem-->>Tracker: Frame data
        Tracker->>Tracker: Process frame
        Tracker->>Test: Detection results
        Test->>Test: Validate results
    end

    Test->>Parking: Request parking analysis
    Parking->>FileSystem: Get frame
    FileSystem-->>Parking: Frame data
    Parking->>Parking: Analyze parking
    Parking->>Test: Parking results
    Test->>Test: Validate parking analysis

    Test->>CamBridge: Validate stream quality
    CamBridge->>Test: Stream metrics
    Test->>Test: Check frame rates
    Test->>Test: Validate file outputs

    Test->>Test: Generate integration report
    Test->>Test: Validate end-to-end workflow
```

## Key Workflow Insights

### Architecture Strengths
- **Dual Output Pipeline**: Simultaneous streaming and file output
- **Service Isolation**: Independent AI service consumption
- **No Cleanup Policy**: Ensures frame availability for AI processing
- **Thread-Safe Operations**: Concurrent HTTP and frame processing

### Performance Characteristics
- **Frame Rate**: 10 fps capture, 5 fps file output
- **Resolution**: 1280x720 default, configurable
- **Latency**: < 100ms frame processing
- **Storage**: Sequential frame files, no automatic cleanup

### Integration Patterns
- **Polling Pattern**: oaTracker polls for new frames
- **Request-Response**: oaParkingMonitor requests snapshots
- **Streaming Pattern**: Web clients consume MJPEG streams
- **File-Based**: AI services read from filesystem

### Reliability Features
- **Error Recovery**: Automatic reconnection for camera issues
- **Permission Handling**: macOS camera permission management
- **Service Monitoring**: Health checks and automatic restart
- **Resource Management**: Disk space monitoring and alerts

This workflow documentation provides comprehensive coverage of oaCamBridge operations, integration patterns, and performance considerations for reliable camera streaming and AI service integration.