
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

	table.fill = function(start, mixed, len, to_str)
		local tmp = {}
		if start == 1 then
			local arr = {}
			for i = 1, len do
				arr[#arr + 1] = mixed
			end
			return table.array(arr, #arr)
		end

		if start ~= nil and len ~= nil then
			for key = start, len do
				tmp[key] = mixed
			end
		end

		if to_str then
			local arr = ""
			for i = 1, len do
				arr = arr .. mixed
			end
			return arr
		end
		return table.array(tmp, #tmp)
	end

	table.reverse = function(tab)
		for i = 1, #tab >> 1, 1 do
			tab[i], tab[#tab - i + 1] = tab[#tab - i + 1], tab[i]
		end
		return tab
	end	

	math.round = function(n, precision)
		precision = precision or 1

		return math.floor((n + precision * 0.5) / precision) * precision
	end

	table.merge = function(...)
		local tables_to_merge = { ... }
    	assert(#tables_to_merge > 1, "There should be at least two tables to merge")

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
			prefix = prefix and num and { '2' = '0b', '8' = '0', '16' = '0x'}[base] or ''
			--This is fucking stupid.
			value = prefix .. pad(tostring(tonumber(tostring(number), base)), precision or 0, '0', false)
			return justify(value, prefix, l_justify, min_w, zero_pad)
		end

		local format_str = function(val, l_justify, min_w, precision, zero_pad, cust_pad_char)
			if precision then
				val = val:sub(1, precision)
			end
			return justify(val, '', l_justify, min_w, zero_pad, cust_pad_char)
		end

		local do_format = function(sub_str, val_index, flags, min_w, _, precision, _type)
			local num, prefix, method, txt_trans, val;

			if sub_str == "%%" then
				return '%'
			end

			local l_justify, pos_prefix, zero_pad, prefix_base_x, cust_pad_char = false, '', false, false, ' '
			local flag_l = #flags

			for j = 1, flag_l do
				if flags[j] == ' ' then
					pos_prefix = ' '
				elseif flags[j] == '+' then
					pos_prefix = '+'
				elseif flags[j] == '-' then
					l_justify = true
				elseif flags[j] == "\'" then
					cust_pad_char = flags[j + 1]
				elseif flags[j] == '0' then
					zero_pad = true
				elseif flags[j] == '#' then
					prefix_base_x = true
				end
			end

			if not min_w then
				min_w = 0
			elseif min_w == '*' then
				min_w = +a[i + 1]
			elseif min_w[1] == '*' then
				min_w = +a[tonumber(min_w:sub(2, -1))]
			else
				min_w = +min_w
			end

			if min_w < 0 then
				min_w = -min_w
				l_justify = true
			end

			if min_w >= math.huge or min_w <= -math.huge then
				error('sprintf: (minimum-)width must be finite')
			end

			if not precision then
				precision = 'fFeE':find(_type) > -1 and 6 or _type == 'd' and 0 or nil
			elseif precision == '*' then
				precision = +a[i + 1]
			elseif precision[1] == '*' then
				precision = +a[tonumber(precision:sub(2, -1))]
			else
				precision = +precision
			end

			val = val_index and a[tonumber(val_index:sub(1, -1))] or a[i + 1]

			if _type == 's' then
				return format_str(tostring(val), l_justify, min_w, precision, zero_pad, cust_pad_char)
			elseif _type == 'c' then
				format_str(utf8.char(+value), l_justify, min_w, precision, zero_pad)
			elseif _type == 'b' then
				format_base_x(val, 2, prefix_base_x, l_justify, min_w, precision, zero_pad)
			elseif _type == 'o' then
				format_base_x(val, 8, prefix_base_x, l_justify, min_w, precision, zero_pad)
			elseif _type == 'x' or _type == 'X' then
				format_base_x(val, 16, prefix_base_x, l_justify, min_w, precision, zero_pad)
			elseif _type == 'u' then
				format_base_x(val, 10, prefix_base_x, l_justify, min_w, precision, zero_pad)
			elseif _type == 'd' then
				num = val or 0
				--Don't ask
				num = math.round(num - num % 1)
				prefix = num < 0 and '-' or pos_prefix
				val  = prefix .. pad(tostring(math.abs(num)), precision, '0', false)
				return justify(val, prefix, l_justify, min_w, zero_pad)
			else
				return sub_str
			end

			return regex_emulate(do_format(format))
		end
	end
	--This is an incomplete version of preg_split, can't be bothered to go beyond my needs.
	string.preg_split = function(pattern, subject, limit, flags)
		limit = limit or 0
		flags = flags or ''
		
		local result;
		local ret, index, i, no_empty, delim, offset, OPTs, opt_tmp = {}, 1, 1, false, false, false, {}, 0
		pattern = type(pattern) ~= "string" or "/.*/(%f[%w]%w%f[%W])*"
		
		OPTs = {
			PREG_SPLIT_NO_EMPTY = 1,
			PREG_SPLIT_DELIM_CAPTURE = 2,
			PREG_SPLIT_OFFSET_CAPTURE = 4
		}

		if type(flags) ~= 'number' then
			flags = table.concat(flags)
			for i = 1 #flags do
				if OPTs[flags[i]] then
					opt_tmp = opt_tmp | OPTs[flags[i]]
				end
			end
			flags = opt_tmp
		end
		no_empty = flags & OPTs.PREG_SPLIT_NO_EMPTY
		delim = flags & OPTs.PREG_SPLIT_DELIM_CAPTURE
		offset = flags & OPTs.PREG_SPLIT_OFFSET_CAPTURE

		local _filter = function(str, str_index)
			if no_empty and not #str then
				return
			end

			if offset then
				str = {str, str_index}
			end

			ret[#ret + 1] = str
		end

		for i, w in subject:gmatch(pattern) do
			if limit == 1 then break end

			_filter(subject:sub(index, i), index)
			index = i + #w
			limit = limit - 1
		end
		_filter(subject:sub(index, #subject), index)
		return ret
	end
end
