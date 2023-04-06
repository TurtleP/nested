local path = (...):gsub("%.classes.+", "")

local Class = require(path .. ".libraries.batteries.class")
local async = require(path .. ".libraries.batteries.async")
local log   = require(path .. ".libraries.logfile")

local TestSuite = Class()

local function setUp(self, context, parameters)
    for key, value in pairs(context) do
        self.context[key] = value
    end

    self.log = log(context.name, { level = "trace", format = "$datetime|$level|$message" })

    local buffer = {}
    for index = 1, #parameters do
        local current_parameter = parameters[index]

        if type(current_parameter) == "table" then
            table.insert(buffer, "{ " .. table.concat(current_parameter, ", ") .. " }")
        elseif type(current_parameter) == "string" then
            table.insert(buffer, "\"" .. tostring(current_parameter) .. "\"")
        else
            table.insert(buffer, tostring(current_parameter))
        end
    end
    self.log:trace("Setting up..")

    if self.description then
        self.log:info(self.description)
    end

    if #parameters > 0 then
        self.log:debug("Detected parameters: " .. table.concat(buffer, ", "))
    end

    return self:setUp()
end

local function tearDown(self)
    self.log:trace("Tearing down..")

    return self:tearDown()
end

local function load_test(filepath)
    filepath = filepath:gsub("/", "%."):gsub("%.lua", "")

    local success, test = pcall(require, filepath)
    assert(success and test.type and test:type() == "TestCase", ("Failed to load test case at '%s'."):format(filepath))

    return { class = test, name = test.name, runner = test.run }
end

---Creates a new Test Suite that holds Tests
---@param name string
---@param filepath string|table Filepath or table of filepaths
function TestSuite:new(name, filepath)
    if type(filepath) == "string" and not love.filesystem.getInfo(filepath, "file") then
        error(("cannot add '%s' to Test Suite: not a file"):format(filepath))
    end

    self.name = name
    self.kernel = async()

    self.tasks = {}
    local filepath_type = type(filepath)

    if filepath_type == "string" then
        load_test(filepath)
    elseif filepath_type == "table" then
        for index = 1, #filepath do
            load_test(filepath[index])
        end
    end

    -- set up the kernel
    self:setUpKernel()
end

---Create a new task
---@param task_class Test
---@param context { wait: function, name: string }
---@param parameters table?
local function new_task(task_class, context, parameters)
    task_class._setUp = setUp(task_class, context, parameters)
    task_class:run(unpack(parameters))
end

function TestSuite:setUpKernel()
    local context = { sleep = self.kernel.wait }

    for index = 1, #self.tasks do
        context.name = self.tasks[index].name

        local class = self.tasks[index].class
        class._tearDown = tearDown

        local params = class:getParams()

        local function onCompleted(message, ...)
            class:onCompleted(message, ...)
        end

        local function onFailure(message)
            class:onFailure(message)
        end

        if class:hasParams() then
            self.tasks[index].class.total_tasks = #params
            for parameter = 1, #params do
                self.kernel:call(function()
                    new_task(class, context, params[parameter])
                end, nil, onCompleted, onFailure)
            end
        else
            self.kernel:call(function()
                new_task(class, context)
            end, nil, class.onCompleted, class.onFailure)
        end
    end
end

function TestSuite:update()
    self.kernel:update()
end

return TestSuite
