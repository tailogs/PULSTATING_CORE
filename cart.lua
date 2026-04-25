local cardWidth = 100
local cardHeight = 150
local cardSpacing = 20
local centerX = love.graphics.getWidth() / 2
local centerY = love.graphics.getHeight() / 2
local numCards = 3
local animationSpeed = 2
local cardPositions = {}
local cardTexts = {"Ace of Spades", "King of Hearts", "Queen of Diamonds"}

local mouseX, mouseY = 0, 0
local animationStarted = false

function love.load()
    for i = 1, numCards do
        table.insert(cardPositions, {
            x = centerX - (cardWidth / 2), 
            y = centerY - 200,
            show = false, 
            scale = 0,
            alpha = 0,
            targetY = centerY - cardHeight / 2,
            raisedY = -10
        })
    end
end

function love.update(dt)
    mouseX, mouseY = love.mouse.getPosition()
    
    if not animationStarted then
        local allCardsShown = true
        for i = 1, numCards do
            cardPositions[i].scale = cardPositions[i].scale + 0.03
            cardPositions[i].alpha = cardPositions[i].alpha + 0.05
            cardPositions[i].y = cardPositions[i].y + animationSpeed
            
            if cardPositions[i].y >= cardPositions[i].targetY then
                cardPositions[i].y = cardPositions[i].targetY
                cardPositions[i].scale = 1
                cardPositions[i].alpha = 1
                cardPositions[i].show = true
            else
                allCardsShown = false
            end
        end
        
        if allCardsShown then
            animationStarted = true
        end
    end

    for i = 1, numCards do
        local cardX = cardPositions[i].x + (i - 2) * (cardWidth + cardSpacing)
        local cardY = cardPositions[i].y
        if mouseX >= cardX and mouseX <= cardX + cardWidth and mouseY >= cardY and mouseY <= cardY + cardHeight then
            cardPositions[i].raised = true
        else
            cardPositions[i].raised = false
        end
    end
end

function love.draw()
    for i = 1, numCards do
        if cardPositions[i].show then
            local cardX = cardPositions[i].x + (i - 2) * (cardWidth + cardSpacing)
            
            if cardPositions[i].raised then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.setColor(0.9, 0.7, 0.5, cardPositions[i].alpha)
                love.graphics.rectangle("fill", cardX, cardPositions[i].y + cardPositions[i].raisedY, cardWidth, cardHeight)
            else
                love.graphics.setColor(0.8, 0.6, 0.4, cardPositions[i].alpha)
                love.graphics.rectangle("fill", cardX, cardPositions[i].y, cardWidth, cardHeight)
            end
            
            love.graphics.setColor(0, 0, 0, cardPositions[i].alpha)
            love.graphics.setFont(love.graphics.newFont(12))
            love.graphics.printf(cardTexts[i], cardX, cardPositions[i].y + cardHeight / 2 - 10 + (cardPositions[i].raised and cardPositions[i].raisedY or 0), cardWidth, "center")
        end
    end
end
