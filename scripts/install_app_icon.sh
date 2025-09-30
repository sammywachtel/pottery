#!/bin/bash

# Install Pottery App Icon
# Usage: ./scripts/install_app_icon.sh <path_to_icon.png>

set -e

SOURCE_IMAGE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "$SCRIPT_DIR/../frontend" && pwd)"

# Check if source image is provided
if [ -z "$SOURCE_IMAGE" ]; then
    echo "❌ Error: No image file provided"
    echo ""
    echo "Usage: $0 <path_to_icon.png>"
    echo ""
    echo "Example:"
    echo "  $0 ~/Downloads/pottery_icon.png"
    exit 1
fi

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Error: Image file not found: $SOURCE_IMAGE"
    exit 1
fi

echo "🎨 Installing Pottery Studio app icon..."
echo ""

# Get source image info
echo "📁 Source image: $SOURCE_IMAGE"
IMAGE_INFO=$(sips -g pixelWidth -g pixelHeight "$SOURCE_IMAGE" 2>/dev/null | grep -E 'pixelWidth|pixelHeight')
echo "📐 $IMAGE_INFO"
echo ""

# Create Android icons
echo "🤖 Creating Android app launcher icons..."

create_android_icon() {
    local folder="$1"
    local size="$2"
    local output_dir="${FRONTEND_DIR}/android/app/src/main/res/${folder}"
    local output_file="${output_dir}/ic_launcher.png"

    printf "   [%-15s] %3dx%3d ... " "$folder" "$size" "$size"

    sips -z ${size} ${size} "$SOURCE_IMAGE" --out "$output_file" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        printf "✅\n"
        return 0
    else
        printf "❌ FAILED\n"
        return 1
    fi
}

# Android icon sizes
create_android_icon "mipmap-mdpi" 48
create_android_icon "mipmap-hdpi" 72
create_android_icon "mipmap-xhdpi" 96
create_android_icon "mipmap-xxhdpi" 144
create_android_icon "mipmap-xxxhdpi" 192

echo ""

# Create Google Play Store icon (512x512)
echo "🏪 Creating Google Play Store icon (512x512)..."
store_icon="${FRONTEND_DIR}/android/app/src/main/res/pottery_icon_512.png"
sips -z 512 512 "$SOURCE_IMAGE" --out "$store_icon" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "   ✅ Created: pottery_icon_512.png"
else
    echo "   ❌ Failed to create store icon"
    exit 1
fi

echo ""

# Create iOS/macOS icons
echo "🍎 Creating iOS/macOS app icons..."

create_ios_icon() {
    local icon_name="$1"
    local size="$2"
    local ios_icon_dir="${FRONTEND_DIR}/macos/Runner/Assets.xcassets/AppIcon.appiconset"
    local output_file="${ios_icon_dir}/${icon_name}.png"

    printf "   [%-15s] %4dx%4d ... " "$icon_name" "$size" "$size"

    sips -z ${size} ${size} "$SOURCE_IMAGE" --out "$output_file" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        printf "✅\n"
        return 0
    else
        printf "❌ FAILED\n"
        return 1
    fi
}

# iOS/macOS icon sizes
create_ios_icon "app_icon_16" 16
create_ios_icon "app_icon_32" 32
create_ios_icon "app_icon_64" 64
create_ios_icon "app_icon_128" 128
create_ios_icon "app_icon_256" 256
create_ios_icon "app_icon_512" 512
create_ios_icon "app_icon_1024" 1024

echo ""
echo "✨ Icon installation complete!"
echo ""
echo "📋 Summary:"
echo "   ✅ Android launcher icons: 5 sizes (48px to 192px)"
echo "   ✅ Google Play Store icon: 512x512px"
echo "   ✅ iOS/macOS icons: 7 sizes (16px to 1024px)"
echo ""
echo "📁 Locations:"
echo "   - Android: ${FRONTEND_DIR}/android/app/src/main/res/mipmap-*/"
echo "   - iOS/macOS: ${FRONTEND_DIR}/macos/Runner/Assets.xcassets/AppIcon.appiconset/"
echo "   - Store: ${FRONTEND_DIR}/android/app/src/main/res/pottery_icon_512.png"
echo ""
echo "🚀 Next steps:"
echo "   1. Build and test the app to see the new icon"
echo "   2. Upload pottery_icon_512.png to Google Play Console"
