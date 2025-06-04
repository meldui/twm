# TWM (Tailwind Merge) Elixir Porting Plan & Cursor Rules

## Project Overview

Port the TypeScript `tailwind-merge` library to Elixir as `twm`, maintaining all functionality while following Elixir conventions. The library merges Tailwind CSS classes without style conflicts by intelligently handling conflicting utilities.

# TWM Elixir Port - Cursor Rules

## Project Context
- Porting tailwind-merge TypeScript library to Elixir as `twm`
- Main module name: `Twm`
- Must maintain all functionality from original library
- Follow Elixir conventions and patterns
- Test-driven development approach
- Port tests first, then implement functionality

## Elixir Conventions to Follow

### Naming Conventions
- Library name: `twm`
- Main module: `Twm`
- Sub-modules: PascalCase (e.g., `Twm.Config`, `Twm.Merger`)
- Function names: snake_case (e.g., `merge/1`, `parse_class/1`)
- Variable names: snake_case
- Constants: @module_attribute format
- Private functions: prefix with underscore

### Code Organization
- One module per file
- Group related functions together
- Use `@moduledoc` and `@doc` for documentation
- Use `@spec` for function specifications
- Follow the GenServer pattern for stateful components if needed

### Data Structures
- Use Maps instead of JavaScript objects
- Use Lists instead of JavaScript arrays
- Use Atoms for constants and small enums
- Use Structs for complex data types
- Consider using Keyword lists for options

### Error Handling
- Use `{:ok, result}` | `{:error, reason}` pattern
- Use `!` suffix for functions that raise exceptions
- Pattern match extensively instead of if/else chains
- Use `with` for complex operation chains

### Performance Considerations
- Use binary pattern matching for string operations
- Consider using ETS for caching if needed
- Implement tail recursion where applicable
- Use Stream for large data processing

## Project Structure
```
twm/
├── lib/
│   ├── twm.ex                         # Main API module
│   ├── twm/
│   │   ├── config.ex                  # Configuration handling
│   │   ├── merger.ex                  # Core merging logic
│   │   ├── parser.ex                  # Class parsing
│   │   ├── validator.ex               # Class validation
│   │   ├── cache.ex                   # Caching mechanism
│   │   └── utilities.ex               # Helper functions
│   └── twm/
│       └── application.ex             # OTP Application (if needed)
├── test/
│   ├── twm_test.exs
│   ├── support/
│   │   └── test_helper.ex
│   └── twm/
│       ├── config_test.exs
│       ├── merger_test.exs
│       ├── parser_test.exs
│       ├── validator_test.exs
│       └── cache_test.exs
├── mix.exs
└── README.md
```

## Implementation Guidelines

### 1. Start with Tests
- Port all existing tests to ExUnit format
- Maintain the same test structure and coverage
- Use ExUnit's `describe` and `test` macros
- Use `assert`, `refute`, and pattern matching for assertions

### 2. API Design
- Main function: `Twm.merge/1` (primary API)
- Alternative: `Twm.tw_merge/1` (for compatibility)
- Configuration: `Twm.extend/1` function
- Cache management: `Twm.Cache` module
- Follow Elixir's pipe operator patterns

### 3. TypeScript to Elixir Mappings
- `interface` → `defstruct` or `@type`
- `type` → `@type` or `@typep`
- `enum` → atoms or module constants
- `Map<K, V>` → `%{key => value}`
- `Array<T>` → `[T]`
- `string` → `String.t()`
- `number` → `integer()` or `float()`
- `boolean` → `boolean()`

### 4. Function Patterns
```elixir
# Public API functions
@spec merge(classes) :: String.t()
def merge(classes) when is_binary(classes) do
  # Implementation
end

def merge(classes) when is_list(classes) do
  classes
  |> Enum.join(" ")
  |> merge()
end

# Alternative API for compatibility
@spec tw_merge(classes) :: String.t()
def tw_merge(classes), do: merge(classes)

# Private helper functions
defp parse_class(class_string) do
  # Implementation
end
```

### 5. Configuration Handling
- Use Application environment for default config
- Support runtime configuration via keyword lists
- Implement config validation
- Support extending default configuration

### 6. Error Handling Patterns
```elixir
# For functions that can fail
def parse_config(config) do
  case validate_config(config) do
    {:ok, validated_config} -> {:ok, process_config(validated_config)}
    {:error, reason} -> {:error, reason}
  end
end

# For functions that should always succeed
def merge_classes!(classes) do
  case merge_classes(classes) do
    {:ok, result} -> result
    {:error, reason} -> raise Twm.Error, reason
  end
end
```

## Development Workflow

1. **Phase 1: Setup & Core Tests**
   - Create Elixir project structure
   - Port basic merge functionality tests
   - Implement core `tw_merge/1` function

2. **Phase 2: Configuration System**
   - Port configuration-related tests
   - Implement configuration parsing and validation
   - Support for extending default configuration

3. **Phase 3: Advanced Features**
   - Port caching tests
   - Implement caching mechanism
   - Port validation tests
   - Implement class validation logic

