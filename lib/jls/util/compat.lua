local compat = {}

-- /!\ Work in progress, do not use

-- This compatibility module provides the latest Lua features to a previous Lua version >= 5.1

local major, minor = string.match(_VERSION, '^%a+ (%d+)%.(%d+)')
local version = tonumber(major) * 10 + tonumber(minor)

function compat.notAvailable()
  error('No compatibility available')
end

function compat.ignored()
end

local function len(v)
  return #v
end

compat.rawlen = _G.rawlen or len

-- Prior Lua 5.2, the length operator does not use the __len metamethod
function compat.len(v)
  if type(v) == 'string' then
    return string.len(v)
  elseif type(v) == 'table' then
    local mt = getmetatable(v)
    if type(mt) == 'table' then
      local fn = mt.__len
      if type(fn) == 'function' then
        return fn(v)
      end
    end
    return compat.rawlen(v)
  else
    error('invalid argument type')
  end
end

local floor = math.floor

function compat.fdiv(a, b)
  return floor(a / b)
end

-- Standard Lua uses 64-bit integers and double-precision (64-bit) floats since 5.3
-- (in Lua 5.2 all numbers were float, double-precision floating-point)
-- 64-bit floats have 52-bits precision

local MAXINT = floor(2 ^ 52)

local function bitoper(oper, a, b)
  -- oper: OR, XOR, AND = 1, 3, 4
  local r, m = 0, 2 ^ 31
  repeat
    local s = a + b + m
    a, b = a % m, b % m
    r, m = r + m * oper % (s - a - b), m / 2
  until m < 1
  return floor(r)
end

local function bitopers(oper, ...)
  local l = select('#', ...)
  if l == 2 then
    return bitoper(oper, ...)
  elseif l < 2 then
    return (select(2, ...))
  end
  local values = {...}
  local r = values[1]
  for i = 2, l do
    r = bitoper(r, values[i], oper)
  end
  return r
end

function compat.bnot(v)
  if v >= 0 then
    return -((v + 1) % MAXINT)
  end
  return (-1 - v) % MAXINT
end

function compat.band(...)
  return bitopers(4, ...)
end

function compat.bor(...)
  return bitopers(1, ...)
end

function compat.bxor(...)
  return bitopers(3, ...)
end

function compat.lshift(v, n)
  if n < 0 then
    return compat.rshift(v, -n)
  end
  return floor((v * (2 ^ n)) % MAXINT)
end

function compat.rshift(v, n)
  if n < 0 then
    return compat.lshift(v, -n)
  end
  return floor(v % MAXINT / (2 ^ n))
end

function compat.pack(...)
  return {n = select('#', ...), ...}
end

---@diagnostic disable-next-line: deprecated
compat.unpack = table.unpack or _G.unpack

function compat.tmove(a1, f, e, t, a2)
  if a2 == nil then
    a2 = a1
  end
  local j = t
  for i = f, e do
    a2[j] = a1[i]
    j = j + 1
  end
end

function compat.itos(v, n, be)
  local chars = {}
  local r = v
  for _ = 1, n do
    local b = r % 256
    r = floor(r / 256)
    table.insert(chars, string.char(b))
  end
  local s = table.concat(chars)
  if be then
    return string.reverse(s)
  end
  return s
end

function compat.stoi(v, n, be, init)
  init = init or 1
  local f, t, s
  if be then
    f, t, s = init, n + init - 1, 1
  else
    f, t, s = n + init - 1, init, -1
  end
  local r = 0
  for i = f, t, s do
    local b = string.byte(v, i)
    r = r * 256 + b
  end
  return r
end

local maxinteger = 1
while maxinteger + 1 > maxinteger and 2 * maxinteger > maxinteger do
  maxinteger = maxinteger * 2
end
local mininteger
if 2 * maxinteger > maxinteger then
  mininteger = -maxinteger
else
  maxinteger = 2 * maxinteger - 1
  mininteger = -maxinteger - 1
end


compat.maxinteger = maxinteger
compat.mininteger = mininteger

function compat.mathtype(v)
  if type(v) == 'number' then
    if v % 1 == 0 and v >= mininteger and v <= maxinteger then
      return 'integer'
    end
    return 'float'
  end
  return nil
