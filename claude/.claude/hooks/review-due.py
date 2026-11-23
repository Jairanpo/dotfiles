#!/usr/bin/env python3
"""SessionStart hook: list concepts in the review log that are due today."""
import datetime
import pathlib

LOG = pathlib.Path.home() / ".claude/learning/review-log.md"


def main():
    if not LOG.exists():
        return
    today = datetime.date.today().isoformat()
    due = []
    for line in LOG.read_text().splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5 or not cells[3][:4].isdigit():
            continue
        if cells[3] <= today:
            due.append(f"- {cells[0]} ({cells[1]}), interval {cells[4]}d, misses {cells[5] if len(cells) > 5 else 0}")
    if due:
        print("Spaced review: these concepts in ~/.claude/learning/"
              "review-log.md are due. Offer the student a short review "
              "(rules in explaining.md section 6):")
        print("\n".join(due))


if __name__ == "__main__":
    main()
