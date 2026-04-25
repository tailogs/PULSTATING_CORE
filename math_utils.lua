local M = {}

function M.add(a, b)
    return a + b
end

function M.subtract(a, b)
    return a - b
end

function M.sign(x)
    return (x > 0 and 1) or (x < 0 and -1) or 0
end

return M
