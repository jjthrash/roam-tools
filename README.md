# Personal tools for Roam Research

## Overview

These tools are not supported, but you're welcome to use them.


### License

These tools are public domain.

## Tools

### Roam Month

Spit out a `{{table}}` that contains a calendar. Specify a month, or print out the current month if blank.

E.g.

- `roam-month` - render the current month
- `roam-month 2020/07 - render July, 2020
- `roam-month 2020/07/01 - render July, 2020


### Roam Day Miner

Mine the day pages for nodes matching a pattern and render `{{embed: (())}}` nodes for each block reference that matches

You must export your DB as JSON for this to work

E.g.

- `roam-mine-daily -f my-db.json -m 2020/07 -s "[[DONE]]" -a` - Show all completed TODOs for July, 2020
