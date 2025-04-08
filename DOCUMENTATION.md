
# XperimentWasm - Documentation

## Overview
XperimentWasm is a Ruby and WebAssembly project that allows Ruby code to be compiled and executed both via Opal (in the browser) and WebAssembly (WASM). This project supports interactive development using Ruby with the help of Opal, and also compiling Ruby code to WebAssembly for maximum performance.

## Features
- **Ruby Compilation via Opal:** Generates JavaScript from Ruby code using the Opal compiler.
- **Ruby Compilation via WebAssembly:** Converts Ruby code to WebAssembly for optimized performance.
- **Automatic Download and Update of Dependencies:** Opal, Ruby WASM, and other necessary libraries can be automatically downloaded and updated.
- **Inline Ruby Code Support:** Allows embedding Ruby code directly in HTML files, which is then compiled by Opal.

---

## Requirements

- Ruby (>= 3.0)
- Opal gem (`gem install opal`)
- rbwasm tool for compiling to WebAssembly
- Internet connection for downloading dependencies

---

## Installation


1. Clone the repository:
   ```bash
   bundle install
   ```

2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/XperimentWasm.git
   cd XperimentWasm
   ```

3. Install the Opal gem if not already installed:
   ```bash
   gem install opal
   ```

4. Install `rbwasm` for WASM compilation (if not already installed).

---

## Usage

### Basic Compilation
To compile the Ruby code without forcing updates:
```bash
ruby builder.rb
```



<!-- ### Forced Update & Compilation
To update all dependencies and forcefully compile everything:
```bash
ruby ruby_builder.rb --update
```

This command will:
- Update the Opal gem.
- Re-download `opal.min.js`.
- Re-download Ruby WASM (`ruby.wasm`).
- Re-download `ruby-3.4-wasm-wasi-2.7.1.tgz`. -->

---

### to run
To compile the Ruby code without forcing updates:
```bash
cd build
ruby -run -e httpd . -p 9393
```

## File Structure

```
.
├── app/                      # Ruby source code
│   ├── index.rb
│   ├── index_back.rb
├── build.sh                  # Optional build script
├── DOCUMENTATION.md          # This documentation file
├── index_opal.html           # HTML file for Opal execution
├── index_wasm.html           # HTML file for WASM execution
├── wasm_builder.rb           # Main Ruby build script
├── build/                    # Generated files (Opal and WASM outputs)
```

---

## HTML Integration

### Opal Version
For using the Opal-compiled version, open `index_opal.html` in your browser:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Opal Version</title>
    <script src="./build/opal.min.js"></script>
    <script src="./build/application.js"></script>
</head>
<body>
    <div id="app">Opal Version Loaded</div>
</body>
</html>
```

### WebAssembly Version
For using the WebAssembly-compiled version, open `index_wasm.html` in your browser:
```html
<!DOCTYPE html>
<html>
<head>
    <title>WASM Version</title>
    <script src="./build/package/dist/browser.script.iife.js"></script>
</head>
<body>
    <div id="app">WASM Version Loaded</div>
</body>
</html>
```

---


## Running the Local Server

1. ruby -run -ehttpd . -p8000

---

## Troubleshooting

1. Ensure all dependencies are properly installed (Ruby, Opal gem, rbwasm).
2. Make sure you have an active internet connection if using the `--update` flag.
3. Check for any errors displayed by the script during compilation.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
