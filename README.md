# das-developers Homebrew tap

Homebrew formulae for the das family of space physics data tools.

| Formula | Contents |
|---------|----------|
| `das2c` | das2/das3 stream utilities, plus the static `libdas3.a` and headers for building against das2C |

Bottles are built for Apple Silicon Macs.  Intel Macs aren't supported at present.

The `das2c` formula downloads [CDF](https://cdf.gsfc.nasa.gov/) and
[CSPICE](https://naif.jpl.nasa.gov/naif/toolkit.html) from their publishers
at build time and links them statically into the programs.  Their libraries
are not installed.

Quick start: `brew install das-developers/das/das2c`

## How do I install these formulae?

`brew install das-developers/das/<formula>`

Or `brew tap das-developers/das` and then `brew install <formula>`.

Or, in a `brew bundle` `Brewfile`:

```ruby
tap "das-developers/das"
brew "<formula>"
```

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
