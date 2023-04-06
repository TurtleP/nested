local path = (...):gsub("%.init.+", "")

local nested =
{
    LICENSE = "",
    _VERSION = "0.1.0",

    TestCase  = require(path .. ".classes.testcase"),
    TestSuite = require(path .. ".classes.suite"),
}

function nested.loadModule(directory, results)
    assert(type(directory) == "string", "argument #1 must be a string")

    if not love.filesystem.getInfo(directory, "directory") then
        error(("bad argument #1: path '%s' not found"):format(directory))
    end

    if not results then
        results = {}
    end

    local files = love.filesystem.getDirectoryItems(directory)

    for _, filename in ipairs(files) do
        local info = love.filesystem.getInfo(directory .. "/" .. filename)

        if info.type == "file" and filename:match("%.lua$") then
            local filepath = ("%s/%s"):format(directory, filename)

            table.insert(results, filepath)
        elseif info.type == "directory" then
            nested.loadModule(directory .. "/" .. filename, results)
        end
    end

    return results
end

return nested