4. **Phase 4: Edge Cases & Optimization**
   - Port remaining edge case tests
   - Optimize performance
   - Add comprehensive documentation

## Quality Standards

- All functions must have proper typespecs
- All public functions must have documentation
- Test coverage should be > 90%
- Follow Credo guidelines for code quality
- Use Dialyzer for static analysis
- Format code with `mix format`

## Testing Strategy

- Use ExUnit for all tests
- Property-based testing with StreamData for complex scenarios
- Benchmark tests for performance-critical functions
- Integration tests for end-to-end scenarios
- Use mocks sparingly, prefer pure functions

## Documentation

- All modules need `@moduledoc`
- All public functions need `@doc`
- Include examples in documentation
- Generate docs with ExDoc
- Maintain API reference documentation
```

## Detailed Implementation Plan

### Phase 1: Project Setup & Basic Functionality (Week 1)

#### Setup Tasks:
1. **Create new Elixir project**
   ```bash
   mix new twm --sup
   cd twm
   ```

2. **Configure dependencies in `mix.exs`**
   ```elixir
   defp deps do
     [
       {:ex_doc, "~> 0.30", only: :dev, runtime: false},
       {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
       {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
       {:stream_data, "~> 0.6", only: :test}
     ]
   end
   ```

3. **Port basic merge tests**
   - Start with simplest test cases from the original library
   - Focus on basic class merging functionality
   - Test cases like: `Twm.merge("px-2 py-1 px-3")` → `"py-1 px-3"`

#### Core Implementation:
1. **Create `Twm` main module**
   ```elixir
   defmodule Twm do
     @moduledoc """
     Utility function to efficiently merge Tailwind CSS classes without style conflicts.
     """

     @spec merge(String.t() | [String.t()]) :: String.t()
     def merge(classes)

     @spec tw_merge(String.t() | [String.t()]) :: String.t()
     def tw_merge(classes), do: merge(classes)
   end
   ```

2. **Implement basic class parsing**
   - Split classes by whitespace
   - Handle multiple class inputs
   - Basic conflict resolution

### Phase 2: Configuration System (Week 2)

#### Configuration Tests:
1. Port configuration-related tests
2. Test custom configuration scenarios
3. Test configuration extension functionality

#### Implementation:
1. **Create `Twm.Config` module**
   ```elixir
   defmodule Twm.Config do
     @moduledoc """
     Configuration management for Twm.
     """

     defstruct [
       :cache_size,
       :theme,
       :class_groups,
       :conflicting_class_groups
     ]
   end
   ```

2. **Implement configuration parsing and validation**
3. **Support for extending default configuration**

### Phase 3: Advanced Features (Week 3)

#### Advanced Tests:
1. Port caching mechanism tests
2. Port class validation tests
3. Port edge case handling tests

#### Implementation:
1. **Create `Twm.Cache` module**
   - Implement LRU cache using ETS or Agent
   - Support configurable cache size
   - Handle cache invalidation

2. **Create `Twm.Validator` module**
   - Implement class validation logic
   - Handle arbitrary value validation
   - Support custom validators

### Phase 4: Optimization & Documentation (Week 4)

#### Final Tasks:
1. **Performance optimization**
   - Benchmark critical functions
   - Optimize string operations
   - Consider binary pattern matching

2. **Documentation**
   - Complete API documentation
   - Add usage examples
   - Create migration guide from TypeScript version

3. **Quality assurance**
   - Run Credo for code quality
   - Run Dialyzer for type checking
   - Ensure test coverage > 90%

## Key Differences from TypeScript Version

### Data Structures:
- **Objects** → **Maps**: `%{key => value}`
- **Arrays** → **Lists**: `[item1, item2, item3]`
- **Tuples** → **Tuples**: `{:ok, result}` for return values

### Function Patterns:
- **Callbacks** → **Higher-order functions** or **Behaviours**
- **Promises** → **Tasks** or **GenServers** (if async needed)
- **Classes** → **Modules** with structs and functions

### Error Handling:
- **Try/catch** → **Pattern matching** with `{:ok, result}` | `{:error, reason}`
- **Throwing exceptions** → **Raising exceptions** or returning error tuples

### String Processing:
- **Regex** → **Elixir Regex** module
- **String methods** → **String** module functions
- **Template literals** → **String interpolation**

## Success Criteria

✅ **All original functionality preserved**

✅ **All tests passing**

✅ **Performance comparable to original**

✅ **Follows Elixir conventions**

✅ **Comprehensive documentation**

✅ **Type specifications for all functions**

✅ **No Credo or Dialyzer warnings**

✅ **Easy to use API**

## Next Steps

1. **Start with Phase 1**: Create the project structure and port the most basic tests
2. **Implement incrementally**: Don't try to port everything at once
3. **Test continuously**: Run tests after each small change
4. **Seek feedback**: Review code regularly and get community input
5. **Document as you go**: Write documentation alongside implementation

This plan ensures a systematic approach to porting while maintaining the library's functionality and improving it with Elixir's strengths.
