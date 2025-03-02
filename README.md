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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)