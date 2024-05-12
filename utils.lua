
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

	table.fill = function(start, num, mixed)
		local key, tmp = {}, {}
		if start == 1 then
			local arr = {}
			for i = 1, num do
				arr[#arr + 1] = mixed
			end
			return arr
		end

		if start ~= nil and num ~= nil then
			for key = 1, num do
				tmp[key + start] = mixed
			end
		end
		return table.array(tmp, #tmp)
	end

	table.reverse = function(tbl)
		return table.sort(tbl, function(a, b) return a[2] > b[2] end)
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
end
