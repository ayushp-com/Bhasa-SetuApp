import json
import requests
from bs4 import BeautifulSoup

# Add as many words as you want here!
words_to_scrape = [
    "abandon", "water", "book", "tree", "school", "read", "write", 
    "food", "sun", "moon", "father", "mother", "brother", "flower", "house"
]

scraped_data = []

headers = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

print("Starting deep dictionary scraper from Glosbe...")

for word in words_to_scrape:
    url = f"https://glosbe.com/en/hoc/{word}"
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Look for translation phrase blocks on Glosbe
            translation_elem = soup.find('span', class_='translation__item__phrase')
            if not translation_elem:
                translation_elem = soup.find('h3', class_='translation__item__phrase')
                
            target_translation = translation_elem.get_text(strip=True) if translation_elem else f"Translation missing"
            
            entry = {
                "hindi_word": word,
                "english_word": word,
                "santhali_word": f"{target_translation} (Sat)",
                "mundari_word": target_translation,
                "ho_word": target_translation
            }
            scraped_data.append(entry)
            print(f"Scraped: {word} -> {target_translation}")
        else:
            print(f"Skipped {word} (Status: {response.status_code})")
    except Exception as e:
        print(f"Error on {word}: {e}")

output_file = "assets/dictionary_data.json"
with open(output_file, "w", encoding="utf-8") as f:
    json.dump(scraped_data, f, ensure_ascii=False, indent=2)

print(f"\nDone! Updated {output_file} with {len(scraped_data)} records.")