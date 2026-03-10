# Storyve

**Storyve** is an AI-powered reading companion that **generates visuals of characters, locations, and key scenes** as users read. It provides an immersive reading experience by allowing users to **see their story come alive** while maintaining **consistent visuals across a book or series**.  

---

## Table of Contents

- [Features](#features)  
- [User Flow](#user-flow)  
- [Future Features](#future-features)  
- [Tech Stack](#tech-stack)  

---

## Features

- **Real-Time Scene Visualization**: Automatically generate images for the passage the user is currently reading.  
- **Character and Location Consistency**: Maintain consistent visuals across the book, series, and globally for all users.  
- **Visual Gallery**: Browse previous images and view an appendix of all characters and locations encountered so far.  
- **Customizable Layouts**: Adjust the position and style of visuals alongside reading settings (themes, fonts, etc.).  
- **Series-Wide Continuity**: Characters and locations retain their appearance across multiple books in a series.  
- **Dark/Light Mode**: Visuals adapt to match the reading theme.  

---

## User Flow

1. **Login**: User logs into the dashboard.  
2. **Dashboard Overview**: Displays books currently being read with buttons for:
   - Browse Books  
   - Add Books  
   - Profile  
   - Past Books  
3. **Adding a Book**: User searches for a book by title, author, or ISBN.  
4. **Start Reading**: Select a book to open the reading interface.  
5. **Reading Interface**: View book content with standard reading settings.  
6. **View Visuals**: Toggle AI-generated images for the current passage via the settings menu.  
7. **Layout Settings**: Customize visual layout in the same settings menu.  

---

## Future Features
  
- **Series-Wide Continuity**: Characters and locations maintain consistent visuals across multiple books.  
- **Dark/Light Mode for Visuals**: Match the reading theme.  

---

## Tech Stack

| Layer                   | Technology / Tools                                    | Purpose / Notes |
|-------------------------|-------------------------------------------------------|----------------|
| Frontend (iOS App)      | Swift + SwiftUI                                       | Native iOS UI for reading interface, galleries, overlays |
| Async Handling          | Combine / async-await                                  | Smooth background updates and network calls |
| Local Storage (Optional)| CoreData / Realm                                      | Cache reading progress and images locally |
| Networking              | URLSession / Alamofire                                 | Communicate with backend APIs |
| Backend API             | FastAPI (Python)                                      | Handles scene detection, AI requests, user/book management |
| Background Tasks        | Celery + Redis                                        | Asynchronous image generation and lookahead scene processing |
| Database                | PostgreSQL / Supabase                                 | Store users, books, reading progress, scene fingerprints, metadata |
| Image Storage           | S3 / Supabase Storage                                 | Stores generated visuals and serves via CDN |
| Scene Detection AI      | GPT-4 API                                             | Analyzes book text to detect scenes, characters, and locations |
| Image Generation AI     | Stable Diffusion API / Nano Banana (prototype)        | Generates visuals for scenes and characters |
| Caching / CDN           | Device cache + Cloud CDN                               | Fast image delivery to users |
| Optional Realtime Updates| WebSockets / Push Notifications                        | Notify frontend when lookahead images are ready |

## Architecture Diagram

```mermaid
flowchart TD

A[User] --> B[Frontend Reader App]

B --> C[Backend API]

C --> D[User Service]
C --> E[Book Service]
C --> F[Visual Generation Service]

D --> G[(PostgreSQL / Supabase Database)]
E --> G

F --> H[Text Analysis AI]
H --> I[Prompt Builder]
I --> J[Image Generation Model]

J --> K[Image Storage]
K --> L[(Visual Metadata Database)]

L --> C
G --> C
C --> B
