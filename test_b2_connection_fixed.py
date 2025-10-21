# test_b2_connection_fixed.py
import os
from dotenv import load_dotenv
import certifi

# Load .env file
load_dotenv()  # make sure you have python-dotenv installed

# Force Python SSL and requests to use certifi CA bundle
os.environ["SSL_CERT_FILE"] = certifi.where()
os.environ["REQUESTS_CA_BUNDLE"] = certifi.where()

import requests
from b2sdk.v2 import InMemoryAccountInfo, B2Api

session = requests.Session()
session.verify = certifi.where()


# B2 credentials from .env
B2_KEY_ID = os.getenv("B2_KEY_ID")
B2_APPLICATION_KEY = os.getenv("B2_APPLICATION_KEY")
B2_BUCKET_NAME = os.getenv("B2_BUCKET_NAME")
B2_BUCKET_ID = os.getenv("B2_BUCKET_ID")

print("Testing B2 Configuration...")
print("B2_KEY_ID:", B2_KEY_ID)
print("B2_BUCKET_NAME:", B2_BUCKET_NAME)
print("B2_BUCKET_ID:", B2_BUCKET_ID)
print("B2_APPLICATION_KEY:", "*"*24)

try:
    info = InMemoryAccountInfo()
    b2_api = B2Api(info)
    b2_api.authorize_account("production", B2_KEY_ID, B2_APPLICATION_KEY)
    print("✅ Successfully authorized with B2!")

    bucket = b2_api.get_bucket_by_name(B2_BUCKET_NAME)
    print(f"✅ Found bucket: {bucket.name}")
    print(f"   Bucket ID: {bucket.id_}")
    print(f"   Bucket Type: {bucket.type_}")
except Exception as e:
    print("❌ B2 Connection Error:", e)