#!/usr/bin/env python3
import sys

with open('docs/index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the corrupted characters
content = content.replace('\u1f64f\u0027\u0153', '\u1f64f ')  # 🙏'œ -> 🙏 
content = content.replace('\u1f64f\u0027\u00ac', '\u1f64f ')  # 🙏'¬ -> 🙏 

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(content)

sys.exit(0)
