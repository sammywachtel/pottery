# Pottery Catalog Mobile App - Wireframes

## Navigation Architecture

```
┌─────────────────────────┐
│    POTTERY CATALOG      │
│                         │
├─────────────────────────┤
│  [Home] [Search] [+]    │ ← Top Navigation
│                         │
│     MAIN CONTENT        │
│                         │
│                         │
└─────────────────────────┘
```

## Screen 1: Items List/Grid (Home)

```
┌─────────────────────────────┐
│ ← Pottery Catalog    🔍 ⚙️  │
├─────────────────────────────┤
│                             │
│ ┌─── Search & Filters ────┐ │
│ │ [🔍 Search pottery...]   │ │
│ │ [All] [Greenware] [Bisque] │ │
│ └─────────────────────────┘ │
│                             │
│ ┌───┬───┐ ┌───┬───┐        │
│ │ ■ │ ■ │ │ ■ │ ■ │        │ ← Photo Grid
│ │G/B│F  │ │G  │B/F│        │   Stage indicators
│ └───┴───┘ └───┴───┘        │
│ Vase #1   Bowl #2          │
│                             │
│ ┌───┬───┐ ┌───┬───┐        │
│ │ ■ │   │ │ ■ │ ■ │        │
│ │G  │   │ │G/B│F  │        │
│ └───┴───┘ └───┴───┘        │
│ Mug #3    Plate #4         │
│                             │
│               ┌─────┐       │
│               │  +  │       │ ← FAB New Item
│               └─────┘       │
└─────────────────────────────┘

Legend: G=Greenware, B=Bisque, F=Final
```

## Screen 2: Item Detail View

```
┌─────────────────────────────┐
│ ← Vase #1           ⋯ Edit  │
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │     [Photo Gallery]     │ │ ← Swipeable gallery
│ │    ● ○ ○  (3 photos)    │ │   Stage indicators
│ │   G   B   F             │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─── Item Details ───────┐  │
│ │ 📋 Tall Ceramic Vase    │  │
│ │ 🏺 Stoneware Clay       │  │
│ │ 🎨 Celadon Glaze        │  │
│ │ 📍 Shelf A-3            │  │
│ │ 📅 Created Mar 15, 2024 │  │
│ └─────────────────────────┘  │
│                             │
│ ┌─── Measurements ───────┐  │
│ │ Greenware: H:12" W:6"   │  │
│ │ Bisque:    H:11" W:5.5" │  │
│ │ Final:     H:11" W:5.5" │  │
│ └─────────────────────────┘  │
│                             │
│ ┌─── Notes ─────────────┐   │
│ │ Beautiful piece with    │  │
│ │ subtle texture work...  │  │
│ └─────────────────────────┘  │
│                             │
│ [📷 Add Photos] [✏️ Edit]    │
└─────────────────────────────┘
```

## Screen 3: Photo Management

```
┌─────────────────────────────┐
│ ← Add Photos to Vase #1     │
├─────────────────────────────┤
│                             │
│ ┌─── Select Stage ───────┐  │
│ │ ●[Greenware] ○[Bisque]  │  │
│ │      ○[Final]           │  │
│ └─────────────────────────┘  │
│                             │
│ ┌─── Current Photos ─────┐  │
│ │ Greenware (2 photos)    │  │
│ │ ┌───┐ ┌───┐ ┌─+─┐      │  │
│ │ │ ■ │ │ ■ │ │ + │      │  │
│ │ │   │ │   │ │   │      │  │
│ │ └───┘ └───┘ └───┘      │  │
│ └─────────────────────────┘  │
│                             │
│ ┌─── Camera Actions ─────┐  │
│ │                         │  │
│ │   📷                    │  │
│ │ [Take Photo]            │  │
│ │                         │  │
│ │   📁                    │  │
│ │ [Choose from Gallery]   │  │
│ │                         │  │
│ └─────────────────────────┘  │
│                             │
│            [Done]            │
└─────────────────────────────┘
```

## Screen 4: Item Form (Create/Edit)

```
┌─────────────────────────────┐
│ ← New Pottery Item   [Save] │
├─────────────────────────────┤
│                             │
│ ┌─── Basic Info ─────────┐  │
│ │ Name                    │  │
│ │ [Ceramic Vase ____]     │  │
│ │                         │  │
│ │ Clay Type               │  │
│ │ [Stoneware ▼]           │  │
│ │                         │  │
│ │ Glaze (optional)        │  │
│ │ [Celadon ______]        │  │
│ │                         │  │
│ │ Location                │  │
│ │ [Shelf A-3 ____]        │  │
│ └─────────────────────────┘  │
│                             │
│ ┌─── Measurements ───────┐  │
│ │ Greenware Dimensions    │  │
│ │ H: [12] W: [6] D: [6]   │  │
│ │                         │  │
│ │ Bisque Dimensions       │  │
│ │ H: [__] W: [__] D: [__] │  │
│ │                         │  │
│ │ Final Dimensions        │  │
│ │ H: [__] W: [__] D: [__] │  │
│ └─────────────────────────┘  │
│                             │
│ ┌─── Notes ─────────────┐   │
│ │ [Additional notes...  ] │   │
│ │ [                   ] │   │
│ └─────────────────────────┘  │
│                             │
│     [Cancel]    [Save]      │
└─────────────────────────────┘
```

## Navigation Flow

```
Items List ←→ Item Detail ←→ Photo Manager
     ↓              ↓
   Item Form    Item Form (Edit)
```

## Key Design Principles

1. **Photo-First Design**: Visual content takes priority
2. **Stage Indicators**: Clear visual indicators for pottery stages (G/B/F)
3. **Touch Targets**: All interactive elements 44px+ minimum
4. **Thumb Navigation**: Important actions within thumb reach
5. **Visual Hierarchy**: Typography and spacing guide attention
6. **Consistent Patterns**: Repeated UI patterns across screens

## Mobile Interactions

- **Swipe**: Photo galleries, stage switching
- **Pull-to-refresh**: Items list updates
- **Long press**: Context menus, item selection
- **Tap**: Primary actions, navigation
- **Floating Action Button**: Quick access to new item creation
