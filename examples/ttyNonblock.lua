--[[ Precise Shadowcasting ]]--
local ROT=require 'src.rot'

local rng=ROT.RNG
rng:randomseed(os.time())
    
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

local function getTerminalSize()
    return tonumber(io.popen('tput cols'):read()),
        tonumber(io.popen('tput lines'):read())
end

function love.load()
    f  = require 'src.rot.ttyDisplay' (getTerminalSize())
    map={}
    field={}
    seen={}
    seenColor={ 100, 100, 100 }
    fieldColor={ 225, 225, 125 }
    fieldbg={ 50, 50, 50 }
    update=false
    player={x=1, y=1}
    doTheThing()
end

function doTheThing()
    uni=ROT.Map.EllerMaze:new(128, 128, {}, rng)
    uni:create(calbak)
    fov=ROT.FOV.Precise:new(lightCalbak)--, {topology=4})
    placePlayer()
    fov:compute(player.x, player.y, 8, computeCalbak)
end

local message

function love.update()
    if update then
        update=false
        seen={}
        doTheThing()
    end
    f:clear()
    local radX = 16
    local radY = 8
    for x= player.x - radX, player.x + radX do
        for y= player.y - radY, player.y + radY do
            local key=x..','..y
            if seen[key] then
                char=key==player.x..','..player.y and '@'
                    or map[key]==0 and '.'
                    or map[key]==1 and '#'
                    or '?'
                f:write(char,
                    x - player.x + radX + 1,
                    y - player.y + radY + 2,
                    field[key] and fieldColor or seenColor,
                    field[key] and fieldbg or nil)
            end
        end
    end
    local s= message or 'Use numpad/arrows to move, Ctrl-C to quit.'
    f:write(s, f:getWidth()-#s, f:getHeight())
end
            
function love.keypressed(key)
    local newPos
    
    if     key=='\27[A' then newPos={ 0,-1}
    elseif key=='\27[B' then newPos={ 0, 1}
    elseif key=='\27[C' then newPos={ 1, 0}
    elseif key=='\27[D' then newPos={-1, 0}
    
    elseif key=='\27[5~' then newPos={ 1,-1}
    elseif key=='\27[6~' then newPos={ 1, 1}
    elseif key=='\27[F' then newPos={-1, 1}
    elseif key=='\27[H' then newPos={-1,-1}
    
    elseif key=='r' then update = true
    else
        message = ('key = %q'):format(key):gsub('\\\n', '\\n')
    end
    if newPos then
        local newx = player.x+newPos[1]
        local newy = player.y+newPos[2]
        if map[newx..','..newy]~=1 then
            field={}
            player.x=newx
            player.y=newy
            fov:compute(player.x, player.y, 9, computeCalbak)
        end
    end

end

function love.draw() f:draw() end

local buf

local function checkInput ()
    local char = buf or io.read(1)
    buf = nil
    if char ~= '\27' then return char end
    local chars = { char }
    repeat
        char = io.read(1)
        if char == '\27' then
            buf = char
            return table.concat(chars)
        end
        chars[#chars + 1] = char
    until not char
    return table.concat(chars)
end

function love.run ()

    local sleepTime = 1/32
    
    -- set stdin to non-blocking
    local ffi, F_SETFL, O_NONBLOCK = require 'ffi', 4, 2048
    ffi.cdef 'int fcntl(int fd, int cmd, long arg);'
    ffi.C.fcntl(0, F_SETFL, O_NONBLOCK)
    
    os.execute('stty -echo cbreak; tput civis')
    io.stdout:write('\27[2J')
    love.load()
    love.update()
    love.draw()
    repeat
        local key = checkInput()
        if key then
            repeat
                love.keypressed(key)
                key = checkInput()
            until not key
            love.update()
            love.draw()
        else
            love.timer.sleep(sleepTime)
        end
        love.event.pump()
    until love.event.poll()() == 'quit'
    io.stdout:write('\n')
    os.execute('stty echo -cbreak; tput cnorm')
end


