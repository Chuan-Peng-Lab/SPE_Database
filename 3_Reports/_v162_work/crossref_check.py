# -*- coding: utf-8 -*-
"""Verify suspicious reference entries against Crossref."""
import json
import urllib.parse
import urllib.request

QUERIES = [
    ("Bogacz 2006 (cited, not listed)",
     "The physics of optimal decision making a formal analysis of performance in two-alternative forced choice tasks", "Bogacz"),
    ("Markus & Kitayama 1991 (draft lists as 'Rose, H. (1991)')",
     "Culture and the self implications for cognition emotion and motivation", "Markus"),
    ("Aron et al. 1992",
     "Inclusion of Other in the Self Scale and the structure of interpersonal closeness", "Aron"),
    ("Ghai 2024",
     "Big-team science does not guarantee generalizability", "Ghai"),
    ("Lin et al. 2023",
     "Pervasive failure to report properties of visual stimuli in experimental research in psychology and neuroscience", "Lin"),
    ("Desebrock & Spence 2021",
     "The Self-Prioritization Effect self-referential processing in movement highlights modulation at multiple stages", "Desebrock"),
    ("Cicchini et al. 2024", "Serial dependence in perception", "Cicchini"),
    ("Sun et al. 2023 China Scientific Data",
     "A cognitive ontological dataset for neuroimaging studies of self-reference", "Sun"),
]

UA = {"User-Agent": "SPE-DB-audit/1.0 (mailto:hcp4715@hotmail.com)"}
for tag, q, a in QUERIES:
    url = ("https://api.crossref.org/works?rows=2&query.bibliographic="
           + urllib.parse.quote(q) + "&query.author=" + urllib.parse.quote(a))
    print("===", tag)
    try:
        req = urllib.request.Request(url, headers=UA)
        d = json.load(urllib.request.urlopen(req, timeout=45))
        for it in d["message"]["items"][:2]:
            t = (it.get("title") or [""])[0]
            ct = it.get("container-title") or []
            ct = ct[0] if ct else ""
            yr = it.get("issued", {}).get("date-parts", [[None]])[0][0]
            au = ", ".join((x.get("family", "") + " " + x.get("given", "")).strip()
                           for x in it.get("author", [])[:3])
            print("   {t} | {ct} | {yr} | v{vol} i{iss} p{pg} | {au} | doi {doi}".format(
                t=t[:95], ct=ct[:55], yr=yr, vol=it.get("volume"), iss=it.get("issue"),
                pg=it.get("page"), au=au, doi=it.get("DOI")))
    except Exception as e:
        print("   ERR", e)
