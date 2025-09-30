# Pottery Catalog Mobile App - Design Requirements

## App Overview
Mobile-first pottery studio catalog for managing pottery items through their lifecycle stages:
- **Greenware** (unfired clay)
- **Bisque** (first firing)
- **Final** (glazed and final fired)

## Core User Workflows

### 1. Browse Items
- View all pottery items in an intuitive grid/list
- Quick visual overview with primary photo
- Filter by stage, clay type, location
- Search functionality

### 2. Item Details
- Comprehensive view of individual pottery piece
- Photo gallery showcasing different stages
- Technical details (measurements, clay type, glaze)
- Notes and location information
- Edit/delete actions

### 3. Photo Management
- Upload photos for specific stages
- Intuitive stage-based organization
- Photo capture with camera integration
- Photo viewing and management

### 4. Item Management
- Create new pottery items
- Edit existing items
- Form for all item properties
- Validation and error handling

## Key Mobile UX Requirements

### Touch-Friendly Design
- Large touch targets (minimum 44px)
- Swipe gestures for photo galleries
- Pull-to-refresh on lists
- Thumb-friendly navigation

### Visual Hierarchy
- Photos as primary content
- Clear typography scale
- Consistent spacing system
- Visual stage indicators

### Pottery Studio Aesthetic
- Earthy, natural color palette
- Clean, modern interface
- Professional but approachable
- Focus on craftsmanship

### Technical Constraints
- Flutter mobile app
- FastAPI backend with Firestore
- Google Cloud Storage for photos
- JWT authentication
- Offline-capable (future consideration)

## Current Implementation Status
- Basic Flutter app with Riverpod state management
- Simple list view with cards
- Basic CRUD operations
- Photo upload capability
- Material Design 3 components
