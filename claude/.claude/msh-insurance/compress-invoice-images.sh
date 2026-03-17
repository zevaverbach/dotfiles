#!/bin/bash
# Compress images in a single invoice folder and combine into PDF if multiple images
# Usage: compress-invoice-images.sh <invoice-directory>

if [ $# -eq 0 ]; then
  echo "Usage: $0 <invoice-directory>"
  echo "Example: $0 ~/Downloads/bills/received,\ paid/12039295"
  exit 1
fi

invoice_dir="$1"

if [ ! -d "$invoice_dir" ]; then
  echo "Error: Directory '$invoice_dir' does not exist"
  exit 1
fi

cd "$invoice_dir" || exit 1
invoice_id=$(basename "$invoice_dir")

# Create originals folder if needed
originals_dir="originals"

shopt -s nullglob
compressed_count=0
quality=70

# Compress images
for img in *.jpeg *.jpg *.JPEG *.JPG; do
  [ -f "$img" ] || continue

  # Skip already compressed images
  [[ "$img" == *"_compressed."* ]] && continue

  # Check if compressed version already exists
  compressed_name="${img%.*}_compressed.${img##*.}"
  [ -f "$compressed_name" ] && continue

  size=$(stat -f%z "$img" 2>/dev/null || stat -c%s "$img" 2>/dev/null)
  if [ $size -gt 3145728 ]; then
    echo "Compressing $img ($(($size/1048576))MB)..."
    sips -s format jpeg -s formatOptions $quality "$img" --out "$compressed_name"

    # Create originals folder if this is the first compression
    if [ $compressed_count -eq 0 ]; then
      mkdir -p "$originals_dir"
    fi

    # Move original to originals folder
    mv "$img" "$originals_dir/"
    echo "  → Moved original to $originals_dir/"
    ((compressed_count++))
  fi
done

# Count compressed images
compressed_images=(*.jpeg *_compressed.jpeg *.jpg *_compressed.jpg *.JPEG *_compressed.JPEG *.JPG *_compressed.JPG)
image_count=0
for img in "${compressed_images[@]}"; do
  [ -f "$img" ] && ((image_count++))
done

# If multiple images, combine into PDF
if [ $image_count -gt 1 ]; then
  echo ""
  echo "Found $image_count images, combining into PDF..."

  # Create PDF using Python with progressive quality reduction
  python3 <<EOF
from PIL import Image
import os

# Get all compressed images
images = sorted([f for f in os.listdir('.') if f.endswith('.jpeg') or f.endswith('.jpg') or f.endswith('.JPEG') or f.endswith('.JPG')])
images = [img for img in images if os.path.isfile(img)]

if len(images) > 0:
    pdf_name = "${invoice_id}.pdf".replace(" ", "_")
    max_size = 3145728  # 3MB

    # Try progressively lower quality until PDF fits
    for pdf_quality in [85, 75, 65, 55, 45, 35, 25]:
        print(f"Trying PDF quality {pdf_quality}%...")

        # Open all images fresh each time
        img_objects = [Image.open(img) for img in images]

        # Convert to RGB if needed
        img_objects = [img.convert('RGB') if img.mode != 'RGB' else img for img in img_objects]

        # Save as PDF
        img_objects[0].save(pdf_name, save_all=True, append_images=img_objects[1:], quality=pdf_quality)

        # Check PDF size
        pdf_size = os.path.getsize(pdf_name)
        print(f"  PDF size: {pdf_size / 1048576:.2f}MB")

        if pdf_size <= max_size:
            print(f"✓ PDF fits at {pdf_quality}% quality!")
            # Remove individual compressed images
            for img in images:
                os.remove(img)
                print(f"  Removed: {img}")
            exit(0)

    # If we get here, even 25% quality is too large
    print("✗ Cannot create PDF under 3MB even at 25% quality")
    print("  Falling back to individual compressed images")
    os.remove(pdf_name)
    exit(1)
EOF

  if [ $? -eq 0 ]; then
    echo "✓ Successfully created PDF under 3MB"
  else
    echo "⚠ Keeping individual compressed images (PDF would be too large)"
  fi
fi

shopt -u nullglob

if [ $compressed_count -eq 0 ]; then
  echo "No images needed compression in $invoice_dir"
else
  echo "Compressed $compressed_count image(s) in $invoice_dir"
fi