end

function compat.ult(m, n)
  return floor(m) < floor(n)
end

function compat.tointeger(n)
  local i = floor(n)
  if i ~= n or n < mininteger or n > maxinteger then
    return nil
  end
  return i
end

-- Two's complement signed integer
function compat.sign(v, n)
  local e = 8 * n
  local sign = floor((v / (2 ^ (e - 1))) % 2)
  if sign == 1 then
    local c = floor(2 ^ e)
    return v - c
  end
  return v
end

function compat.unsign(v, n)
  local c = floor((2 ^ (8  * n)) - 1)
  if v < 0 then
    return v % c + 1
  end
  return v % c
end

function compat.rtos(v, ew, sp)
  local sign = 0
  if v < 0 then
    sign = 1
    v = -v
  end
  local e = floor(math.log(v, 10))
  local sm = 2 ^ sp
  local se = floor(math.log(sm, 10))
  if e > se then
    v = v / (10 ^ e - se)
  elseif e < se then
    v = v * (10 ^ se - e)
  end
  v = floor(v % sm)
  -- TODO Fix
  return string.char((sign * 128) + floor(e % 128))..compat.itos(v, floor(sp / 8) + 1, false)
end

function compat.stor(v, ew, sp)
  return 0 -- TODO
end

local option_aliases = {
  b = {o = 'i', n = 1},
  h = {o = 'i', n = 2},
  i = {o = 'i', n = 4},
  l = {o = 'i', n = 8},
  B = {o = 'I', n = 1},
  H = {o = 'I', n = 2}, -- unsigned short (native size)
  I = {o = 'I', n = 4},
  L = {o = 'I', n = 8}, -- unsigned long (native size)
  j = {o = 'i', n = 8}, -- lua_Integer
  J = {o = 'I', n = 8}, -- lua_Unsigned
  T = {o = 'I', n = 8}, -- unsigned size_t
  n = {o = 'd', n = 8}, -- lua_Number
}

local function mapPack(fmt, fn)
  local be
  local mal = 1
  local i = 1
  local t = {}
  for o, ns in string.gmatch(fmt, "([^0-9])([0-9]*)") do
    local a = option_aliases[o]
    local n = 1
    if a then
      o, n = a.o, a.n
    end
    if #ns > 0 then
      n = tonumber(ns)
    end
    if o == '<' then
      be = false
    elseif o == '>' then
      be = true
    elseif o == '=' then
      be = true
    elseif o == '!' then
      mal = n
    elseif o == ' ' then
      -- ignored
    else
      local v = fn(i, o, n, be, mal)
      if v ~= nil then
        table.insert(t, v)
      end
      i = i + 1
    end
  end
  return t
end

