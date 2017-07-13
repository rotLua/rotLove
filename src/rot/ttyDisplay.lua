local ROT = require((...):gsub(('.[^./\\]*'):rep(1) .. '$', ''))
local TTYDisplay = ROT.Class:extend("TTYDisplay")

function TTYDisplay:init(width, height)
    self.width, self.height = width, height
    self:clear()
end

function TTYDisplay:getWidth()
    return self.width
end

function TTYDisplay:getHeight()
    return self.height
end

function TTYDisplay:draw()
    io.stdout:write('\27[0;0H')
    for y = 1, self.height do
        for x = 1, self.width do
            io.stdout:write(self.lines[y][x] or ' ')
        end
        if y < self.height then io.stdout:write('\n') end
    end
end

function TTYDisplay:clear()
    self.lines = {}
    for y = 1, self.height do
        self.lines[y] = {}
    end
end

function TTYDisplay:write(text, x, y, fg, bg)
    self.lines[y] = self.lines[y] or {}
    self.lines[y][x] =
        (fg and ('\27[38;2;%i;%i;%im'):format(fg.r, fg.g, fg.b) or '') .. 
        (bg and ('\27[48;2;%i;%i;%im'):format(bg.r, bg.g, bg.b) or '')
    for i = 1, #text do
        self.lines[y][x] = (self.lines[y][x] or '') .. text:sub(i, i)
        x = x + 1
    end
    x = x - 1
    self.lines[y][x] = self.lines[y][x] .. ((bg or fg) and '\27[0m' or '')
end

return TTYDisplay

