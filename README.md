# TWM (Tailwind Merge)

**TWM** is an Elixir port of the popular JavaScript/TypeScript [`tailwind-merge`](https://github.com/dcastil/tailwind-merge) library. It efficiently merges Tailwind CSS classes without style conflicts by intelligently handling conflicting utilities.

## Attribution

This library is a port of the excellent [`tailwind-merge`](https://github.com/dcastil/tailwind-merge) library (v3.3.0) by [Dany Castillo](https://github.com/dcastil). The original JavaScript/TypeScript implementation provides the foundation and algorithms that make this Elixir version possible.

**Original Library:**
- **Name:** tailwind-merge
- **Author:** Dany Castillo
- **License:** MIT
- **Repository:** https://github.com/dcastil/tailwind-merge
- **Version:** 3.3.0

## Purpose

TWM solves the problem of conflicting Tailwind CSS classes when dynamically combining class strings. When you have multiple sources of Tailwind classes (props, conditional logic, component composition), you often end up with conflicts like:

```elixir
# Without TWM - both padding classes are applied, causing unexpected results
"px-2 px-4"  # Both px-2 and px-4 are in the final output

# With TWM - conflicts are resolved intelligently
Twm.merge("px-2 px-4")
# => "px-4"  # Only the last conflicting class is kept
```

## Features

- ✅ **Conflict Resolution**: Automatically removes conflicting Tailwind classes
- ✅ **Performance Optimized**: Built-in LRU cache for repeated class combinations
- ✅ **Extensible**: Support for custom configurations and class groups
- ✅ **Multiple Input Types**: Accepts strings, lists, and nested structures
- ✅ **Arbitrary Values**: Full support for Tailwind's arbitrary value syntax
- ✅ **TypeScript Compatibility**: Maintains API compatibility with the original library
- ✅ **Elixir Native**: Leverages Elixir's strengths for better performance and reliability

## Installation

Add `twm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:twm, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

```elixir
# Basic usage - resolves padding conflicts
Twm.merge("px-2 py-1 px-3")
# => "py-1 px-3"

# Background color conflicts
Twm.merge("bg-red-500 bg-blue-500")
# => "bg-blue-500"

# Complex spacing conflicts
Twm.merge("pt-2 pt-4 pb-3")
# => "pt-4 pb-3"

# Works with lists too
Twm.merge(["flex", "items-center", "justify-center"])
# => "flex items-center justify-center"

# Handles arbitrary values
Twm.merge("p-[20px] p-[30px]")
# => "p-[30px]"

# Modifier conflicts
Twm.merge("hover:bg-red-500 hover:bg-blue-500")
# => "hover:bg-blue-500"
```

## Usage Examples

### With Cache (Default Behavior)

The library automatically uses an LRU cache to optimize performance for repeated class combinations:

```elixir
# First call - computes and caches result
result1 = Twm.merge("px-2 py-1 px-3")
# => "py-1 px-3"

# Second call with same input - returns cached result (faster)
result2 = Twm.merge("px-2 py-1 px-3")
# => "py-1 px-3" (from cache)

# Check cache usage
Twm.Cache.size()  # Returns number of cached entries
```

### Without Cache (Custom Configuration)

For scenarios where you don't want caching, you can create a custom configuration:

```elixir
# Create a configuration without cache
no_cache_config = Twm.Config.extend(cache_size: 0)

# Use the configuration directly
Twm.merge("px-2 px-3", no_cache_config)
# => "px-3" (no caching)
```

### Different Input Types

```elixir
# String input
Twm.merge("flex items-center px-4 px-2")
# => "flex items-center px-2"

# List input
Twm.merge(["flex", "items-center", "px-4", "px-2"])
# => "flex items-center px-2"

# Mixed with nils and false values (filtered out)
Twm.merge(["flex", nil, "items-center", false, "px-4"])
# => "flex items-center px-4"

# Empty inputs
Twm.merge("")        # => ""
Twm.merge([])        # => ""
Twm.merge([nil])     # => ""
```

## Configuration

### Ways to Create Config Structures

TWM provides several ways to create and customize configurations:

#### 1. Using the Default Configuration

```elixir
# Get the default configuration
default_config = Twm.Config.get_default()

# Use with merge
Twm.merge("px-2 px-4", default_config)
# => "px-4"
```

#### 2. Creating a New Configuration from Scratch

```elixir
# Create a completely custom configuration
custom_config = Twm.Config.new(
  cache_size: 100,
  theme: [],
  class_groups: [
    # Define custom class groups
    spacing: ["p-1", "p-2", "p-4", "p-8"],
    colors: ["text-red", "text-blue", "text-green"]
  ],
  conflicting_class_groups: [
    # Define which groups conflict with each other
    spacing: ["margins"],
    colors: ["backgrounds"]
  ],
  conflicting_class_group_modifiers: [],
  order_sensitive_modifiers: []
)

Twm.merge("p-1 p-4", custom_config)
# => "p-4"
```

#### 3. Extending the Default Configuration

```elixir
# Extend with simple options
extended_config = Twm.Config.extend(
  cache_size: 1000,
  prefix: "tw-"
)

# Extend with override (replaces default values)
override_config = Twm.Config.extend(
  override: [
    class_groups: [
      display: ["custom-block", "custom-flex"]
    ]
  ]
)

# Extend with additional values (merges with defaults)
extended_config = Twm.Config.extend(
  extend: [
    class_groups: [
      custom_group: ["custom-class-1", "custom-class-2"]
    ],
    conflicting_class_groups: [
      custom_group: ["display"]
    ]
  ]
)
```

#### 4. Using Configuration Functions

```elixir
# Create a configuration with a function
config_with_fn = Twm.Config.extend(
  default_config,
  fn config ->
    # Modify the configuration
    config
    |> Keyword.update!(:class_groups, fn groups ->
      Keyword.put(groups, :custom_utilities, ["util-1", "util-2"])
    end)
    |> Keyword.update!(:conflicting_class_groups, fn conflicts ->
      Keyword.put(conflicts, :custom_utilities, ["display"])
    end)
  end
)
```


## Performance and Caching

### Cache Configuration

1. As a global cache for the main Twm functionality:

```elixir
defmodule Twm.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Twm.Cache with default configuration
      {Twm.Cache, []}
    ]

    opts = [strategy: :one_for_one, name: Twm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

You can also pass a custom cache name and configuration:

```elixir
defmodule Twm.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Custom configuration
    custom_config = Twm.Config.extend(cache_size: 1000)

    children = [
      # Start the Twm.Cache with custom name and configuration
      {Twm.Cache, [name: :my_twm_cache, config: custom_config]}
    ]

    opts = [strategy: :one_for_one, name: Twm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

```elixir
# Configure cache size
large_cache_config = Twm.Config.extend(cache_size: 2000)

# Use a custom cache name
custom_cache_config = Twm.Config.extend(cache_name: MyApp.TwmCache)

# Disable caching entirely
no_cache_config = Twm.Config.extend(cache_size: 0)
```

### Cache Management

```elixir
# Check cache size
Twm.Cache.size()

# Clear cache
Twm.Cache.clear()

# Resize cache
Twm.Cache.resize(1000)

# Get cache statistics (for monitoring)
{:ok, state} = Twm.Cache.get_state()
```

### Benchmarking

Run benchmarks to test performance in your environment:

```bash
# Quick development benchmarks
mix run test/benchmarks/quick_benchmark.exs

# Comprehensive benchmarks
mix run test/benchmarks/benchmark.exs
```

## Advanced Usage

### Working with Arbitrary Values

```elixir
# Arbitrary padding values
Twm.merge("p-[20px] p-[25px]")
# => "p-[25px]"

# Arbitrary colors
Twm.merge("bg-[#ff0000] bg-[#00ff00]")
# => "bg-[#00ff00]"

# Complex arbitrary values
Twm.merge("grid-cols-[200px_1fr_100px] grid-cols-[300px_1fr]")
# => "grid-cols-[300px_1fr]"
```

### Modifier Handling

```elixir
# Pseudo-class modifiers
Twm.merge("hover:bg-red-500 hover:bg-blue-500 focus:bg-green-500")
# => "hover:bg-blue-500 focus:bg-green-500"

# Responsive modifiers
Twm.merge("sm:p-2 md:p-4 sm:p-3")
# => "md:p-4 sm:p-3"

# Dark mode modifiers
Twm.merge("dark:text-white dark:text-gray-100")
# => "dark:text-gray-100"

# Stacked modifiers
Twm.merge("sm:hover:bg-red-500 sm:hover:bg-blue-500")
# => "sm:hover:bg-blue-500"
```

### Complex Conflict Resolution

```elixir
# Multiple property conflicts
Twm.merge("px-2 py-4 p-3 pt-6")
# => "px-2 py-4 p-3 pt-6" → "p-3 pt-6" (p-3 overrides px-2 py-4, pt-6 overrides p-3's top padding)

# Border conflicts
Twm.merge("border-2 border-4 border-t-8")
# => "border-4 border-t-8"

# Flexbox conflicts
Twm.merge("flex-row flex-col items-start items-center")
# => "flex-col items-center"
```

## API Reference

### Core Functions

- `Twm.merge/1` - Main merge function with default configuration
- `Twm.merge/3` - Merge with custom configuration and options
- `Twm.Config.get_default/0` - Get the default configuration
- `Twm.Config.new/1` - Create a new configuration from scratch
- `Twm.Config.extend/1` - Extend the default configuration
- `Twm.Config.extend/2` - Extend a configuration with a function

### Cache Functions

- `Twm.Cache.start_link/1` - Start the cache GenServer
- `Twm.Cache.get/2` - Get a value from cache
- `Twm.Cache.put/3` - Put a value in cache
- `Twm.Cache.clear/1` - Clear all cache entries
- `Twm.Cache.size/1` - Get current cache size
- `Twm.Cache.resize/2` - Resize the cache

### Validator Functions

The library includes comprehensive validators for different Tailwind value types:

- `Twm.is_arbitrary_value/1` - Check if value is arbitrary (e.g., `[20px]`)
- `Twm.is_arbitrary_length/1` - Check if value is arbitrary length
- `Twm.is_arbitrary_number/1` - Check if value is arbitrary number
- `Twm.is_tshirt_size/1` - Check if value is t-shirt size (xs, sm, md, lg, xl, etc.)
- `Twm.is_integer/1` - Check if value is integer
- `Twm.is_fraction/1` - Check if value is fraction (1/2, 1/3, etc.)

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/twm_test.exs
```

### Code Quality

```bash
# Format code
mix format

# Run linter
mix credo

# Type checking (if dialyzer is configured)
mix dialyzer
```

### Benchmarking

```bash
# Quick benchmarks for development
mix run scripts/quick_benchmark.exs

# Full benchmark suite
mix run test/twm_benchmark.exs
```

### API Compatibility

The Elixir version maintains API compatibility where possible:

```javascript
// TypeScript/JavaScript
import { twMerge } from 'tailwind-merge'
twMerge('px-2 py-1 px-3') // => 'py-1 px-3'
```

```elixir
# Elixir
Twm.merge("px-2 py-1 px-3") # => "py-1 px-3"
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for your changes
5. Ensure all tests pass (`mix test`)
6. Ensure code formatting (`mix format`)
7. Ensure code quality (`mix credo`)
8. Commit your changes (`git commit -am 'Add amazing feature'`)
9. Push to the branch (`git push origin feature/amazing-feature`)
10. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

## Acknowledgments

- **Dany Castillo** and contributors to the original [`tailwind-merge`](https://github.com/dcastil/tailwind-merge) library
- The **Tailwind CSS** team for creating the utility-first CSS framework
- The **Elixir** community for providing an excellent platform for this port

---

**Note**: This is a community-maintained port and is not officially affiliated with the original `tailwind-merge` project or Tailwind CSS.
