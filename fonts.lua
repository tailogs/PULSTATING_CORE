local M = {}

local lastClickTime = 0
local clickCooldown = 0.2

local function checkTextClick(x, y, text, link)
    if not link or link == "" then
        return false
    end

    local mx, my = love.mouse.getPosition()
    local textWidth = love.graphics.getFont():getWidth(text)
    local textHeight = love.graphics.getFont():getHeight()

    if mx > x and mx < x + textWidth and my > y and my < y + textHeight then
        love.graphics.setColor(1, 0.8, 0.8)
        if love.mouse.isDown(1) and love.timer.getTime() - lastClickTime > clickCooldown then
            love.system.openURL(link)
            lastClickTime = love.timer.getTime()
            return true
        end
    end
    return false
end

function M.drawFontScumbriaRegular(size, color, text, x, y, align, limitWidth, link)
    local font = love.graphics.newFont("fonts/Scumbria/Scumbria_Regular.otf", size)
    love.graphics.setFont(font)
    love.graphics.setColor(color.r, color.g, color.b, color.a or 1)

    if limitWidth then
        love.graphics.printf(text, x, y, limitWidth, align or "left")
    else
        love.graphics.print(text, x, y)
    end

    if link then
       checkTextClick(x, y, text, link)
    end
end

function M.drawFontScumbriaBold(size, color, text, x, y, align, limitWidth, link)
    local font = love.graphics.newFont("fonts/Scumbria/Scumbria_Bold.otf", size)
    love.graphics.setFont(font)
    love.graphics.setColor(color.r, color.g, color.b, color.a or 1)

    if limitWidth then
        love.graphics.printf(text, x, y, limitWidth, align or "left")
    else
        love.graphics.print(text, x, y)
    end

    if link then
       checkTextClick(x, y, text, link)
    end
end

function M.drawFontSturkopfGrotesk(size, color, text, x, y, align, limitWidth, link)
    local font = love.graphics.newFont("fonts/SturkopfGrotesk/SturkopfGrotesk.ttf", size)
    love.graphics.setFont(font)
    love.graphics.setColor(color.r, color.g, color.b, color.a or 1)

    if limitWidth then
        love.graphics.printf(text, x, y, limitWidth, align or "left")
    else
        love.graphics.print(text, x, y)
    end

    if link then
       checkTextClick(x, y, text, link)
    end
end

return M

