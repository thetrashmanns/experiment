
do
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

	table.array = function(t, len) --Emulates array behavior in other languages
		local proxy = {}
		local mt = {}
		mt.len = len
		mt.__index = t == nil and {} or t
		mt.__newindex = function(t, k, v)
			if k < t.len and type(k) == "number" then
				t[k] = v
			else
				error("Attempted to write outside array bounds .. bozo", 2)
			end
		end
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
	--Joins a set of strings in a table with a given separator
	table.join = function(tbl, val)
		val = val or ''
		local final = tbl[1] .. val
		for i = 2, #tbl do
			final = final .. val .. tbl[i]
		end
		return final
	end

	table.fill = function(start, mixed, num, to_str)
		local tmp = {}
		if start == 1 then
			local arr = {}
			for i = 1, num do
				arr[#arr + 1] = mixed
			end
			return table.array(arr, #arr)
		end

		if start ~= nil and num ~= nil then
			for key = start, num do
				tmp[key + start] = mixed
			end
		end

		if to_str then
			local arr = ""
			for i = 1, num do
				arr = arr .. mixed
			end
			return arr
		end
		return table.array(tmp, #tmp)
	end

	table.reverse = function(tab)
		for i = 1, #tab >> 1, 1 do
			tab[i], tab[#tab-i+1] = tab[#tab-i+1], tab[i]
		end
		return tab
	end	

	math.round = function(n, precision)
		precision = precision or 1

		return math.floor((n + precision * 0.5) / precision) * precision
	end

	table.merge = function(...)
		local tables_to_merge = { ... }
    	assert(#tables_to_merge > 1, "There should be at least two tables to merge them")

    	for k, t in ipairs(tables_to_merge) do
        	assert(type(t) == "table", string.format("Expected a table as function parameter %d", k))
    	end

    	local result = tables_to_merge[1]

    	for i = 2, #tables_to_merge do
        	local from = tables_to_merge[i]
        	for k, v in pairs(from) do
            	if type(k) == "number" then
                	table.insert(result, v)
            	elseif type(k) == "string" then
                	if type(v) == "table" then
                    	result[k] = result[k] or {}
                    	result[k] = table.merge(result[k], v)
                	else
                    	result[k] = v
                	end
            	end
        	end
    	end

    	return result
	end

	string.sprintf = function(...)
		--[[
			Lua doesn't have regex :(
			Below is the same as: /%%|%(\d+\$)?([-+\'#0 ]*)(\*\d+\$|\*|\d+)?(\.(\*\d+\$|\*|\d+))?([scboxXuideEfFgG])/g
			(in JavaScript Regex)
		--]]
		local function regex_emulate(str)
			local result = ""
			local tmp = string.find(str, "%%%%")
			if not tmp then
				if str:find("%d+%$") then
					for w in str:gmatch("%d+%$") do
						result = result .. w
					end
				elseif str:find("[%-%+\'#0%s]+") then
					for w in str:gmatch("[%-%+\'#0%s]+") do
						result = result .. w
					end
				elseif str:find("%*%d+%$") or str:find("%*") or str:find("%d+") then
					if str:find("%*%d+%$") then
						for w in str:gmatch("%*%d+%$") do
							result = result .. w
						end
					elseif str:find("%*") then
						for w in str:gmatch("%*") do
							result = result .. w
						end
					else
						for w in str:gmatch("%d+") do
							result = result .. w
						end
					end
				elseif str:find("%.%*%d+%$") or str:find("%.%*") or str:find("%.%d+") then
					if str:find("%.%*%d+%$") then
						for w in str:gmatch("%*%d+%$") do
							result = result .. w
						end
					elseif str:find("%.%*") then
						for w in str:gmatch("%*") do
							result = result .. w
						end
					else
						for w in str:gmatch("%.%d+") do
							result = result .. w
						end
					end
				elseif str:find("[scboxXuideEfFgG]") then
					for w in str:gmatch("[scboxXuideEfFgG]") do
						result = result .. w
					end
				end
			else
				for w in str:gmatch("%%%%") do
					result = result .. w
				end
			end
			return result
		end

		local a = {...}
		local i = 1
		local format = a[i + 1]

		local pad = function(str, len, chr, l_justify)
			chr = chr or ' '
			local padding = #str >= len and '' or table.fill(1, chr, 1 + len - str.length >>> 0, true)
			return l_justify and str .. padding or padding .. str
		end

		local justify = function(value, prefix, l_justify, min_w, zero_pad, cust_pad_char)
			local diff = min_w - #value
			if diff > 0 then
				if l_justify or not zero_pad then
					value = pad(value, min_w, cust_pad_char, l_justify)
				else
					value = value:sub(0, #prefix) .. pad('', diff, '0', true) .. value:sub(#prefix)
				end
			end
			return value
		end

		local format_base_x = function(value, base, prefix, l_justify, min_w, zero_pad)
			local num = value >>> 0
			prefix = prefix and number and { '2' = '0b', '8' = '0', '16' = '0x'}[base] or ''
			value = prefix .. pad(tostring(tonumber(tostring(number), base)), precision or 0, '0', false)
			return justify(value, prefix, l_justify, min_w, zero_pad)
		end
	end
end
