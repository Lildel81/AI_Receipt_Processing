# AI Receipt Processor

## Overview

The **AI Receipt Processor** is a Python automation tool that converts scanned PDF receipts into structured accounting data using AI.

The script reads receipt PDFs, converts each page into an image, sends the images to an AI model for interpretation, and extracts all line items into structured data. The output is automatically formatted for **Excel analysis and QuickBooks imports**, while also separating **food vs non-food purchases** for tax and accounting purposes.

This tool was designed to automate the tedious process of manually entering receipt data for restaurants or small businesses.

Key capabilities include:

* Extract **every line item from multi-page receipts**
* Automatically classify items as **food or non-food**
* Export accounting-friendly datasets
* Generate **QuickBooks import files**
* Archive processed receipts
* Log unreadable receipts
* Process batches of receipts automatically

The script is especially useful for businesses that frequently purchase supplies from places like:

* Restaurant Depot
* Costco
* Walmart
* Food distributors
* Wholesale suppliers

Instead of manually entering receipts, users can simply **drop scanned PDFs into a folder and run the script**.

---

# Features

### AI-Based Receipt Parsing

Uses OpenAI's vision models to read scanned receipts and extract structured data.

### Multi-Page Receipt Support

Many scanned PDFs contain multiple receipt pages. The processor automatically converts each page to an image and analyzes them individually.

### Automatic Categorization

Each item is categorized into:

* **food** – edible items such as meat, produce, beverages, ingredients
* **non_food** – supplies, chemicals, paper goods, cleaning products, equipment

This separation helps with **tax reporting and cost-of-goods tracking**.

### Parallel Processing

Receipts are processed concurrently using Python threading for improved performance.

### Automatic File Management

Processed receipts are automatically moved to an archive folder.

### Accounting Outputs

The script produces:

* full item dataset
* food-only dataset
* non-food dataset
* QuickBooks import file

---

# Directory Structure

```
Restaurant Receipts/
│
├── AI_Workplace/
│   ├── process_reciepts.py
│   ├── receipt_env/          (Python virtual environment)
│
└── Reciepts/
    ├── Scan_1.pdf
    ├── Scan_2.pdf
    ├── ...
    │
    ├── processed/            (automatically created)
    └── output/               (automatically created)
```

---

# Input Folder

```
Reciepts/
```

Place all receipt PDFs here.

Requirements:

* Files must be **PDF**
* Receipts should be **scanned clearly**
* Multi-page PDFs are supported

---

# Processed Folder

```
Reciepts/processed/
```

After successful processing, receipts are moved here to prevent duplicate processing.

---

# Output Folder

```
Reciepts/output/
```

The script generates several output files:

### 1. Full Dataset

```
all_items_TIMESTAMP.xlsx
```

Contains every extracted item:

| vendor | date | item | price | category |
| ------ | ---- | ---- | ----- | -------- |

---

### 2. Food Items

```
food_items_TIMESTAMP.xlsx
```

Contains only items categorized as food.

Useful for:

* Cost of Goods Sold
* Inventory tracking
* Food tax reporting

---

### 3. Non-Food Items

```
non_food_items_TIMESTAMP.xlsx
```

Contains supplies and non-edible purchases.

Useful for:

* Operational expenses
* Supply tracking

---

### 4. QuickBooks Import File

```
quickbooks_import_TIMESTAMP.csv
```

Formatted for QuickBooks bulk import.

Columns:

| Date | Vendor | Category | Description | Amount |

Category mapping:

| AI Category | QuickBooks Category |
| ----------- | ------------------- |
| food        | Cost of Goods Sold  |
| non_food    | Supplies            |

---

### 5. Unreadable Receipt Log

```
unreadable_receipts.txt
```

Contains a list of receipts that could not be processed successfully.

Common causes:

* poor scan quality
* unusual formatting
* corrupted PDFs

---

# Dependencies

The script requires Python 3.9+ and the following libraries:

* openai
* pandas
* tqdm
* python-dotenv
* pdf2image
* pillow

---

# Installing Dependencies

Create a virtual environment:

```
python -m venv receipt_env
```

Activate it:

### Windows

```
receipt_env\Scripts\activate
```

### Linux / WSL / Mac

```
source receipt_env/bin/activate
```

Install dependencies:

```
pip install openai pandas tqdm python-dotenv pdf2image pillow
```

---

# Additional Requirement (PDF Processing)

The library **pdf2image** requires **Poppler**.

### Windows

Download Poppler:

https://github.com/oschwartz10612/poppler-windows/releases/

Extract it and add the `bin` folder to your system PATH.

Example:

```
C:\poppler\Library\bin
```

---

# Environment Variables

Create a `.env` file in the script directory.

```
OPENAI_API_KEY=your_api_key_here
```

This key allows the script to access the OpenAI API for receipt interpretation.

---

# How the Script Works

1. Scan receipts into PDF format
2. Place PDFs into the `Reciepts` folder
3. Run the script
4. The script:

   * converts each page to an image
   * sends the image to the AI model
   * extracts item data
5. Results are saved to Excel and CSV files
6. Processed receipts are moved to `processed/`

---

# Running the Script

### Manual Run

```
python process_reciepts.py
```

### Recommended (Windows Batch Launcher)

Create a `.bat` file:

```
@echo off
cd /d "%~dp0"
receipt_env\Scripts\python.exe process_reciepts.py
pause
```

This allows the script to run by simply double-clicking the icon.

---

# Example Workflow

1. Scan receipts with a phone scanner app
2. Export them as PDF files
3. Place them in:

```
Reciepts/
```

4. Run the processor

Within minutes you will have:

* categorized inventory reports
* QuickBooks import files
* organized receipt archives

---

# Performance Notes

* Large multi-page receipts may take several seconds to process
* API calls are automatically retried if they fail
* Threaded processing allows multiple receipts to run simultaneously

If API rate limits occur, reduce the thread count in the script:

```
ThreadPoolExecutor(max_workers=2)
```

---

# Limitations

* Poor scan quality may reduce accuracy
* Extremely unusual receipt formats may fail parsing
* Internet connection is required for AI processing

---

# License

This project is provided for educational and personal automation use.

Use responsibly with financial data.

---

# Author

Terry Weatherman
