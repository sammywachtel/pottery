# Pottery Catalog App - Design System

## Color Palette (OKLCH Color Space)

### Primary Colors - Ceramic Earth Tones
```css
/* Primary - Warm ceramic brown */
--clay-primary: oklch(55% 0.08 45);        /* #8B6F47 - Warm clay brown */
--clay-primary-light: oklch(70% 0.06 45);  /* #A89B7A - Light clay */
--clay-primary-dark: oklch(40% 0.10 45);   /* #5D4A32 - Dark clay */

/* Secondary - Kiln fire orange */
--kiln-secondary: oklch(65% 0.15 35);      /* #C8956D - Kiln fire orange */
--kiln-secondary-light: oklch(75% 0.12 35); /* #D4AE8A - Light kiln */
--kiln-secondary-dark: oklch(50% 0.18 35);  /* #9E6B3A - Dark kiln */
```

### Stage Colors - Pottery Process
```css
/* Greenware - Fresh clay green */
--greenware: oklch(60% 0.12 140);         /* #7BA05B - Fresh clay green */
--greenware-light: oklch(75% 0.10 140);   /* #A3C184 - Light greenware */
--greenware-dark: oklch(45% 0.15 140);    /* #567139 - Dark greenware */

/* Bisque - Ceramic tan */
--bisque: oklch(70% 0.08 65);             /* #B5A688 - Bisque tan */
--bisque-light: oklch(80% 0.06 65);       /* #CCC1A8 - Light bisque */
--bisque-dark: oklch(55% 0.10 65);        /* #8B7E5E - Dark bisque */

/* Final - Glazed ceramic blue */
--final: oklch(55% 0.10 240);             /* #6B7BA8 - Glazed blue */
--final-light: oklch(70% 0.08 240);       /* #8FA1C4 - Light final */
--final-dark: oklch(40% 0.12 240);        /* #485A84 - Dark final */
```

### Neutral Colors - Natural Clay Tones
```css
/* Surface colors */
--surface: oklch(98% 0.005 45);           /* #FEFCFA - Warm white */
--surface-variant: oklch(92% 0.01 45);    /* #F0EDE8 - Light clay */
--surface-container: oklch(95% 0.008 45); /* #F8F5F1 - Container */

/* Text colors */
--on-surface: oklch(20% 0.02 45);         /* #322C24 - Dark clay text */
--on-surface-variant: oklch(45% 0.03 45); /* #6B5F52 - Medium clay text */
--outline: oklch(65% 0.02 45);            /* #A39A8D - Subtle outline */
```

### Semantic Colors
```css
/* Success - Firing success green */
--success: oklch(60% 0.15 140);           /* #7BA05B */
--success-container: oklch(90% 0.06 140); /* #E8F4E0 */

/* Warning - Kiln caution amber */
--warning: oklch(70% 0.15 75);            /* #D4B86A */
--warning-container: oklch(92% 0.08 75);  /* #F7F0E1 */

/* Error - Crack red */
--error: oklch(55% 0.15 25);              /* #C4705C */
--error-container: oklch(90% 0.06 25);    /* #F4E6E2 */
```

## Typography Scale

### Font Stack
```css
/* Primary font - Clean, professional */
font-family: 'Inter', 'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;

/* Monospace - For measurements */
font-family-mono: 'JetBrains Mono', 'SF Mono', 'Monaco', 'Cascadia Code', monospace;
```

### Type Scale (Pottery-themed naming)
```css
/* Display - For hero titles */
--type-kiln: {
  font-size: 2.5rem;    /* 40px */
  font-weight: 700;
  line-height: 1.2;
  letter-spacing: -0.02em;
}

/* Headlines - For section titles */
--type-wheel: {
  font-size: 2rem;      /* 32px */
  font-weight: 600;
  line-height: 1.25;
  letter-spacing: -0.01em;
}

--type-clay: {
  font-size: 1.5rem;    /* 24px */
  font-weight: 600;
  line-height: 1.3;
}

/* Body text */
--type-ceramic: {
  font-size: 1rem;      /* 16px */
  font-weight: 400;
  line-height: 1.5;
}

--type-glaze: {
  font-size: 0.875rem;  /* 14px */
  font-weight: 400;
  line-height: 1.4;
}

/* Labels and captions */
--type-slip: {
  font-size: 0.75rem;   /* 12px */
  font-weight: 500;
  line-height: 1.33;
  letter-spacing: 0.01em;
  text-transform: uppercase;
}
```

## Spacing System (Clay Grid)

