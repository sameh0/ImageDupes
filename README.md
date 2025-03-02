# Duplicate Image Finder

A tool to help you identify and manage duplicate images in your filesystem.

## Features

- Scans directories for image files
- Identifies duplicate images using hash comparison
- Supports common image formats (JPEG, PNG, GIF, etc.)
- Shows file locations of duplicates
- Helps manage storage space efficiently

## Installation

To install the Duplicate Image Finder, follow these steps:

1.  Build the project using Swift Package Manager:
    ```bash
    swift build -c release
    ```
2.  Copy the executable to your desired location (e.g., /usr/local/bin):
    ```bash
    cp ./.build/release/ImageDupes /usr/local/bin
    ```

## Usage

To use the Duplicate Image Finder, run the following command:

```bash
ImageDupes <directory> [options]
```
### Options
```bash
  -t, --threshold <threshold>
                          Similarity threshold (0-100, where 100 means identical). Default: 95 (default: 95)
  -h, --hash-size <hash-size>
                          Image hash size (higher values provide more accurate comparison but slower performance). Default: 8 (default: 8)
  -q, --quiet             When set, only shows file paths without interactive prompts
  -r, --recursive         Recursively scan directories
  -d, --delete            Enable interactive deletion mode
  -n, --dry               Dry run - only show duplicates without deleting anything
  -h, --help              Show help information.
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)
