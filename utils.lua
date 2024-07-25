do
	--Same as ipairs but in reverse
	reverse_ipairs = function(t)
		local i = #t + 1

		return function ()
			i = i - 1

			if i == 0 then
				return
			end

			return i, t[i]
		end
	end

	table.read_only = function(t) --Creates a read-only table
		local proxy = {}
		local mt = {
			__index = t,
			__newindex = function(t, k, v)
				error("Attempted to write a read-only table... bozo", 2)
			end
		}
		setmetatable(proxy, mt)
		return proxy
	end

	table.find_key_of = function(tbl, val) --Locates the key of a given value
		for key, value in pairs(tbl) do
			if value == val then
				return key
			end
		end
		return false
	end
	--Returns a table filled with a given value
	table.fill = function(start, length, mixed)
		mixed = mixed or 0
		local tmp_tbl = {}

		if start == 1 then
			for i = 1, length do
				tmp_tbl[#tmp_tbl + 1] = mixed
			end
			return tmp_tbl
		elseif start ~= 1 and start ~= nil and length ~= nil then
			for i = start, (length + start) do
				tmp_tbl[i] = mixed
			end
			return tmp_tbl
		end
	end
	--Reverses a table with numerical indexes
	table.reverse = function(tab)
		local length = #tab
		for i = 1, bit.rshift(length, 1) do --LuaJIT doesn't support Lua 5.3+ bitwise operators yet :/
			tab[i], tab[length - i + 1] = tab[length - i + 1], tab[i]
		end
		return tab
	end
	--Self explanitory
	math.round = function(n, precision)
		precision = precision or 1

		return math.floor((n + precision / 2) / precision) * precision
	end
	--Merges 2 tables into each other
	table.merge = function(...)
		assert(select("#", ...) > 1, "There should be at least two tables to merge")
		local tables_to_merge = { ... }

    	local result = tables_to_merge[1]

    	for i = 2, #tables_to_merge do
        	local from = tables_to_merge[i]
        	for key, value in pairs(from) do
            	if type(key) == "number" then
                	table.insert(result, value)
            	elseif type(key) == "string" then
                	if type(value) == "table" then
                    	result[key] = result[key] or {}
                    	result[key] = table.merge(result[key], value)
                	else
                    	result[key] = value
                	end
            	end
        	end
    	end

    	return result
	end
	--Performs a deep cloning of a table (i.e., also cloning the tables in the table)
	table.deep_clone = function(tbl)
		if type(tbl) == "userdata" then
			return tbl
		end

		local res = {}

		setmetatable(res, getmetatable(tbl))

		for key, value in pairs(tbl) do
			if type(value) == "table" then
				res[key] = table.deep_clone(value)
			else
				res[key] = value
			end
		end

		return res
	end
	--Emulates the "sprintf" function found in other languages.
	_G.sprintf = function(format, ...)
		local args = {...}
		local index = 1
		local formatted = format:gsub('%%(.)', function(type)
			local arg = args[index]
			index = index + 1
			if type == 'd' then
				return string.format('%d', arg)
			elseif type == 'f' then
				return string.format('%' .. format:match('%%(%d+)%.%d+f'), arg)
			elseif type == 's' then
				local width = tonumber(format:match('%%(%d+)s')) or #arg
				local alignment = format:match('%%(%W)') or ''
				if alignment == '#' then
					return string.format('%s%s', ('#'):rep(width - #arg), arg)
				else
					return string.format('%' .. alignment .. width .. 's', arg)
				end
			end
		end)
		return formatted
	end

	_G.preg_split = function(pattern, subject, limit, flags)
		limit = limit or 0
		flags = flags or ''

		local ret = {}
		local index = 0
		local noEmpty = false
		local delim = false
		local offset = false

		local OPTS = {
			PREG_SPLIT_NO_EMPTY = 1,
			PREG_SPLIT_DELIM_CAPTURE = 2,
			PREG_SPLIT_OFFSET_CAPTURE = 4
		}

		local function _filter(str, strindex)
			if noEmpty and #str == 0 then return end
			if offset then str = {str, strindex} end
			table.insert(ret, str)
		end

		-- Special case for empty regexp
		local regexpBody = pattern:match('^/(.*)/%w*$')
		if not regexpBody then
			for i = 1, #subject do
				_filter(subject:sub(i, i), i)
			end
			return ret
		end

		local regexpFlags = pattern:match('^/.*/(%w*)$')
		pattern = pattern:gsub('^/(.*)/%w*$', '%1')
		if not pattern:find('g', 1, true) then
			pattern = pattern .. 'g'
		end
		--NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE NIGHTMARE
		pattern = pattern:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0')

		noEmpty = bit.band(flags, OPTS.PREG_SPLIT_NO_EMPTY) ~= 0
		delim = bit.band(flags, OPTS.PREG_SPLIT_DELIM_CAPTURE) ~= 0
		offset = bit.band(flags, OPTS.PREG_SPLIT_OFFSET_CAPTURE) ~= 0

		local function exec_pattern()
			local result = {subject:match(pattern, index + 1)}
			if not result[1] then return end
			local result_index = index + 1
			local result_len = result[1]:len()
			_filter(subject:sub(index + 1, result_index + result_len - 1), index)
			index = result_index + result_len
			if delim then
				for i = 2, #result do
					if result[i] then
						_filter(result[i], result_index + result[1]:find(result[i]) - 1)
					end
				end
			end
			limit = limit - 1
		end

		while limit ~= 1 do
			exec_pattern()
			if limit <= 0 or index >= #subject then break end
		end

		_filter(subject:sub(index + 1), index)

		return ret
	end
end

