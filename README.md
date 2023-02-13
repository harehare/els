<div align="center">

# <img height="128px" src="./assets/icon.svg"/>

<!--
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)
[![tests](https://github.com/harehare/els/actions/workflows/tests.yml/badge.svg)](https://github.com/harehare/els/actions/workflows/tests.yml)
-->
</div>

<div style="color:#49B6C8">
els is a powerful ls for pros.

- shows useful icons next to file and folder names.
- environment variables can be used to change the default options.
- can be displayed in json, jsonl, csv, and other formats.

---

## cli options

### Display options

- **-1**, **--oneline** Display one entry per line.
- **-l**, **--long** Display extended file metadata as a table.
- **-G**, **--grid** Display entries as a grid (default).
- **-F**, **--classify** Display type indicator by file names
- **-c**, **--csv** Display entries as csv
- **-j**, **--json** Display entries as json
- **-J**, **--jsonl** Display entries as jsonl
- **-p**, **--path** Display full path
- **-R**, **--recurse** Recurse into directories
- **--color COLOR** Use terminal colours (always, never)
- **--icons ICONS** Display icons (nerd, unicode)
- **--no-dir-name** Don't display dir name

### Environment variables

```bash
# Display entries as a grid (default).
ELS_DISPLAY_GRID=true
# Display one entry per line.
ELS_DISPLAY_ONELINE=false
# Display extended file metadata as a table.
ELS_DISPLAY_LONG=false
# Display entries as csv
ELS_DISPLAY_CSV=false
# Display type indicator by file names
ELS_DISPLAY_CLASSIFY=false
# Display entries as json
ELS_DISPLAY_JSON=false
# Display entries as jsonl
ELS_DISPLAY_JSONL=false
# Recurse into directories
ELS_DISPLAY_RECURSE=false
# Display icons (nerd, unicode)
ELS_DISPLAY_ICONS=none
# Display full path
ELS_DISPLAY_PATH=false
# Use terminal colours (always, never)
ELS_DISPLAY_COLOR_STYLE=always
```

### Filtering and sorting options

- **-a**, **--all** Show hidden and 'dot' files.
- **-r**, **--reverse** Reverse the sort order
- **-s**, **--sort SORT_FIELD** Which field to sort by (choices: name, extension, size, modified, accessed, created, inode)
- **-L**, **--level DEPTH** Limit the depth of recursion
- **-D**, **--only-dirs** List only directories
- **-e**, **--exclude** EXCLUDE Do not show files that match the given regular expression
- **-o**, **--only** ONLY Only show files that match the given regular expression
- **--group-directories-first** List directories before other files

### Environment variables

```bash
# Show hidden and 'dot' files.
ELS_FILTRING_AND_SORTING_ALL=true
# Reverse the sort order
ELS_FILTRING_AND_SORTING_REVERSE=false
# List only directories
ELS_FILTRING_AND_SORTING_ONLY_DIRS=false
# Which field to sort by (choices: name, extension, size, modified, accessed, created, inode)
ELS_FILTRING_AND_SORTING_SORT=kind
# Limit the depth of recursion
ELS_FILTRING_AND_SORTING_LEVEL=128
# List directories before other files
ELS_GROUP_DIRECTORIES_FIRST=false
# Do not show files that match the given regular expression
ELS_FILTRING_AND_SORTING_EXCLUDE="\.git"
# ONLY Only show files that match the given regular expression
ELS_FILTRING_AND_SORTING_ONLY=".*\.zig"
```

### Long view, csv and json options

- **-B**, **--bytes** List file sizes in bytes
- **-g**, **--group** List each file's group
- **-i**, **--inode** List each file's inode number
- **-H**, **--header** Add a header row to each column
- **-U**, **--created** Use the created timestamp field
- **-u**, **--accessed** Use the accessed timestamp field
- **-m**, **--modified** Use the modified timestamp field
- **-n**, **--numeric** List numeric user and group IDs
- **--all-fields** Show all fields
- **--blocks** Show number of file system blocks
- **--links** List each file’s number of hard links
- **--no-permissions** Suppress the permissions field
- **--no-filesize** Suppress the filesize field
- **--no-dir-name** Don't display dir name
- **--no-user** Suppress the user field
- **--no-time** Suppress the time field
- **--time-style** How to format timestamps (default, iso, long-iso, timestamp)
- **--octal-permissions** List each file's permission in octal format

### Environment variables

```bash
# List each file's inode number
ELS_LONG_VIEW_INODE=false
# List each file's group
ELS_LONG_VIEW_GROUP=false
# Use the created timestamp field
ELS_LONG_VIEW_CREATED=false
# Use the accessed timestamp field
ELS_LONG_VIEW_ACCESSED=false
# Use the modified timestamp field
ELS_LONG_VIEW_MODIFIED=false
# Add a header row to each column
ELS_LONG_VIEW_HEADER=false
# Suppress the filesize field
ELS_LONG_VIEW_NO_FILE_SIZE=false
# Suppress the user field
ELS_LONG_VIEW_NO_USER=false
# Suppress the time field
ELS_LONG_VIEW_NO_TIME=false
# Suppress the permissions field
ELS_LONG_VIEW_NO_PERMISSIONS=false
# How to format timestamps (default, iso, long-iso, timestamp)
ELS_LONG_VIEW_TIME_STYLE=default
# List file sizes in bytes
ELS_LONG_VIEW_BYTES=false
# List each file's permission in octal format
ELS_LONG_VIEW_OCTAL_PERMISSIONS=false
# Show number of file system blocks
ELS_LONG_VIEW_BLOCKS=false
# List numeric user and group IDs
ELS_LONG_VIEW_NUMERIC=false
# List each file’s number of hard links
ELS_LONG_VIEW_LINKS=false
# Don't display dir name
ELS_LONG_VIEW_NO_DIR_NAME=false
# Show all fields
ELS_LONG_VIEW_ALL_FIELDS=false
```

## Installation

### Homebrew

TODO:

### Manual

```
just install
```

## Development

```
just run
```

## Testing

```
$ just test
```

<hr />

## License

[MIT](http://opensource.org/licenses/MIT)

</div>
