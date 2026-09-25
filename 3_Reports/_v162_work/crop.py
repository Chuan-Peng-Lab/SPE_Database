# -*- coding: utf-8 -*-
"""Crop and save regions of an image for close inspection."""
import sys
from PIL import Image

src = sys.argv[1]
out = sys.argv[2]
box = [float(x) for x in sys.argv[3:7]]  # fractional l, t, r, b
im = Image.open(src).convert('RGB')
W, H = im.size
l, t, r, b = box
crop = im.crop((int(l * W), int(t * H), int(r * W), int(b * H)))
# upscale small crops for legibility
if max(crop.size) < 1600:
    f = min(3, 1600 // max(crop.size) + 1)
    crop = crop.resize((crop.width * f, crop.height * f), Image.LANCZOS)
crop.save(out)
print(out, crop.size, 'from', im.size)
