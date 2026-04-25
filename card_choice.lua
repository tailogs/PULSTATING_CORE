local M = {}

local game_state = require("game_state")

M.cards = {}
M.selectedCard = nil
M.cardWidth, M.cardHeight = 200, 300

function M.loadCards()
    M.cards = {
        love.graphics.newImage("image/1.png"),
        love.graphics.newImage("image/2.png"),
        love.graphics.newImage("image/3.png"),
    }

    if #M.cards == 0 then
        for i = 1, 3 do
            M.cards[i] = {
                color = {love.math.random(), love.math.random(), love.math.random()},
            }
        end
    end
end

function M.showCards()
    local width, height = love.graphics.getWidth(), love.graphics.getHeight()
    local cardWidth, cardHeight = M.cardWidth, M.cardHeight

    for i, card in ipairs(M.cards) do
        local x = (i - 1) * (cardWidth + 10) + (width - 3 * cardWidth - 20) / 2
        local y = (height - cardHeight) / 2

        local mouseX, mouseY = love.mouse.getPosition()
        local isHovered = mouseX > x and mouseX < x + cardWidth and mouseY > y and mouseY < y + cardHeight
        if isHovered then
            love.graphics.setColor(0.8, 0.8, 0.8)
        else
            love.graphics.setColor(1, 1, 1)
        end

        if card.color then
            love.graphics.setColor(card.color)
            love.graphics.rectangle("fill", x, y, cardWidth, cardHeight)
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(card, x, y, 0, cardWidth / card:getWidth(), cardHeight / card:getHeight())
        end
    end
end

function M.handleMouseClick()
    local mouseX, mouseY = love.mouse.getPosition()
    local cardWidth, cardHeight = M.cardWidth, M.cardHeight
    local width = love.graphics.getWidth()

    for i, card in ipairs(M.cards) do
        local x = (i - 1) * (cardWidth + 10) + (width - 3 * cardWidth - 20) / 2
        local y = (love.graphics.getHeight() - cardHeight) / 2

        if mouseX > x and mouseX < x + cardWidth and mouseY > y and mouseY < y + cardHeight then
            M.selectedCard = i
            game_state.resumeGame()
            break
        end
    end
end

return M
