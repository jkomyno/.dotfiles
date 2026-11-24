"""Rough sentence-length check for a Markdown or MDX post.

Usage: python3 -I scripts/sentence-band.py <file>
Strips frontmatter, code blocks, headings, tables, and link targets, then
reports median words per sentence, standard deviation, share under 8 words,
and the semicolon count. Treat the numbers as approximate.
"""
import re
import statistics as st
import sys


def main(path: str) -> None:
    text = open(path, encoding="utf-8").read()
    text = re.sub(r"^---.*?^---", "", text, flags=re.S | re.M)
    text = re.sub(r"export const .*?`;", "", text, flags=re.S)
    text = re.sub(r"```.*?```", "", text, flags=re.S)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    skip = ("#", "|", "<", "import", "export", "{")
    paras = [p for p in text.split("\n\n") if p.strip() and not p.lstrip().startswith(skip)]
    prose = " ".join(paras)
    sents = [s for s in re.split(r'(?<=[.!?])\s+(?=[A-Z"`])', prose) if len(s.split()) > 1]
    n = [len(s.split()) for s in sents]
    if not n:
        print("no sentences found")
        return
    print(
        f"{len(n)} sentences | median {st.median(n)} (12-17) | sd {st.pstdev(n):.1f} (<12) "
        f"| under 8 words {sum(x < 8 for x in n) / len(n):.0%} (<20%) | semicolons {prose.count(';')} (0)"
    )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
