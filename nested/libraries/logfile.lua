local got_love, love = pcall(require, "love")

local open_file = (not got_love and io.open) or love.filesystem.newFile
local get_time  = (not got_love and os.time) or love.timer.getTime

local floor = math.floor
local mod   = math.mod

local no_op_func = function() end

if got_love and love._version_major >= 12 then
    open_file = love.filesystem.openFile
end

---@class Log
local Log = {}
Log.__index = Log

local levels =
{
    trace = 1,
    debug = 2,
    info  = 3,
    warn  = 4,
    error = 5,
    fatal = 6
}

local default_config =
{
    level = "info",
    path = "log",
    format = "$datetime $level $source$sep$line [$time_since_last_write] $message",
    datetime_format = "%Y-%m-%d %H:%M:%S",
    source_info = function()
        local info = debug.getinfo(3, "Sl")
        return { source = info.short_src, line = info.currentline }
    end,
    name_append_time = true
}

local function apply_template(template, sub)
    local result = template
    for key, value in pairs(sub) do
        result = result:gsub("%$" .. key, value)
    end
    return result
end

---Creates a new Log with the filename and config
---@param filename string The name of the log without the extension
---@param config { level: string, path: string, format: string, datetime_format: string, source_info: function }
---@return Log
function Log.new(filename, config)
    local instance = setmetatable({}, Log)
    assert(filename and type(filename) == "string")

    instance.last_write = get_time()
    instance.first_write = instance.last_write

    instance.config = default_config

    instance:set_config(config)
    instance.path = instance.config.name_append_time and (filename .. "_" .. os.time()) or filename

    instance.file = open_file(instance.path .. ".log", "a")
    instance.name = filename

    instance.buffer = {}

    return instance
end

function Log:set_config(config)
    config.level = config and config.level or default_config.level
    assert(levels[config.level], "Invalid log level " .. tostring(config.level))

    config.datetime_format = config and config.datetime_format or default_config.datetime_format
    local ok, err = pcall(os.date, config.datetime_format)
    assert(ok, "Invalid datetime format: " .. err)

    if not config.source_info then
        self.config.source_info = no_op_func
    end

    for key, value in pairs(config) do
        self.config[key] = value
    end
end

for level, _ in pairs(levels) do
    Log[level] = function(self, message, ...)
        self:write_level(level:upper(), message, ...)
    end
end

function Log:getWriteTimeOffset()
    local time = get_time() - self.last_write
    self.last_write = get_time()
    return time
end

function Log:getWriteTimeDisplay(time)
    local offset = time or self:getWriteTimeOffset()

    if offset < 0.001 then
        return "< 1ms"
    end

    local hours = floor(offset / 3600)
    local minutes = floor((offset % 3600) / 60)
    local seconds = offset % 60

    return ("%02d:%02d:%05.3f"):format(hours, minutes, seconds)
end

function Log:getOverallTimeDisplay()
    local time = get_time() - self.first_write
    return self:getWriteTimeDisplay(time)
end

---Write directly to the log
---@param message string
---@vararg any format variables
function Log:write_raw(message, ...)
    assert(message and type(message) == "string", "bad argument #2: message cannot be nil")

    local formatted_message = message:format(...)

    self.file:write(formatted_message .. "\n")
    table.insert(self.buffer, formatted_message)
end

---Write to the Log without a trace level
---@param message any
---@vararg any format variables
function Log:write(message, ...)
    assert(message and type(message) == "string", "bad argument #2: message cannot be nil")

    self:write_level("", message, ...)
end

---Write to the Log \
---Note: There are convinience functions, e.g. `Log:info(message, ...)` - use those instead!
---@param level string log level to use
---@param message string formattable message to write
---@vararg any format variables
function Log:write_level(level, message, ...)
    if level and levels[self.config.level] > levels[level:lower()] then
        return
    end

    assert(message and type(message) == "string", "bad argument #2: message cannot be nil")

    local source_info = self.config.source_info()

    message = message:format(...)

    local formatted_message = apply_template(self.config.format, {
        datetime              = os.date(self.config.datetime_format),
        level                 = level,
        source                = (source_info and source_info.source or ""),
        sep                   = (source_info and ":" or ""),
        line                  = (source_info and source_info.line or ""),
        time_since_last_write = self:getWriteTimeOffset(),
        message               = message
    }):gsub("%s+", " ")

    self:write_raw(formatted_message)
end

return setmetatable(Log, {
    __newindex = function (self, key, value)
        if levels[key] then
            error("Cannot set value for log level")
        end
    end,
    __call = function(_, filepath, config)
        return Log.new(filepath, config or {})
    end
})