### Base Unit: 4px (Ceramic Pixel)
```css
/* Spacing scale */
--space-1: 0.25rem;   /* 4px - Slip thin */
--space-2: 0.5rem;    /* 8px - Clay fine */
--space-3: 0.75rem;   /* 12px - Glaze medium */
--space-4: 1rem;      /* 16px - Ceramic standard */
--space-5: 1.25rem;   /* 20px - Wheel comfortable */
--space-6: 1.5rem;    /* 24px - Kiln spacious */
--space-8: 2rem;      /* 32px - Studio generous */
--space-10: 2.5rem;   /* 40px - Gallery wide */
--space-12: 3rem;     /* 48px - Showroom extra */
--space-16: 4rem;     /* 64px - Exhibition vast */
```

### Component Spacing
```css
/* Card padding */
--card-padding: var(--space-4) var(--space-5);

/* Section spacing */
--section-gap: var(--space-8);

/* Form spacing */
--form-field-gap: var(--space-4);
--form-section-gap: var(--space-6);
```

## Border Radius (Ceramic Curves)

```css
--radius-sm: 0.375rem;    /* 6px - Subtle curve */
--radius-md: 0.5rem;      /* 8px - Standard ceramic */
--radius-lg: 0.75rem;     /* 12px - Generous curve */
--radius-xl: 1rem;        /* 16px - Bowl-like */
--radius-full: 9999px;    /* Full circle - Pottery wheel */
```

## Elevation (Kiln Levels)

```css
/* Shadow tokens */
--shadow-slip: 0 1px 3px oklch(0% 0 0 / 0.12);
--shadow-clay: 0 2px 6px oklch(0% 0 0 / 0.16);
--shadow-ceramic: 0 4px 12px oklch(0% 0 0 / 0.15);
--shadow-kiln: 0 8px 24px oklch(0% 0 0 / 0.12);
--shadow-gallery: 0 16px 48px oklch(0% 0 0 / 0.10);
```

## Component Tokens

### Buttons
```css
/* Primary button */
.btn-primary {
  background: var(--clay-primary);
  color: var(--surface);
  padding: var(--space-3) var(--space-5);
  border-radius: var(--radius-md);
  font: var(--type-ceramic);
  font-weight: 500;
  box-shadow: var(--shadow-clay);
}

.btn-primary:hover {
  background: var(--clay-primary-dark);
  box-shadow: var(--shadow-ceramic);
}
```

### Cards
```css
.card {
  background: var(--surface);
  border-radius: var(--radius-lg);
  padding: var(--card-padding);
  box-shadow: var(--shadow-clay);
  border: 1px solid var(--outline);
}

.card-photo {
  aspect-ratio: 1;
  border-radius: var(--radius-md);
  overflow: hidden;
  background: var(--surface-variant);
}
```

### Stage Indicators
```css
.stage-greenware {
  background: var(--greenware);
  color: var(--surface);
}

.stage-bisque {
  background: var(--bisque);
  color: var(--on-surface);
}

.stage-final {
  background: var(--final);
  color: var(--surface);
}

.stage-badge {
  padding: var(--space-1) var(--space-2);
  border-radius: var(--radius-full);
  font: var(--type-slip);
}
```

## Mobile Touch Targets

```css
/* Minimum touch target */
--touch-target-min: 44px;

/* Interactive elements */
.touch-target {
  min-height: var(--touch-target-min);
  min-width: var(--touch-target-min);
}

/* Thumb-friendly zones */
.thumb-zone {
  margin-bottom: 6rem; /* Bottom navigation clearance */
}
```

## Animation Tokens

```css
/* Timing functions */
--ease-ceramic: cubic-bezier(0.25, 0.46, 0.45, 0.94); /* Smooth ceramic */
--ease-clay: cubic-bezier(0.175, 0.885, 0.32, 1.275);  /* Clay bounce */
--ease-kiln: cubic-bezier(0.55, 0.055, 0.675, 0.19);  /* Kiln fire */

/* Durations */
--duration-quick: 150ms;
--duration-smooth: 250ms;
--duration-gentle: 400ms;

/* Standard transitions */
--transition-color: color var(--duration-smooth) var(--ease-ceramic);
--transition-transform: transform var(--duration-smooth) var(--ease-clay);
--transition-all: all var(--duration-smooth) var(--ease-ceramic);
```

## Accessibility

### WCAG Compliance
- Contrast ratio minimum: 4.5:1 for normal text
- Contrast ratio minimum: 3:1 for large text
- Focus indicators with 2px outline
- Touch targets minimum 44px

### Screen Reader Labels
- Stage indicators with descriptive text
- Photo alt text with stage and item information
- Form labels properly associated

This design system provides a cohesive foundation for the pottery catalog app, emphasizing the natural, crafted aesthetic while maintaining modern usability standards.
