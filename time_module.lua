local M = {}

function M.formatTime(seconds)
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60

    local timeStr = ""
    if days > 0 then
        timeStr = timeStr .. days .. "d "
    end
    if hours > 0 or days > 0 then
        timeStr = timeStr .. hours .. "h "
    end
    if minutes > 0 or hours > 0 or days > 0 then
        timeStr = timeStr .. minutes .. "m "
    end
    timeStr = timeStr .. string.format("%.2fs", secs)

    return timeStr
end

return M