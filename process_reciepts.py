import os
import json
import base64
import hashlib
import shutil
import pandas as pd
from tqdm import tqdm
from dotenv import load_dotenv
from openai import OpenAI
from pdf2image import convert_from_path
from concurrent.futures import ThreadPoolExecutor
from io import BytesIO
import time
import re


load_dotenv()

client = OpenAI()
print("SCRIPT STARTED")
INPUT_DIR = r"C:\Users\terry\OneDrive\Restaurant Reciepts\Reciepts"
PROCESSED_DIR = r"C:\Users\terry\OneDrive\Restaurant Reciepts\Reciepts\processed"
OUTPUT_DIR = r"C:\Users\terry\OneDrive\Restaurant Reciepts\Reciepts\output"

BATCH_SIZE = 4


def hash_file(path):
    with open(path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def pdf_to_images(path):

    pages = convert_from_path(path, dpi=300)

    images = []

    for page in pages:

        buffer = BytesIO()
        page.save(buffer, format="PNG")

        images.append(base64.b64encode(buffer.getvalue()).decode())

    return images


def analyze_receipt(images):

    prompt = """
Extract EVERY line item from this receipt page.

Extract ALL items even if there are more than 100.
Do NOT summarize.

{
 "vendor":"",
 "date":"",
 "items":[
   {"name":"","price":0.00,"category":""}
 ]
}

Rules for category:
- "food" = edible items (meat, vegetables, drinks, ingredients)
- "non_food" = supplies, paper goods, chemicals, cleaning, utensils, equipment, etc.
"""

    image_inputs = []

    for img in images:
        image_inputs.append({
            "type": "input_image",
            "image_url": f"data:image/png;base64,{img}"
        })

    for attempt in range(3):

        try:

            response = client.responses.create(
                model="gpt-4.1-mini",
                input=[{
                    "role": "user",
                    "content": [{"type": "input_text", "text": prompt}] + image_inputs
                }]
            )

            time.sleep(2)

            return response.output_text

        except Exception as e:

            print("Retrying API call:", attempt+1)
            time.sleep(5)

    raise RuntimeError("API failed after retries")


def process_file(path):

    try:

        pages = convert_from_path(path, dpi=200)

        all_records = []

        for page in pages:

            buffer = BytesIO()
            page.save(buffer, format="PNG")

            img = base64.b64encode(buffer.getvalue()).decode()

            result = analyze_receipt([img])

            import re

            json_match = re.search(r"\{.*\}", result, re.S)

            if not json_match:
                continue

            data = json.loads(json_match.group())

            for item in data.get("items", []):

                all_records.append({
                    "vendor": data.get("vendor", ""),
                    "date": data.get("date", ""),
                    "item": item.get("name", ""),
                    "price": item.get("price", 0),
                    "category": item.get("category", "")
                })

        return all_records

    except Exception as e:

        print("Failed:", path, e)
        return None

def main():

    os.makedirs(PROCESSED_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    receipts = [
        os.path.join(INPUT_DIR, f)
        for f in os.listdir(INPUT_DIR)
        if f.lower().endswith(".pdf")
    ]

    if not receipts:
        print("No receipts found")
        return

    print(f"{len(receipts)} receipts found")

    records = []
    unreadable = []

    with ThreadPoolExecutor(max_workers=4) as executor:

        results = list(
            tqdm(
                executor.map(process_file, receipts),
                total=len(receipts)
            )
        )

    for file, result in zip(receipts, results):

        if result:

            records.extend(result)

            shutil.move(
                file,
                os.path.join(PROCESSED_DIR, os.path.basename(file))
            )

        else:

            unreadable.append(file)

    if not records:

        print("No items extracted")
        return

    df = pd.DataFrame(records)

    # normalize categories just in case AI returns capitalization differences
    df["category"] = df["category"].str.lower()

    from datetime import datetime
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    # split food vs non-food
    food_df = df[df["category"] == "food"]
    non_food_df = df[df["category"] == "non_food"]

    food_df.to_excel(
        os.path.join(OUTPUT_DIR, f"food_items_{timestamp}.xlsx"),
        index=False
    )

    non_food_df.to_excel(
        os.path.join(OUTPUT_DIR, f"non_food_items_{timestamp}.xlsx"),
        index=False
    )

    # full dataset export
    excel_path = os.path.join(OUTPUT_DIR, f"all_items_{timestamp}.xlsx")
    df.to_excel(excel_path, index=False)

    # QuickBooks export
    qb = pd.DataFrame({
        "Date": df["date"],
        "Vendor": df["vendor"],
        "Category": df["category"].map({
            "food": "Cost of Goods Sold",
            "non_food": "Supplies"
        }),
        "Description": df["item"],
        "Amount": df["price"]
    })

    qb.to_csv(
        os.path.join(OUTPUT_DIR, f"quickbooks_import_{timestamp}.csv"),
        index=False
    )

    with open(
        os.path.join(OUTPUT_DIR, "unreadable_receipts.txt"),
        "w"
    ) as f:

        for r in unreadable:
            f.write(r + "\n")

    print("\nProcessing complete")
    print("Items extracted:", len(df))
    print("Food items:", len(food_df))
    print("Non-food items:", len(non_food_df))
    print("Unreadable receipts:", len(unreadable))


if __name__ == "__main__":
    main()