function compat.spack(fmt, ...)
  local s = select('#', ...)
  local args = {...}
  return table.concat(mapPack(fmt, function(i, o, n, be, mal)
    if i > s then
      error('missing argument #'..tostring(i))
    end
    local v = args[i]
    if o == 'I' then
      return compat.itos(v, n, be)
    elseif o == 'i' then
      if v < 0 then
        return compat.itos(compat.unsign(v, n), n, be)
      end
      return compat.itos(v, n, be)
    elseif o == 'f' then
      -- Single-precision floating-point
      return compat.rtos(v, 8, 23)
    elseif o == 'd' then
      -- Double-precision floating-point
      return compat.rtos(v, 11, 52)
    elseif o == 'c' then
      if n > #v then
        return v..string.rep('\0', n - #v)
      end
      return string.sub(v, 1, n)
    elseif o == 'x' then
      return '\0'
    elseif o == 's' then
      local l = compat.itos(#v, n, be)
      return l..v
    elseif o == 'z' then
      if string.find(v, '\0', 1, true) then
        error('string argument contain zero character')
      end
      return v..'\0'
    else
      error('unknown pack option "'..tostring(o)..'"')
    end
  end))
end

function compat.sunpack(fmt, s, pos)
  local k = pos or 1
  local t = mapPack(fmt, function(i, o, n, be, mal)
    local j = k
    if o == 's' then
      local l = compat.stoi(s, n, be, j)
      j = j + n
      k = j + l
      return string.sub(s, j, k - 1)
    elseif o == 'z' then
      local z = string.find(s, '\0', k, true)
      k = z + 1
      return string.sub(s, j, z - 1)
    else
      k = j + n
      if o == 'c' then
        return string.sub(s, j, k - 1)
      elseif o == 'I' then
        return compat.stoi(s, n, be, j)
      elseif o == 'i' then
        return compat.sign(compat.stoi(s, n, be, j), n)
      elseif o == 'f' then
        return 0.0 -- TODO Fix
      elseif o == 'd' then
        return 0.0 -- TODO Fix
      elseif o == 'x' then
        return nil
      else
        error('unknown unpack option "'..tostring(o)..'"')
      end
    end
  end)
  table.insert(t, k)
  return compat.unpack(t)
end

function compat.spacksize(fmt)
  local s = 0
  mapPack(fmt, function(i, o, n, be, mal)
    if o == 'i' or o == 'I' or o == 'f' or o == 'd' or o == 'c' then
      s = s + n
    elseif o == 'z' or o == 's' then
      error('bad packsize option "'..tostring(o)..'"')
    else
      error('unknown packsize option "'..tostring(o)..'"')
    end
  end)
  return s
end

-- Since Lua 5.2, string format converts using tostring
function compat.format(fmt, ...)
  local l = select('#', ...)
  local values = {...}
  -- Each conversion specification is introduced by the character %, and ends with a conversion specifier.
  -- In between there may be (in this order) zero or more flags, an optional minimum field width, an optional precision and an optional length modifier.
  local i = 1
  for c in string.gmatch(fmt, '%%[#0%-%+ ]*[0-9]*%.?[0-9]*[hlLqjzt]*([diouxXeEfFgGaAcspn])') do
    local value = values[i]
    if c == 's' and type(value) ~= 'string' then
      values[i] = tostring(value)
    elseif c == 's' and type(value) ~= 'table' and type(value) ~= 'thread' and type(value) ~= 'userdata' and type(value) ~= 'string' and type(value) ~= 'function' then
      values[i] = '(null)'
    end
    i = i + 1
  end
  return string.format(fmt, compat.unpack(values, 1, l))
end

-- Prior Lua 5.2, xpcall does not take arguments
function compat.xpcall(f, msgh, ...)
  local args = compat.pack(...)
  return xpcall(function()
    return f(compat.unpack(args, 1, args.n))
  end, msgh)
end

local function exists(path)
  local f, err = io.open(path)
  if f then
    io.close(f)
    return true
  end
  return false, err
end

function compat.searchpath(name, path, sep, rep)
  local sp = sep and ('%'..sep) or '%.'
  local rp = rep or string.sub(package.config, 1, 1)
  for tp in string.gmatch(path, "([^;]+)") do
    local p = string.gsub(string.gsub(tp, '%?', name), sp, rp)
    if exists(p) then
      return p
    end
  end
  return nil, 'Not found'
end

local function encodeUTF8(i)
  if i < 0 then
    error('bad argument (value out of range)')
  end
  if i < 0x80 then
    return string.char(i)
  end
  local z = 0x80 + i % 64
  if i < 0x800 then
    return string.char(0xc0 + floor(i / 64) % 32, z)
  end
  local y = 0x80 + floor(i / 64) % 64
  if i < 0x10000 then
    return string.char(0xe0 + floor(i / 0x1000) % 16, y, z)
  end
  local x = 0x80 + floor(i / 0x1000) % 64
  if i < 0x200000 then
    return string.char(0xf0 + floor(i / 0x40000) % 8, x, y, z)
  end
  error('bad argument (value out of range)')
end

local function decodeUTF8(s, offset)
  offset = offset or 1
  local b = string.byte(s, offset)
  if not b then
    return nil, nil
  end
  if b < 128 then
    return b, offset + 1
  end
  if b == 0xff or floor(b / 64) == 2 then
    error('invalid UTF-8 code')
  end
  local i, l
  if b < 224 then
    l = 2
    i = b % 32
  elseif b < 240 then
    l = 3
    i = b % 16
  elseif b < 247 then
    l = 4
    i = b % 8
  end
  for j = 1, l - 1 do
    b = string.byte(s, offset + j)
    if b then
      i = i * 64 + b % 64
    else
      return nil, nil
    end
  end
  return i, offset + l
end

compat.encodeUTF8 = encodeUTF8
compat.decodeUTF8 = decodeUTF8

function compat.uchar(...)
  local count = select('#', ...)
  local values = {...}
  for i = 1, count do
    values[i] = encodeUTF8(values[i])
  end
  return table.concat(values)
end

function compat.ucodepoint(s, i, j, lax)
  i = i or 1
  j = j or i
  if i == j then
    return (decodeUTF8(s, i))
  end
  local t = {}
  local cp
  while i <= j do
    cp, i = decodeUTF8(s, i)
    if cp then
      table.insert(t, cp)
    else
      break
    end
  end
  return compat.unpack(t)
end

function compat.ulen(s, i, j, lax)
  i = i or 1
  j = j or #s
  local n = 0
  while i <= j do
    local cp, ii = decodeUTF8(s, i)
    if cp then
      n = n + 1
      i = ii
    else
      return nil, i
    end
  end
  return n
end

function compat.uoffset(s, n, i)
  i = i or 1
  -- TODO support negative n value
  local nn = 0
  while true do
    local cp, ii = decodeUTF8(s, i)
    if cp then
      nn = nn + 1
      if n == nn then
        return i
      end
      i = ii
    else
      return nil
    end
  end
end

local function nextcode(s, i)
  local cp, ni = decodeUTF8(s, i)
  return ni, cp
end

function compat.ucodes(s, lax)
  return nextcode, s, 1
end

function compat.traceback(...)
  local count = select('#', ...)
  if count >= 3 then
    local thread = select(1, ...)
    local message = select(2, ...) or ''
    local level = select(3, ...) or 1
    if type(message) ~= 'string' then
      return message
    end
    return debug.traceback(thread, message, level)
  end
  local message = select(1, ...) or ''
  local level = select(2, ...) or 1
  if type(message) ~= 'string' then
    return message
  end
  return debug.traceback(message, level)
end

function compat.load(chunk, chunkname, mode, env)
  -- TODO support mode and env
  if type(chunk) == 'string' then
    local code = chunk
    chunk = function()
      local c = code
      code = nil
      return c
    end
  end
  return load(chunk, chunkname)
end

-- random is not initialized
local t = os.time()
math.randomseed(floor(t / 10))
for i = 0, t % 10 do
  math.random()
end

function compat.random(...)
  local count = select('#', ...)
  if count == 0 then
    return math.random()
  end
  local m, n = ...
  if count == 1 then
    n = m
    m = 1
  end
  if n < 0x0fffffff then
    return math.random(m, n)
  end
  local r = math.random()
  return floor((r * ((n - m) + 1)) + m)
end

function compat.execute(...)
  local status = os.execute(...)
  local count = select('#', ...)
  if count == 0 then
    return status ~= 0
  end
  return status == 0, 'exit', status
end

-- file read does not support 'a' but '*a' but 5.4 remains compatible ignoring '*'

local status, m
---- see https://github.com/AlberTajuelo/bitop-lua
--status, m = pcall(require, 'bitop.funcs')
--if status then
--  m = m.bit32
--  compat.bnot = m.bnot
--  compat.band = m.band
--  compat.bor = m.bor
--  compat.bxor = m.bxor
--  compat.lshift = m.lshift
--  compat.rshift = m.rshift
--end
-- see http://www.inf.puc-rio.br/~roberto/struct/
--status, m = pcall(require, 'struct')
--if status then
--  local function unpack(fmt, s, pos)
--    local t = compat.pack(m.unpack(fmt, s, pos))
--    for i, v in ipairs(t) do
--      if type(v) =='number' and v % 1 == 0 then
--        t[i] = floor(v)
--      end
--    end
--    return compat.unpack(t)
--  end
--  compat.spack = m.pack
--  compat.sunpack = unpack
--  compat.spacksize = m.size
--end
-- see https://github.com/lunarmodules/lua-compat-5.3

return compat
