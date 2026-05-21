#!/usr/bin/env python3
"""Split hica-for-kids.md into mdBook chapter files."""
import os
import re

SRC = "documentation/hica-for-kids.md"
OUT = "documentation/hica-for-kids-book/src"

with open(SRC) as f:
    lines = f.readlines()

# Define the world→levels mapping from the TOC
worlds = {
    1: {"title": "The Training Grounds", "emoji": "🏕️", "levels": range(1, 8)},
    2: {"title": "Building Machines", "emoji": "🏗️", "levels": range(8, 14)},
    3: {"title": "Time Loops & Word Magic", "emoji": "⏳", "levels": range(14, 20)},
    4: {"title": "The Ultimate Data Backpack", "emoji": "🎒", "levels": range(20, 25)},
    5: {"title": "Wizard Level Coding", "emoji": "🧙", "levels": range(25, 29)},
    6: {"title": "Real-World Quests", "emoji": "🌍", "levels": range(29, 36)},
}

# Find line numbers for each ## and ### heading
headings = []
for i, line in enumerate(lines):
    if line.startswith("## ") or line.startswith("### "):
        headings.append((i, line.rstrip()))

# Extract the introduction (before first ## World)
intro_end = None
for i, line in enumerate(lines):
    if line.startswith("## 🏕️ World 1"):
        intro_end = i
        break

intro_text = "".join(lines[:intro_end]).rstrip() + "\n"
# Remove the TOC from intro since mdBook has its own sidebar
# Keep just the welcome paragraph
intro_clean = []
in_toc = False
for line in lines[:intro_end]:
    if line.startswith("## Table of Contents"):
        in_toc = True
        continue
    if in_toc and line.startswith("---"):
        in_toc = False
        continue
    if in_toc:
        continue
    intro_clean.append(line)

with open(os.path.join(OUT, "introduction.md"), "w") as f:
    f.write("".join(intro_clean).strip() + "\n")

# Find all "### Level N." headings and their line ranges
level_ranges = []
for idx, (lineno, heading) in enumerate(headings):
    m = re.match(r"### Level (\d+)\.", heading)
    if m:
        level_num = int(m.group(1))
        # Find next "### Level" or "## " heading to determine end
        end_lineno = len(lines)
        for next_idx in range(idx + 1, len(headings)):
            next_lineno, next_heading = headings[next_idx]
            if re.match(r"### Level \d+\.", next_heading) or next_heading.startswith("## "):
                end_lineno = next_lineno
                break
        level_ranges.append((level_num, lineno, end_lineno))

# Find Glossary
glossary_start = None
for i, line in enumerate(lines):
    if line.startswith("## 📖 Glossary"):
        glossary_start = i
        break

# Extract world intro text (the blockquote after ## World N heading)
world_intros = {}
for i, line in enumerate(lines):
    m = re.match(r"## [🏕️🏗️⏳🎒🧙🌍]+ World (\d+):", line)
    if m:
        wnum = int(m.group(1))
        # Collect lines until next ### Level
        intro_lines = [line]
        for j in range(i + 1, len(lines)):
            if lines[j].startswith("### Level"):
                break
            intro_lines.append(lines[j])
        world_intros[wnum] = "".join(intro_lines).strip() + "\n"

# Create world directories and level files
for wnum, winfo in worlds.items():
    wdir = os.path.join(OUT, f"world-{wnum}")
    os.makedirs(wdir, exist_ok=True)

    # World index page
    if wnum in world_intros:
        with open(os.path.join(wdir, "index.md"), "w") as f:
            f.write(world_intros[wnum])

    for lnum in winfo["levels"]:
        for level_num, start, end in level_ranges:
            if level_num == lnum:
                content = "".join(lines[start:end]).strip() + "\n"
                # Promote ### to # for the main heading
                content = re.sub(r"^### (Level \d+\.)", r"# \1", content, count=1)
                # Sub-sections that were ### become ## 
                # (they're sub-sections of a Level)
                # Actually they should stay as-is since the Level heading is now #
                # Let's make sub-### into ## for proper hierarchy
                fname = f"level-{lnum:02d}.md"
                with open(os.path.join(wdir, fname), "w") as f:
                    f.write(content)
                break

# Glossary
if glossary_start is not None:
    glossary_content = "".join(lines[glossary_start:]).strip() + "\n"
    # Promote to #
    glossary_content = glossary_content.replace("## 📖 Glossary", "# 📖 Glossary", 1)
    with open(os.path.join(OUT, "glossary.md"), "w") as f:
        f.write(glossary_content)

# Generate SUMMARY.md
summary_lines = ["# Summary\n\n"]
summary_lines.append("[Introduction](introduction.md)\n\n")

for wnum, winfo in worlds.items():
    summary_lines.append(f"# {winfo['emoji']} World {wnum}: {winfo['title']}\n\n")
    for lnum in winfo["levels"]:
        for level_num, start, end in level_ranges:
            if level_num == lnum:
                # Extract the title from the heading
                heading = lines[start].rstrip()
                title = re.sub(r"^### Level \d+\. ", "", heading)
                summary_lines.append(
                    f"- [Level {lnum}. {title}](world-{wnum}/level-{lnum:02d}.md)\n"
                )
                break

summary_lines.append("\n# 📖 Reference\n\n")
summary_lines.append("- [Glossary](glossary.md)\n")

with open(os.path.join(OUT, "SUMMARY.md"), "w") as f:
    f.writelines(summary_lines)

print("Done! Generated mdBook source in", OUT)
print(f"  - {len(level_ranges)} levels extracted")
print(f"  - {len(worlds)} worlds")
