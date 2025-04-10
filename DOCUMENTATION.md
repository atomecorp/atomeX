# atomeX Documentation

This document explains the structure and functionality of the atomeX project, a development environment that supports both Opal (Ruby to JavaScript) and Ruby WebAssembly.

## Project Structure

The project is organized as follows:

```
atomeX/
├── app/                # Ruby application code
├── sources/            # Core Ruby source files
│   ├── infos.rb        # Project information
│   └── kernel.rb       # Ruby kernel code
├── html_sources/       # HTML templates
│   ├── index.html      # Base HTML template
│   ├── index_opal.html # HTML template for Opal version
│   └── index_wasm.html # HTML template for WebAssembly version
├── specific/           # Runtime-specific code
│   ├── opal/           # Opal-specific extensions
│   │   └── opal_init.rb # Opal initialization
│   └── wasm/           # WebAssembly-specific extensions
│       └── wasm_init.rb # WebAssembly initialization
├── builder.rb          # Main build script
├── hot_reloader.rb     # Auto-reloading during development
├── html_builder.rb     # HTML file generator
├── web_builder.rb      # Opal and WebAssembly compiler
└── Gemfile             # Ruby dependencies
```

## Usage

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/atomeX.git
cd atomeX
```

### Compilation

To compile the project, run:

```bash
ruby builder.rb
```

### Compilation Options


to build for production, you can use the `--production` flag:

```bash
ruby builder.rb --production
```

### Hot Reloading

The project automatically includes a hot reloading feature that watches for changes in your files and rebuilds them when necessary. To use it:

When a file is modified, the Opal and wasm versions of the application will be automatically recompiled.

## Architecture

### HTML Builder

The `html_builder.rb` script is responsible for:

1. Taking the base HTML template from `html_sources/index.html`
2. Merging it with runtime-specific templates (`index_opal.html` and `index_wasm.html`)
3. Generating the final HTML files in the `build/` directory

### Web Builder

The `web_builder.rb` script handles the compilation process:

#### Opal Compilation

For the Opal version:
1. Compiles all Ruby files from `specific/opal/`, `sources/`, and `app/` directories to JavaScript
2. Adds script tags to the generated HTML file
3. Outputs the compiled files to `build/opal/`

#### WebAssembly Compilation

For the WebAssembly version:
1. Downloads and extracts Ruby WASM and WASI packages if they don't exist
2. Compiles the Ruby runtime to WebAssembly
3. Modifies generated JavaScript files to use local paths
4. Adds script tags for Ruby files to the generated HTML
5. Outputs the compiled files to `build/wasm/`

## Compiled Output

### Opal Version

The Opal version compiles Ruby code into JavaScript. The main output files are:

- `build/index_opal.html` : HTML page for the Opal version
- `build/opal/*.js` : Compiled JavaScript files

### WebAssembly Version

The WebAssembly version uses Ruby WASM. The main output files are:

- `build/index_wasm.html` : HTML page for the WebAssembly version
- `build/wasm/ruby.wasm` : Ruby WebAssembly runtime
- `build/wasm/ruby_runtime.wasm` : Compiled application as WebAssembly

## Development Flow

1. Write your Ruby code in the `app/` directory
2. Run `ruby builder.rb` to compile both Opal and WebAssembly versions
3. Run the app using a local server (e.g., `ruby -run -e httpd . -p 9292`), this will load either the Opal or WebAssembly version depending on your settings


