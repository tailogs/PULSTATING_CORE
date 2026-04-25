function love.load()
    spider = {
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2,
        size = 20,
        num_legs = 8,
        leg_length = 40,
        leg_segments = 3,
        speed = 100,
        angle_offset = math.pi / 8,
        walk_cycle = 0,
        leg_angles = {},
        direction_x = 1,
        direction_y = 1
    }
    
    for i = 1, spider.num_legs do
        spider.leg_angles[i] = (i - 1) * (math.pi / 4) + spider.angle_offset
    end
end

function love.update(dt)
    spider.walk_cycle = spider.walk_cycle + dt * 3
    if spider.walk_cycle > 1 then
        spider.walk_cycle = 0
    end
    
    for i = 1, spider.num_legs do
        local angleOffset = (i % 2 == 0) and math.sin(spider.walk_cycle * math.pi) or -math.sin(spider.walk_cycle * math.pi)
        spider.leg_angles[i] = (i - 1) * (math.pi / 4) + spider.angle_offset + angleOffset * 0.2
    end

    spider.x = spider.x + spider.direction_x * spider.speed * dt
    spider.y = spider.y + spider.direction_y * spider.speed * dt

    if spider.x < spider.size then
        spider.x = spider.size
        spider.direction_x = -spider.direction_x
    elseif spider.x > love.graphics.getWidth() - spider.size then
        spider.x = love.graphics.getWidth() - spider.size
        spider.direction_x = -spider.direction_x
    end
    
    if spider.y < spider.size then
        spider.y = spider.size
        spider.direction_y = -spider.direction_y
    elseif spider.y > love.graphics.getHeight() - spider.size then
        spider.y = love.graphics.getHeight() - spider.size
        spider.direction_y = -spider.direction_y
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.8, 0.8, 0.8)

    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", spider.x, spider.y, spider.size)

    love.graphics.setColor(0, 0, 0)
    for i = 1, spider.num_legs do
        local angle = spider.leg_angles[i]
        local x1 = spider.x + math.cos(angle) * spider.size
        local y1 = spider.y + math.sin(angle) * spider.size
        local x2 = x1 + math.cos(angle) * spider.leg_length
        local y2 = y1 + math.sin(angle) * spider.leg_length

        love.graphics.line(x1, y1, x2, y2)
    end
end
