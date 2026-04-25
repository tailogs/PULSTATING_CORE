local M = {}

local HEX_SIZE = 40
local HEX_ALPHA = 0.2
local HEX_COLOR = {0.1, 0.1, 0.1}
local HEX_FADE_SPEED = 2
local HEX_MIN_DISTANCE = 150
local hex_grid = {}
local last_mouse_x, last_mouse_y = 0, 0
local mouse_moved = false
local idle_timer = 0
local explosion_timer = 0

local start_timer = 0
local delay_timer = 0
local START_ANIMATION_DELAY = 2
local START_ANIMATION_DURATION = 2

local Y_SHIFT = 20

local function get_hex_center(col, row)
    local x = col * HEX_SIZE * 1.5
    local y = row * HEX_SIZE * math.sqrt(3) - Y_SHIFT

    if col % 2 == 1 then
        y = y + (HEX_SIZE * math.sqrt(3) / 2)
    end
    return x, y
end

local function create_hexagons(w, h)
    local cols = math.ceil(w / (HEX_SIZE * 1.5)) + 2
    local rows = math.ceil(h / (HEX_SIZE * math.sqrt(3))) + 2

    for col = -1, cols do
        for row = -1, rows do
            local x, y = get_hex_center(col, row)

            if math.abs(x) < w + HEX_SIZE and math.abs(y) < h + HEX_SIZE then
                hex_grid[col .. "_" .. row] = {
                    x = x,
                    y = y,
                    alpha = 0,
                    size = 0,
                    timer = 0,
                    active = false,
                    angle = 0,
                    angle_speed = 0,
                    rise_speed = math.random() * 2 - 1,
                    color = {math.random(), math.random(), math.random()},
                    dist = 0
                }
            end
        end
    end
end

local function draw_hex(x, y, size, alpha, color, angle)
    local points = {}
    for i = 0, 5 do
        local angle_i = angle + 2 * math.pi * i / 6
        table.insert(points, x + size * math.cos(angle_i))
        table.insert(points, y + size * math.sin(angle_i))
    end
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.setLineWidth(1)
    love.graphics.polygon("line", points)
end

function M.update(dt)
    local x, y = love.mouse.getPosition()
    local dx, dy = x - last_mouse_x, y - last_mouse_y

    if dx ~= 0 or dy ~= 0 then
        mouse_moved = true
        idle_timer = 0
    else
        mouse_moved = false
        idle_timer = idle_timer + dt
    end

    if delay_timer < START_ANIMATION_DELAY then
        delay_timer = delay_timer + dt
    else
        if start_timer < START_ANIMATION_DURATION then
            start_timer = start_timer + dt
            local progress = start_timer / START_ANIMATION_DURATION
            for _, v in pairs(hex_grid) do
                v.size = HEX_SIZE * progress
            end
        end
    end

    explosion_timer = explosion_timer + dt * 2
    for k, v in pairs(hex_grid) do
        local col, row = k:match("(-?%d+)_(-?%d+)") 
        col = tonumber(col)
        row = tonumber(row)

        v.dist = v.dist + dt * 200
        local target_x, target_y = get_hex_center(col, row)
        v.x = target_x + (v.x - target_x) * (1 - math.exp(-v.dist / 200))
        v.y = target_y + (v.y - target_y) * (1 - math.exp(-v.dist / 200))

        local distance = math.sqrt((x - v.x) ^ 2 + (y - v.y) ^ 2)
        if distance < HEX_MIN_DISTANCE then
            v.active = true
            v.alpha = math.min(v.alpha + dt * HEX_FADE_SPEED, 1)
        else
            if v.active then
                v.alpha = math.max(v.alpha - dt * HEX_FADE_SPEED, HEX_ALPHA)
            end
        end

        if v.active then
            if v.angle_speed ~= 0 then
                v.angle = v.angle + v.angle_speed
            end
        end
    end

    if not mouse_moved then
        for k, v in pairs(hex_grid) do
            v.alpha = math.max(v.alpha - dt * idle_timer * 0.2, HEX_ALPHA)
            if v.alpha == HEX_ALPHA then
                v.active = false
            end
        end
    end

    last_mouse_x, last_mouse_y = x, y
end

function M.draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.05)
    love.graphics.clear()

    for k, v in pairs(hex_grid) do
        draw_hex(v.x, v.y, v.size, v.alpha, v.color, v.angle)
    end
end

function M.load()
    local w, h = love.graphics.getDimensions()
    create_hexagons(w, h)
end

return M
