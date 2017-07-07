--[[ Precise Shadowcasting ]]--

setmetatable(_G, { __newindex = function (k, v) error('global ' .. v, 2) end })
local ROT=require 'src.rot'
setmetatable(_G, nil)

function calbak(x, y, val)
    map[x..','..y]=val
end

function lightCalbak(fov, x, y)
    local key=x..','..y
    if map[key] then
        return map[key]==0
    end
    return false
end

function computeCalbak(x, y, r, v)
    local key  =x..','..y
    if not map[key] then return end
    field[key]=1
    seen[key]=1
end

function placePlayer()
    local key =nil
    local char='#'
    local rng=ROT.RNG.Twister:new()
    rng:randomseed()
    while true do
        key=rng:random(1,f:getWidth())..','..rng:random(1,f:getHeight())
        if map[key]==0 then
            pos = key:split(',')
            player.x, player.y=tonumber(pos[1]), tonumber(pos[2])
            f:write('@', player.x, player.y)
            break
        end
    end
end

function love.load()
    f  = require 'src.rot.ttyDisplay' (80, 24)
    map={}
    field={}
    seen={}
    seenColor={r=100, g=100, b=100, a=255}
    fieldColor={r=225, g=225, b=225, a=255}
    fieldbg={r=50, g=50, b=50, a=255}
    update=false
    player={x=1, y=1}
    doTheThing()
end

function doTheThing()
    uni=ROT.Map.Uniform:new(f:getWidth(), f:getHeight())
    uni:create(calbak)
    fov=ROT.FOV.Precise:new(lightCalbak)--, {topology=4})
    placePlayer()
    fov:compute(player.x, player.y, 10, computeCalbak)
end

function love.update()
    if update then
        update=false
        seen={}
        doTheThing()
    end
    f:clear()
    for x=1,f:getWidth() do
        for y=1,f:getHeight() do
            local key=x..','..y
            if seen[key] then
                char=key==player.x..','..player.y and '@' or map[key]==0 and '.' or map[key]==1 and '#'
                f:write(char, x, y, field[key] and fieldColor or seenColor, field[key] and fieldbg or nil)
            end
        end
    end
    local s='Use WASD to move!'
    f:write(s, f:getWidth()-#s, f:getHeight())
end
function love.keypressed(key)
    local newPos={0,0}
    if     key=='s' then newPos={ 0, 1}
    elseif key=='a' then newPos={-1, 0}
    elseif key=='d' then newPos={ 1, 0}
    elseif key=='w' then newPos={ 0,-1}
    else
        update=true
    end
    if newPos~={0,0} then
        local newx = player.x+newPos[1]
        local newy = player.y+newPos[2]
        if map[newx..','..newy]==0 then
            field={}
            player.x=newx
            player.y=newy
            fov:compute(player.x, player.y, 10, computeCalbak)
        end
    end

end
function love.draw() f:draw() end

function love.run ()
    os.execute('stty -echo cbreak; tput civis')
    io.stdout:write('\27[2J')
    love.load()
    repeat
        love.update()
        love.draw()
        love.keypressed(io.stdin:read(1))
        love.event.pump()
    until love.event.poll()() == 'quit'
    os.execute('stty echo -cbreak; tput cnorm')
end


