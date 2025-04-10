
# atomeX

> Hybrid Ruby development environment — Opal (Ruby → JavaScript) & Ruby WebAssembly.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Ruby](https://img.shields.io/badge/Ruby-3.0%2B-red)](https://www.ruby-lang.org/)
[![WebAssembly](https://img.shields.io/badge/WebAssembly-supported-blueviolet)](https://webassembly.org/)

---

atomeX is a hybrid Ruby development environment designed to compile Ruby code into JavaScript using [Opal](https://opalrb.com/) or run Ruby directly in WebAssembly (WASM).

This environment provides a clean structure to build portable Ruby applications for the web.

---

## Download

Clone the repository:

```bash
git clone https://github.com/yourusername/atomeX.git
```

---

## Getting Started

### Prerequisites

- Ruby (version 3.0 or higher recommended)
- Bundler

### Installation

```bash
git clone https://github.com/atomecorp/atomeX.git
```

---

## Build and Run

### Build the project:

```bash
cd atomeX
```
Optional: modify the app/index.rb file to your needs, if you want 
```bash
ruby builder.rb
```

### Optional: you can build a specific target:
Possible options are `--opal` or `--wasm`

for production build, add `--production` to the command.
```bash
ruby builder.rb --wasm --production
```

---

## Open in your Browser:

```bash
cd build 
ruby -run -e httpd . -p 9292
```

---

## Documentation

For full details about the project structure and API usage, see:

[DOCUMENTATION.md](DOCUMENTATION.md)

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
