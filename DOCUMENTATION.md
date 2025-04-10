
# atomeX Documentation

This document explains the structure and functionality of the atomeX project, a development environment that supports both Opal (Ruby to JavaScript) and Ruby WebAssembly.

## Project Structure

The project is organized as follows:

```
atomeX/
├── app/               # Ruby application code
├── sources/           # Source files for compilation
│   ├── index.html     # Base HTML template
│   ├── index_opal.html # HTML template for Opal version
│   ├── index_wasm.html # HTML template for WebAssembly version
│   ├── kernel.rb      # Ruby kernel code
│   ├── opal_add_on.rb # Opal-specific extensions
│   └── wasm_add_on.rb # WebAssembly-specific extensions
├── builder.rb         # Main build script
├── hot_reloader.rb    # Auto-reloading during development
├── html_builder.rb    # HTML file generator
├── web_builder.rb     # Opal and WebAssembly compiler
└── Gemfile            # Ruby dependencies
```

## Usage

### Installation


### Compilation

```bash
ruby builder.rb
```

### Compilation Options

- `--update` : Force update libraries and components
- `--skip-opal` : Skip Opal compilation
- `--skip-wasm` : Skip WebAssembly compilation
- `--serve` : Start a development server with hot reloading

### Example

```bash
# Full build and start development server
ruby builder.rb --serve

# Update dependencies and build
ruby builder.rb --update

# Build only the Opal version
ruby builder.rb --skip-wasm
```

## Compiled Versions Architecture

### Opal Version (JavaScript)

The Opal version compiles Ruby code into JavaScript. Main files:

- `build/index_opal.html` : HTML page for the Opal version
- `build/opal/kernel.js` : Compiled Ruby kernel
- `build/opal/application.js` : Compiled application
- `build/opal/opal.min.js` : Opal runtime

### WebAssembly Version

The WebAssembly version uses Ruby WebAssembly. Main files:

- `build/index_wasm.html` : HTML page for the WebAssembly version
- `build/wasm/app.wasm` : Application compiled into WebAssembly
- `build/wasm/ruby.wasm` : Ruby WebAssembly runtime
- `build/wasm/package/` : JavaScript files for WebAssembly integration

## Hot Reloading

In server mode (`--serve`), changes made to files in the `app/` directory are automatically detected and trigger a recompilation of the Opal version.
