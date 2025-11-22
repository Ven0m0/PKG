#!/usr/bin/env python
import sys
import json
import os
from sys import argv
from json import load, dump, JSONDecodeError

PRODUCT_JSON_LOCATION = "/usr/share/vscodium/resources/app/product.json"


if __name__ == "__main__":
    try:
        with open(PRODUCT_JSON_LOCATION) as file:
            product = load(file)
    except JSONDecodeError:
        print("error: couldn't parse local product.json or fetch a new one from the web")
        exit(1)
    if "-R" in argv:
        product["extensionsGallery"] = {
            "serviceUrl": "https://open-vsx.org/vscode/gallery",
            "itemUrl": "https://open-vsx.org/vscode/item",
        }
        product["linkProtectionTrustedDomains"] = ["https://open-vsx.org"]
    else:
        product["extensionsGallery"] = {
            "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
            "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
            "itemUrl": "https://marketplace.visualstudio.com/items",
        }
        product.pop("linkProtectionTrustedDomains", None)

    with open(PRODUCT_JSON_LOCATION, mode="w") as file:
        dump(product, file, indent=2)

pkt_name = sys.argv[1]
operation = sys.argv[2]

product_path = "/usr/share/vscodium/resources/app/product.json"
patch_path = "/usr/share/%s/patch.json" % pkt_name
cache_path = "/usr/share/%s/cache.json" % pkt_name

if not os.path.exists(cache_path):
    with open(cache_path, "w") as file:
        file.write("{}")


def patch():
    # Read all files once at the start
    with open(product_path, "r") as product_file:
        product_data = json.load(product_file)
    with open(patch_path, "r") as patch_file:
        patch_data = json.load(patch_file)

    # Build cache data in memory
    cache_data = {}
    for key in patch_data.keys():
        if key in product_data:
            cache_data[key] = product_data[key]
        product_data[key] = patch_data[key]

    # Write both files at the end
    with open(product_path, "w") as product_file:
        json.dump(product_data, product_file, indent="\t")
    with open(cache_path, "w") as cache_file:
        json.dump(cache_data, cache_file, indent="\t")


def restore():
    # Read all files once at the start
    with open(product_path, "r") as product_file:
        product_data = json.load(product_file)
    with open(patch_path, "r") as patch_file:
        patch_data = json.load(patch_file)
    with open(cache_path, "r") as cache_file:
        cache_data = json.load(cache_file)

    # Update product data in memory
    for key in patch_data.keys():
        if key in product_data:
            del product_data[key]
    for key in cache_data.keys():
        product_data[key] = cache_data[key]

    # Write the final result
    with open(product_path, "w") as product_file:
        json.dump(product_data, product_file, indent="\t")


if operation == "patch":
    patch()
elif operation == "restore":
    restore()
