local iso_map = table.read_only({
	--For my purposes it needs to only contain these characters, more can be found here:
	--https://en.wikipedia.org/wiki/ISO/IEC_8859-1
	{ " ", "!", "\"", "#", "$", "\%", "&", "\'", "\(", "\)", "\*", "\+", ",", ".", "\/" },
	{ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "\?" },
	{ "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O" },
	{ "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_" }
})


function convert_iso(str)
	local function get_conversion(char)
		if tonumber(char) ~= nil then --Rather than search each row, just jump to the row with digits.
			return "0x3" .. char
		else
			for bruh = 1, 2 do --Two rows contain the characters I will be looking for.
				for i = 1, 16 do --Each ISO row is 16 characters
					if char == iso_map[bruh + 2][i] then
						return i > 10 and "0x" .. tostring(bruh + 2) .. iso_map[3][i - 9] or "0x" .. tostring(bruh + 2) .. tostring(i - 1)
					end
				end
			end
		end
	end

	local converted = {}
	for i = 1, #str do
		converted[#converted + 1] = get_conversion(str[i])
	end
	return converted
end
