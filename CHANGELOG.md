## [2018.X.X]

### Added
- `--case` flag to the `test` command, to specify which test case to run.

## [2018.10.03]

### Added
- `new-commit` configuration for auto committing when a new project is generated.
- `update-commit` configuration for auto committing when a project's packages are updated.
- `version-latest-commit` configuration for auto committing when a project's dependencies are all updated to their latest versions.
- `version-set-commit` configuration for auto committing when a project's dependency's version is updated.

### Fixed
- JSON key used to get license info during package search

## [2018.09.08]

### Added
- A `-p,--playground` option to the `install` command to install dependencies to an Xcode Playground instead of an SPM project. Playground installs do not support packages the use C module maps.
- `-t,--targets` flag to the `install` command, which specifies which targets the new dependency will be added to.

## [2018.08.11]

### Fixed
- `new` command no longer fails when cleaning new project's manifest.
- Dependency writing when last dependency has a trailing comma.
- White space when adding first dependency to manifest.

### Added
- `--print/-p` flag to `config` command to output config values.
- `test` command, for formatted output when running `swift test`.

## [2018.06.15]

### Added
- `remove` and `version set` commands are case-insensitive.

### Fixed
- Some problem where the package data fetch would hang.

## [2018.05.25]

### Added
- `install-commit` configuration key.
- `remove-commit` configuration key.
- `signed-commits` configuration key.
- Template command group.
- `template list` command.
- Default answer `n` for pre-release version install question.

## [2018.05.22]
 
### Fixed
- Create config file and template directory if they don't exist instead of throwing an error.

## [2018.05.18]
 
### Updated
- Rewrote whole CLI with Console 3, Manifest, and the vapor-community/PackageCatalogAPI. 

## [1.10.0] 2018-02-18

### Added
- `ether version set` command to update the version of a single package.

### Updated
- The RegEx for any command that matches the version of a package, so it handles any version type for a package.

## [1.9.2] 2017-11-27

### Fixed
- The first installation of a dependency in a project no longer breaks the manifest file with bad code injection.

## [1.9.1] 2017-11-17

### Fixed
- Xcode regeneration bar does not run if the xcode flag was not passed in.
- Xcode projects are now opened if the xcode flag is passed into a command.

## [1.9.0] 2017-11-15

### Added
- Short flag options for some command's flags.
- Pre-fetching when updating packages.
- Xcode regeneration options.

## [1.8.0] - 2017-11-4

### Added
- `ether fix-install` to replace automatic cache clearing, which can make the install process take an extended amount of time.

## [1.7.0] - 2017-09-18

### Added
- Ether now supports the SPM 4 manifest API!

## [1.6.2] - 2017-09-18

### Fixed
- The position of the dependencies array when a targets array exists.

## [1.6.1] - 2017-09-15

### Fixed
- Fixed bug that caused the install to fail if the dependencies array is non-existent or empty.

## [1.6.0] - 2017-08-2

### Added
- `ether version all` for viewing installed package versions.

## [1.5.2] - 2017-07-30

### Fixed
- `ether --version` flag; again.

## [1.5.1] - 2017-07-30

### Fixed
- `ether --version` flag.

## [1.5.0] - 2017-07-30

### Added
- `ether --version` and `ether -v` for viewing the version of Ether you are using.

## [1.4.2] - 2017-06-2

### Fixed
- Packages are updated after their version is updated.

## [1.4.1] - 2017-06-2

### Changed
- Network requests now use synchronous `get(url parameter)`
- `version latest` only rewrites `Package.swift` once.


## [1.4.0] - 2017-06-2

### Added
- `ether version latest` for updating all packages to their latest version.

## [1.3.0] - 2017-05-31

### Added
- `ether new` for creating new projects.

## [1.2.1] - 2017-05-31

### Fixed
- Attribution for `shell()`
- Fail error typo for the template command.

## [1.2.0] - 2017-05-30

### Added
- Saving and removing project templates

## [1.1.0] - 2017-05-25

### Added
- Updating Ether

### Fixed
- `ether help`

## [1.0.1] - 2017-05-25

### Fixed
- `ether help`

## [1.0.0] - 2017-05-25

### Changed
- Package name {Haze => Ether}

## [0.4.0] - 2017-05-24

### Added
- Package removal

## [0.3.0] - 2017-05-24

### Added
- Package Updating

## [0.2.0] - 2017-05-24

### Added
- Package installation

## [0.1.0] - 2017-05-24

### Added
- Package Searching
