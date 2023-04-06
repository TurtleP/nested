local path = (...):gsub("%.classes.+", "")

local assert = require(path .. ".libraries.batteries.assert")
local Class  = require(path .. ".libraries.batteries.class")

---@class Test
local Test = Class({ name = "TestCase" })
Test.Status =
{
    STATUS_PASS = "PASSED",
    STATUS_FAIL = "FAILED",
    STATUS_UNKNOWN = "UNKNOWN"
}

---Private set up. Calls *:setUp.
---@param context table
function Test:_setUp(context)
end

---Private tear down. Calls *:tearDown.
function Test:_tearDown()
end

---Called before the test is executed
---@param context table Holds context information
function Test:setUp(context)
end

---Called after the test is executed
function Test:tearDown()
end

---Creates a new Test
---@param name string The name of the Test
---@param description? string The description of the Test
function Test:new(name, description)
    assert(type(name) == "string" and #name > 0, "Name was not a string or was empty.")
    assert(type(description) == "string" or type(description) == "nil", "Description must be a string or nil.")

    self.name = name

    self.run = function()
    end

    self.description = description or ""
    self.parameters  = {}

    self.log  = nil
    self.total_tasks = 1

    self.assert = assert

    -- status of all tests
    self.context = {}

    -- overall status
    self.status = Test.Status.STATUS_UNKNOWN
    self.statuses = {}

    self.failed = false

    return self
end

---Sets the Test Case's description
---@param description string
function Test:describe(description)
    assert(type(description) == "string" and #description > 0)

    self.description = description
end

function Test:onCompleted(message, ...)
    self:_tearDown()

    if not message then
        table.insert(self.statuses, Test.Status.STATUS_PASS)
    end

    self.log:info("Duration: " .. self.log:getWriteTimeDisplay())

    if #self.statuses == self.total_tasks then
        if self.status ~= Test.Status.STATUS_FAIL then
            self.status = Test.Status.STATUS_PASS
        end

        self.log:info("Overall Status: " .. self.status)
    else
        self.log:info("Status: " .. self.statuses[#self.statuses])
        if self.statuses[#self.statuses] == Test.Status.STATUS_FAIL then
            self.log:info("Traceback: " .. message)
        end
    end
end

function Test:onFailure()
    table.insert(self.statuses, Test.Status.STATUS_FAIL)
    self.status = Test.Status.STATUS_FAIL
end

---Attaches a runner function to the test.
---@param func function
---@param parameters table
function Test:attach(func, parameters)
    assert(type(func) == "function", "Runner is not a function")

    self.run = func
    self.parameters = parameters or {}

    return self
end

function Test:hasParams()
    return #self.parameters > 0
end

function Test:getParams()
    return self.parameters
end

function Test:getStatus()
    return self.status
end

function Test:getOverallStatus()
    return self.status
end

---Sleep the test for a duration
---@param duration number The duration to sleep for
function Test:sleep(duration)
    self.context.sleep(duration)
end

return Test
