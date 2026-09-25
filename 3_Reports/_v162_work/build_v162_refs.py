# -*- coding: utf-8 -*-
"""Batch 3: fix the reference list (verified against Crossref) and the related in-text citations."""
import docx

DST = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2.docx'
doc = docx.Document(DST)


def set_text(p, text):
    if not p.runs:
        p.add_run(text); return
    p.runs[0].text = text
    for r in p.runs[1:]:
        r.text = ""


def find(prefix, start=0):
    for i, p in enumerate(doc.paragraphs):
        if i >= start and p.text.strip().startswith(prefix):
            return i, p
    raise KeyError(prefix)


REPLACEMENTS = [
    ("Aron, A., Aron, E. N., & Smollan, D.",
     "Aron, A., Aron, E. N., & Smollan, D. (1992). Inclusion of Other in the Self Scale and the "
     "structure of interpersonal closeness. Journal of Personality and Social Psychology, 63(4), "
     "596\u2013612. https://doi.org/10.1037/0022-3514.63.4.596"),
    ("Ghai, S. (2024).",
     "Ghai, S., Forscher, P. S., & Hu, C.-P. (2024). Big-team science does not guarantee "
     "generalizability. Nature Human Behaviour, 8(6), 1053\u20131056. "
     "https://doi.org/10.1038/s41562-024-01902-y"),
    ("Lin, Z., Ma, Q., Huang, X.",
     "Lin, Z., Ma, Q., Huang, X., Wu, X., & Zhang, Y. (2023). Pervasive failure to report "
     "properties of visual stimuli in experimental research in psychology and neuroscience: Two "
     "metascientific studies. Psychological Bulletin, 149(7\u20138), 487\u2013505. "
     "https://doi.org/10.1037/bul0000399"),
    ("Rose, H. (1991).",
     "Markus, H. R., & Kitayama, S. (1991). Culture and the self: Implications for cognition, "
     "emotion, and motivation. Psychological Review, 98(2), 224\u2013253. "
     "https://doi.org/10.1037/0033-295X.98.2.224"),
    ("Sun, S., Wang, N., Wen, J., & Chuan-Peng, H.",
     "Sun, S., Wang, N., Wen, J., & Hu, C.-P. (2023). A dataset of cognitive ontology for "
     "neuroimaging studies of self-reference. China Scientific Data, 8(3), 175\u2013189. "
     "https://doi.org/10.11922/11-6035.csd.2022.0047.zh"),
]

for prefix, new in REPLACEMENTS:
    _, p = find(prefix)
    set_text(p, new)
    print("replaced:", prefix)

# --- add the missing Bogacz et al. (2006) entry, kept in alphabetical order ---
i_aron, p_aron = find("Aron, A., Aron, E. N., & Smollan, D.")
bogacz = ("Bogacz, R., Brown, E., Moehlis, J., Holmes, P., & Cohen, J. D. (2006). The physics of "
          "optimal decision making: A formal analysis of models of performance in two-alternative "
          "forced-choice tasks. Psychological Review, 113(4), 700\u2013765. "
          "https://doi.org/10.1037/0033-295X.113.4.700")
new_p = p_aron.insert_paragraph_before(bogacz, style=p_aron.style)
print("inserted Bogacz et al. (2006)")

# --- remove the duplicated Sun et al. (2023) entry ---
i_dup, p_dup = find("Sun, S., Wang, N., Wen, J., & Hu, C.")
p_dup._element.getparent().remove(p_dup._element)
print("removed duplicate Sun et al. (2023) entry")

# --- in-text citation fixes ---
for i, p in enumerate(doc.paragraphs):
    t = p.text
    if "Rose, 1991" in t:
        set_text(p, t.replace("(Rose, 1991)", "(Markus & Kitayama, 1991)"))
        print("in-text: Rose, 1991 -> Markus & Kitayama, 1991")
    elif "(Ghai, 2024;" in p.text:
        set_text(p, p.text.replace("(Ghai, 2024;", "(Ghai et al., 2024;"))
        print("in-text: Ghai, 2024 -> Ghai et al., 2024")

doc.save(DST)
print("saved ->", DST)
