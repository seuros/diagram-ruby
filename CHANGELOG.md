# Changelog

## [1.0.0](https://github.com/seuros/diagram-ruby/compare/diagram/v0.2.1...diagram/v1.0.0) (2025-03-31)


### ⚠ BREAKING CHANGES

* This is a complete architectural overhaul. The public API is incompatible with previous versions (pre-0.3.0) but i think i was the only one using the gem.
    - Diagram classes no longer inherit from `Dry::Struct`.
    - Element classes are now under `Diagrams::Elements` and use `Dry::Struct`.
    - Internal data structures (e.g., `sections`, `links`) replaced with standardized element arrays (`nodes`, `edges`, `slices`, etc.).
    - Old `type`, `to_json`, validation, and plotting methods removed from subclasses; use `Base` methods or implement separately.
    - Requires Ruby >= 3.3.0.

### Features

* add .from_hash and .from_json ([82b032b](https://github.com/seuros/diagram-ruby/commit/82b032b8f4a4bb8f9d85f462de26a6a0d7d775a7))
* rebuild diagram gem with modern architecture ([0c86060](https://github.com/seuros/diagram-ruby/commit/0c860607b1ca15025c6599ca52754635ca9d374d))

## [0.2.1](https://github.com/seuros/diagram-ruby/compare/diagram/v0.2.0...diagram/v0.2.1) (2024-02-03)


### Bug Fixes

* update version file ([e5b3853](https://github.com/seuros/diagram-ruby/commit/e5b385353a8d0fd6c904d65f276db481dd39793d))

## [0.2.0](https://github.com/seuros/diagram-ruby/compare/diagram-v0.0.1...diagram/v0.2.0) (2024-02-03)


### Features

* Add more abstract diagrams ([59df905](https://github.com/seuros/diagram-ruby/commit/59df90526f6e7168f66968c929ede42d97729cd2))
* add warning ([9291c70](https://github.com/seuros/diagram-ruby/commit/9291c70987a4855f64254240ec285240cd2b9987))
