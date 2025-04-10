# Documentation atomeX

Ce document explique la structure et le fonctionnement du projet atomeX, un environnement de développement qui prend en charge à la fois Opal (Ruby vers JavaScript) et Ruby WebAssembly.

## Structure du projet

Le projet est organisé comme suit:

```
atomeX/
├── app/               # Code Ruby de l'application
├── build/             # Répertoire généré (ne pas modifier directement)
│   ├── opal/          # Build Opal (JavaScript)
│   └── wasm/          # Build WebAssembly
├── sources/           # Fichiers source pour la compilation
│   ├── index.html     # Template HTML de base
│   ├── index_opal.html # Template HTML pour la version Opal
│   ├── index_wasm.html # Template HTML pour la version WebAssembly
│   ├── kernel.rb      # Code kernel Ruby
│   ├── opal_add_on.rb # Extensions spécifiques à Opal
│   └── wasm_add_on.rb # Extensions spécifiques à WebAssembly
├── builder.rb         # Script principal de build
├── hot_reloader.rb    # Rechargement automatique pendant le développement
├── html_builder.rb    # Générateur de fichiers HTML
├── web_builder.rb     # Compilateur Opal et WebAssembly
└── Gemfile            # Dépendances Ruby
```

## Utilisation

### Installation

```bash
bundle install
```

### Compilation

```bash
ruby builder.rb
```

### Options de compilation

- `--update` : Force la mise à jour des bibliothèques et des composants
- `--skip-opal` : Ignore la compilation Opal
- `--skip-wasm` : Ignore la compilation WebAssembly
- `--serve` : Lance un serveur de développement avec rechargement à chaud

### Exemple

```bash
# Compilation complète et démarrage d'un serveur de développement
ruby builder.rb --serve

# Mise à jour des dépendances et compilation
ruby builder.rb --update

# Compilation uniquement de la version Opal
ruby builder.rb --skip-wasm
```

## Architecture des versions compilées

### Version Opal (JavaScript)

La version Opal compile le code Ruby en JavaScript. Les fichiers principaux sont:

- `build/index_opal.html` : Page HTML pour la version Opal
- `build/opal/kernel.js` : Noyau Ruby compilé
- `build/opal/application.js` : Application compilée
- `build/opal/opal.min.js` : Runtime Opal

### Version WebAssembly

La version WebAssembly utilise Ruby WebAssembly. Les fichiers principaux sont:

- `build/index_wasm.html` : Page HTML pour la version WebAssembly
- `build/wasm/app.wasm` : Application compilée en WebAssembly
- `build/wasm/ruby.wasm` : Runtime Ruby WebAssembly
- `build/wasm/package/` : Fichiers JavaScript pour l'intégration WebAssembly

## Hot Reloading

En mode serveur (`--serve`), les modifications apportées aux fichiers dans le répertoire `app/` sont automatiquement détectées et déclenchent une recompilation de la version Opal.