# Twm

TWM (Tailwind Merge) is an Elixir port of the popular TypeScript `tailwind-merge` library. It efficiently merges Tailwind CSS classes without style conflicts by intelligently handling conflicting utilities.

## Features

- ✅ **Conflict Resolution**: Automatically removes conflicting Tailwind classes
- ✅ **Performance Optimized**: Built-in LRU cache for repeated class combinations
- ✅ **Extensible**: Support for custom configurations and class groups
- ✅ **Multiple Input Types**: Accepts strings, lists, and nested structures
- ✅ **Arbitrary Values**: Full support for Tailwind's arbitrary value syntax
- ✅ **TypeScript Compatibility**: Maintains API compatibility with the original library

## Quick Start

```elixir
# Basic usage
Twm.merge("px-2 py-1 px-3")
# => "py-1 px-3"

# Conflicting classes are resolved
Twm.merge("bg-red-500 bg-blue-500")
# => "bg-blue-500"

# List inputs are supported
Twm.merge(["flex", "items-center", "justify-center"])
# => "flex items-center justify-center"

# Complex conflicts are handled
Twm.merge("pt-2 pt-4 pb-3")
# => "pt-4 pb-3"
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `twm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:twm, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/twm>.

## Advanced Usage

### Custom Configuration

```elixir
# Create a custom merge function with extended configuration
custom_merge = Twm.extend_tailwind_merge(
  cache_size: 100,
  extend: [
    class_groups: [
      "custom-group": ["custom-class-1", "custom-class-2"]
    ]
  ]
)

custom_merge.("custom-class-1 custom-class-2")
# => "custom-class-2"
```

### Performance Testing

Run benchmarks to test performance:

```bash
# Quick development benchmarks
mix run scripts/quick_benchmark.exs

# Comprehensive benchmarks
mix run test/twm_benchmark.exs
```

See [BENCHMARKS.md](BENCHMARKS.md) for detailed performance information.

## API Reference

### Core Functions

- `Twm.merge/1` - Main merge function
- `Twm.tw_merge/1` - Alias for merge (compatibility)
- `Twm.extend_tailwind_merge/1` - Create custom merge functions
- `Twm.create_tailwind_merge/1` - Create merge functions with custom config

### Configuration

The library supports extensive configuration options including:
- Custom class groups
- Cache size configuration
- Conflicting class group definitions
- Experimental parsing options

## Development

### Running Tests

```bash
mix test
```

### Running Benchmarks

```bash
# Quick benchmarks for development
mix run scripts/quick_benchmark.exs

# Full benchmark suite
mix run test/twm_benchmark.exs
```

### Code Quality

```bash
# Format code
mix format

# Run linter
mix credo

# Type checking
mix dialyzer
```

## Comparison with TypeScript Version

This Elixir port maintains full feature parity with the original TypeScript library while leveraging Elixir's strengths:

- **Immutable Data Structures**: More predictable and safer
- **Pattern Matching**: Elegant handling of different input types
- **Fault Tolerance**: Graceful error handling
- **Concurrency**: Better performance in concurrent environments
- **Functional Style**: Clean, composable API design

Performance is comparable to or better than the original in most scenarios, with the added benefit of Elixir's excellent concurrency model.

