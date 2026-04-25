local M = {}

function M.drawTextWithProgress(text, x, y, fontSize, progress, maxProgress, color, progressColor)
    print("Drawing text: " .. text)

    love.graphics.setFont(love.graphics.newFont(fontSize))
    love.graphics.setColor(color or {1, 1, 1})

    love.graphics.print(text, x, y)

    if progress ~= nil and maxProgress ~= nil then
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", x, y + fontSize + 5, 200, 10)

        love.graphics.setColor(progressColor or {0, 1, 0})
        love.graphics.rectangle("fill", x, y + fontSize + 5, (progress / maxProgress) * 200, 10)
    end
end

return M
