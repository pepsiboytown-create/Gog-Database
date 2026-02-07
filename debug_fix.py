import codecs

filepath = r'docs/index.html'

# Read the file in binary to understand the exact bytes
with open(filepath, 'rb') as f:
    content_bytes = f.read()

# Decode as UTF-8
content = content_bytes.decode('utf-8')

# Display what we're looking for
print("Looking for patterns...")
print(repr(content[5750:5850]))

# Try different replacements
if '🙏' in content:
    print("Found praying hands emoji")
    # Find the exact problematic bytes
    idx = content.find('🙏')
    print(f"Context around emoji: {repr(content[idx:idx+10])}")

# Replace all X_EMOJI_X_encoded variants
for i in range(len(content)-2):
    if content[i:i+1] == '🙏':
        next_chars = repr(content[i:i+4])
        if '\u0027' in content[i:i+4]:  # apostrophe
            print(f"Found emoji followed by apostrophe at {i}: {next_chars}")

# Do the replacements
content = content.replace('\U0001f64f\u0027\u0153', '\U0001f64f')  # 🙏'œ
content = content.replace('\U0001f64f\u0027\u00ac', '\U0001f64f')  # 🙏'¬  

# Write back
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed!")
