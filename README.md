
# nested

A testing framework for LÖVE projects. 


## API Reference

#### Create a Test Suite

```lua
local nested = require("nested")
local test_suite = nested.TestSuite(name, filepaths)
```

| Parameter   | Type            | Description                              |
| :-----------|:----------------|:-----------------------------------------|
| `name`      | `string`        | The name of the Test Suite               |
| `filepaths` | `table\|string` | A filepath or table of filepaths to load |

In order for tests to run, you must invoke the update method in love.update:

```lua
function love.update(dt)
    test_suite:update()
end
```

#### Create a Test Case

```lua
local nested = require("nested")
local test_case = nested.TestCase(name, description)
```

| Parameter     | Type     | Description                             |
|:--------------|:---------|:----------------------------------------|
| `name`        | `string` | **Required**. The name of the Test Case |
| `description` | `string` | The description of the Test Case        |

#### Attach a Runner to the Test Case

```lua
local params = 
{
    { 4, 4 }
}

-- self refers to the Test Case
local function runner(self, a, b)
end

return test_case:attach(runner, params)
```

| Parameter     | Type     | Description                                                                                      |
|:--------------|:---------|:-------------------------------------------------------------------------------------------------|
| `runner`      | `function` | **Required**. The function to execute                                                          |
| `params`      | `table`    | A table of different parameters. The more tables, the more re-runs with new parameters.        |

#### Testing in the Runner

nested comes [bundled with batteries](https://github.com/1bardesign/batteries), but only `async`, `class`, and `assert`. In the runner, `self` refers to the Test Case which holds the assert functions from `batteries` as a member variable. This prevents exposing it globally and makes it easier for the end-user to make their assertions instead of requiring the file for every test themselves.

```lua
-- self refers to the Test Case
local function runner(self, a, b)
    self.assert:equal(a, b, "extra message!")
end
```

## Usage/Examples

```lua
-- main.lua
local nested = require("nested")

local first_test_suite = nested.TestSuite("My First Test Suite", "tests/something.lua")

function love.update(_)
    first_test_suite:update()
end

-- test/something.lua
local nested = require("nested")

local Example = nested.TestCase("Hello World")
Example:describe("This makes sure two numbers added as a total equal another number.")

local params = 
{
    { 2 + 2,      4 }
    { 6 + 9, "nice" }
}

local function runner(self, total, expected)
    self.assert:equal(total, expected)
end

return Example:attach(runner, params)
```


## To-Do
- Make it easier to configure the log files in the Test Suite without editing the core lua file
- Possibly allow for status updates to be output through the console (test passing/failing with test suite name)