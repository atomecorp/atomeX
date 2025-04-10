# atomeX

Un environnement hybride de développement Ruby qui prend en charge à la fois la compilation via Opal (Ruby vers JavaScript) et Ruby WebAssembly.

## Pour commencer

### Prérequis

- Ruby (version 3.0 ou supérieure recommandée)
- Bundler
- npm (optionnel, pour certaines fonctionnalités)

### Installation

```bash
# Cloner le dépôt
git clone https://github.com/yourusername/atomeX.git
cd atomeX

# Installer les dépendances
bundle install
```

### Compilation et exécution

```bash
# Compiler le projet
ruby builder.rb

# Compiler et lancer le serveur de développement
ruby builder.rb --serve
```

Ouvrez l'un des fichiers suivants dans votre navigateur:
- `build/index_opal.html` (version JavaScript)
- `build/index_wasm.html` (version WebAssembly)

## Documentation

Pour plus de détails sur la structure du projet et l'API, consultez [DOCUMENTATION.md](DOCUMENTATION.md).