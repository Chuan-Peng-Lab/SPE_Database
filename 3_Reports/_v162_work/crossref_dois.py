# -*- coding: utf-8 -*-
"""Verify exact author lists / venues for the references being corrected."""
import json
import urllib.request

DOIS = [
    "10.1037/bul0000399",       # Lin et al. 2023
    "10.11922/11-6035.csd.2022.0047.zh",  # Sun et al. 2023
    "10.1038/s41562-024-01902-y",         # Ghai et al. 2024
    "10.1037/0033-295x.98.2.224",         # Markus & Kitayama 1991
    "10.1037/0022-3514.63.4.596",         # Aron et al. 1992
    "10.1037/0033-295x.113.4.700",        # Bogacz et al. 2006
]
UA = {"User-Agent": "SPE-DB-audit/1.0 (mailto:hcp4715@hotmail.com)"}
for doi in DOIS:
    try:
        req = urllib.request.Request("https://api.crossref.org/works/" + doi, headers=UA)
        m = json.load(urllib.request.urlopen(req, timeout=45))["message"]
        au = "; ".join(f"{a.get('family','')}, {a.get('given','')}" for a in m.get("author", []))
        print(f"DOI {doi}")
        print(f"  title : {(m.get('title') or [''])[0]}")
        print(f"  venue : {(m.get('container-title') or [''])[0]}")
        print(f"  year  : {m.get('issued',{}).get('date-parts',[[None]])[0][0]}  "
              f"vol {m.get('volume')} issue {m.get('issue')} pages {m.get('page')}")
        print(f"  authors: {au}")
        print()
    except Exception as e:
        print("ERR", doi, e)
