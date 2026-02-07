with open('docs/index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the stray corrupted quotes after praying hands emoji
# The emoji 🙏 followed by corrupted characters
content = content.replace('\U0001f64f\u0027\u0153', '\U0001f64f')  # 🙏'œ -> 🙏
content = content.replace('\U0001f64f\u0027\u00ac', '\U0001f64f')  # 🙏'¬ -> 🙏

with open('docs/index.html', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed all remaining emoji issues!')
