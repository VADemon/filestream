--[[
The MIT License (MIT)

Copyright (c) 2016 VADemon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

local streamlib = {
	CONST = {
		UBYTE_MAX = 255,
		BYTE_MAX = 127,
		BYTE_MIN = -127,
		
		USHORT_MAX = 65535,
		SHORT_MAX = 32767,
		SHORT_MIN = -32767,
		
		ULONGSHORT_MAX = 16777215,
		LONGSHORT_MAX = 8388607,
		LONGSHORT_MIN = -8388607,
		
		UINT_MAX = 4294967295,
		INT_MAX = 2147483647,
		INT_MIN = -2147483647
	}
}

---- Math Functions

function streamlib:char2Binary(ch)
	local num = ch:byte()
	local bintbl = {}
	--print("num:", num)
	
	for i = 7, 0, -1 do
		local bitvalue = 2^i
		--print(num, bitvalue)
		
		if num >= bitvalue then
			bintbl [ i ] = true
			num = num - bitvalue
		else
			bintbl [ i ] = false
		end
	end
	
	--print(binstr)
	return bintbl
end

function streamlib:byte2Binary(num)
	return self:char2Binary(string.char(num))
end

function streamlib:char2BinaryString(ch)
	local num = ch:byte()
	local binstr = ""
		
	for i = 7, 0, -1 do
		local bitvalue = 2^i
				
		if num >= bitvalue then
			binstr = binstr .. "1"
			num = num - bitvalue
		else
			binstr = binstr .. "0"
		end
	end
	
	return binstr
end

function streamlib:byte2BinaryString(num)
	return self:char2BinaryString(string.char(num))
end

function streamlib:composeByte(...)
	local boolTbl = {...}	-- MSB -> LSB order
	local byte = 0
	
	for i = 1, 8 do
		if boolTbl[ i ] then
			byte = byte + 2^(8-i)
		end
	end
	
	return byte
end

function streamlib:UShort2String(num)
	assert(num < self.CONST.USHORT_MAX, "UShort2String: Number is greater than CONST.USHORT_MAX!")
	local byte1, byte2 = 0, 0
	
	for i = 15, 0, -1 do
		local bitvalue = 2^i
		
		-- bit is set?
		if num >= bitvalue then
			if i > 7 then
				byte1 = byte1 + 2^(i-8)	-- set the corresponding bit of byte
			else
				byte2 = byte2 + bitvalue
			end
			num = num - bitvalue
			
			
		end	-- else: leave bit in byte as zero
	end
	
	return string.char(byte1) .. string.char(byte2)
end

function streamlib:short2String(num)
	if num < 0 then
		num = math.abs(num - 2^15)
	end
	
	return self:UShort2String(num)
end

function streamlib:ULongShort2String(num)
	assert(num < self.CONST.ULONGSHORT_MAX, "ULongShort2String: Number is greater than CONST.ULONGSHORT_MAX!")
	local byte1, byte2, byte3 = 0, 0, 0
	
	for i = 23, 0, -1 do
		local bitvalue = 2^i
		
		-- bit is set?
		if num >= bitvalue then
			if i > 15 then
				byte1 = byte1 + 2^(i-16)
			elseif i > 7 then
				byte2 = byte2 + 2^(i-8)	-- set the corresponding bit of byte
			else
				byte3 = byte3 + bitvalue
			end
			num = num - bitvalue
			
			
		end	-- else: leave bit in byte as zero
	end
	
	return string.char(byte1) .. string.char(byte2) .. string.char(byte3)
end

function streamlib:longShort2String(num)
	if num < 0 then
		num = math.abs(num - 2^23)
	end
	
	return self:ULongShort2String(num)
end

function streamlib:UInt2String(num)
	assert(num < self.CONST.UINT_MAX, "UInt2String: Number is greater than CONST.UINT_MAX!")
	local byte1, byte2, byte3, byte4 = 0, 0, 0, 0
	
	for i = 31, 0, -1 do
		local bitvalue = 2^i
		
		-- bit is set?
		if num >= bitvalue then
			if i > 23 then
				byte1 = byte1 + 2^(i-24)
			elseif i > 15 then
				byte2 = byte2 + 2^(i-16)
			elseif i > 7 then
				byte3 = byte3 + 2^(i-8)	-- set the corresponding bit of byte
			else
				byte4 = byte4 + bitvalue
			end
			num = num - bitvalue
			
			
		end	-- else: leave bit in byte as zero
	end
	
	return string.char(byte1) .. string.char(byte2) .. string.char(byte3) .. string.char(byte4)
end

function streamlib:int2String(num)
	if num < 0 then
		num = math.abs(num - 2^31)
	end
	
	return self:UInt2String(num)
end

-- ftp://ftp.openwatcom.org/pub/devel/docs/ieee-754.pdf
-- http://www3.ntu.edu.sg/home/ehchua/programming/java/datarepresentation.html#show-toc
-- https://www.youtube.com/watch?v=r0F_3XKcu5A
-- http://www.rapidtables.com/calc/math/Log_Calculator.htm @> TODO FOR NEGATIVE NUMBERS
-- https://ru.wikipedia.org/wiki/%D0%A7%D0%B8%D1%81%D0%BB%D0%BE_%D0%B4%D0%B2%D0%BE%D0%B9%D0%BD%D0%BE%D0%B9_%D1%82%D0%BE%D1%87%D0%BD%D0%BE%D1%81%D1%82%D0%B8
function streamlib:parseDouble(byteTbl)
	local sign
	local exponent, mantissa = 0, 0

	-- BYTE 1, bits 63-56
	local byte1 = byteTbl[1]
	
	if byte1 > self.CONST.BYTE_MAX then
		sign = false -- negative
		byte1 = byte1 - (2^7)
	else
		sign = true
	end
	
	-- the first bit was parsed above, hence [6,0]
	for i = 6, 0, -1 do
		local bitvalue = 2^i
		
		if byte1 >= bitvalue then
			exponent = exponent + 2^(i+4)
			byte1 = byte1 - bitvalue
		end
	end
	
	-- BYTE2, 55-48
	-- exponent bits 3-0
	-- mantissa bits 51-48
	local byte2 = byteTbl[2]
	
	for i = 7, 0, -1 do
		local bitvalue = 2^i
		
		if i > 3 and byte2 >= bitvalue then
			-- exponent
			exponent = exponent + 2^(i-4)
			byte2 = byte2 - bitvalue
			
		elseif byte2 >= bitvalue then
			-- mantissa
			mantissa = mantissa + 2^(i+48)
			byte2 = byte2 - bitvalue	-- thanks to Syping for: double dtest = 1.76544129; // 3ffc3f3f5db8edc8
		end
	end
	
	--print("Mantissa calc:")
	-- MANTISSA BYTES 3-8, BITS 47-0
	--[[ PS: That's why I haven't written such a loop yet:  print("i|	 7 |	 6 |	 5 |	 4 |	 3 |	 2 |	 1 |	 0 |	"); print("mb|" .. string.rep("_", 69)); for mb = 3, 8 do; io.write(mb .. " |\t" ); for i = 7, 0, -1 do; io.write(" ".. i+8*(8-mb) .." |\t"); end; io.write("\n"); end  ]]--
	for mb = 3, 8 do
		for i = 7, 0, -1 do
			local bitvalue = 2^i
			
			if byteTbl[ mb ] >= bitvalue then
				--print("Mantissa byte ".. mb .." is bigger than bitvalue ".. byteTbl[ mb ] ..">=".. bitvalue)
				mantissa = mantissa + 2^(i+8*(8-mb))	-- add bitvalue inside the current byte
				
				byteTbl[ mb ] = byteTbl[ mb ] - bitvalue	-- @> You can optimize this, I believe in you!
			end
		end
	end
	
	--print("Sign: ".. tostring(sign), "Exponent:" .. exponent - 1023)
	--print("Mantissa:" .. mantissa)
	--print("Calc: ".. (sign and 1 or -1) * (1 + mantissa / (2^52)) * (2^(exponent - 1023)))
	
	-- exceptions:
	if exponent == 0 then
		if mantissa == 0 then
			-- return ZERO
			return (sign and (0) or (-0)), sign	-- Lua is buggy when it comes down to returning negative Zero
		else
			-- DENORMALIZED NUMBER
			--print("DENORMALIZED NUMBER!")
			return (sign and 1 or -1) * (0 + mantissa / (2^52)) * (2^(1 - 1023))
		end
	
	elseif exponent == 0x7ff then	-- 2047
		-- INF or NaN
		--print("INF OR NAN, Mantissa", mantissa)
		if mantissa == 0 then
			-- INF
			return (sign and (math.huge) or (-math.huge)), sign
		else
			-- NaN
			-- todo: Preserve Mantissa value, even though its not in the standard
			-- more: https://habrahabr.ru/post/112953/
			return (0/0), sign
		end
	end
	
	return ((sign and 1 or -1) * (1 + mantissa / (2^52)) * (2^(exponent - 1023))), sign
end

function streamlib:decodeDouble(str)
	if #str == 8 then
		local byteTbl = {}
		for i = 1, 8 do
			byteTbl[ i ] = string.byte(string.sub(str, i, i))
		end
		
		return self:parseDouble(byteTbl)
	else
		error("streamlib:decodeDouble: str is too short to be a double!")
	end
end

function streamlib:encodeDouble(num)
	-- NaN Check
	if num ~= num then
		-- Sign=0/1, Exponent=1...1, Mantissa=!0
		--print("encodeDouble: input is NaN")
		return string.char(0x7f,0xff, 0xff,0xff, 0xff,0xff, 0xff,0xff)
	end
	
	-- ZERO and Sign Determination Checks
	local sign = true
	
	if num == 0 then
		-- Positive Zero
		--print("encodeDouble: input is Zero")
		return "\0\0\0\0\0\0\0\0"
	elseif num < 0 then
		sign = false
		num = math.abs(num)
	end
	
	-- Infinity Check
	if num == math.huge then
		-- Set Sign if needed
		-- Sign=0/1, Exponent=1...1, Mantissa=0...0
		--print("encodeDouble: input is inf")
		return string.char(0x7f + (sign and 0 or 0x80),0xf0, 0x00,0x00, 0x00,0x00, 0x00,0x00)
	end
		
	local byteTbl = {
		[1] = (sign and 0 or 128),
		[2] = 0,	[3] = 0,	[4] = 0,	[5] = 0,	[6] = 0,	[7] = 0,	[8] = 0,
	}
	
	local exponent, mantissa_fraction
	if num >= 1 then
		exponent = math.modf(math.log(num) / math.log(2))	-- Lua 5.1 only has Log_e and Log_10
		mantissa_fraction = select(2, math.modf(num / 2^exponent) )
	else
		exponent = 0
		
		repeat 
			exponent = exponent - 1
			local fraction = num / 2^exponent
			--print("fraction: ".. fraction)
		until fraction >= 1 or exponent == -1023
		
		if exponent == -1023 then -- @TODO - Denormalized numbers
			print("streamlib:encodeDouble: The number provided is REALLY small to be represented as a normalised double. Denormalised values are NOT tested/implemented yet!")
		end
		
		-- I suppose it's faster to calculate the number once again than to factorise the local fraction var
		mantissa_fraction = math.abs(select(2, math.modf(num / 2^exponent)))
	end
	
	local biased_exp = 1023 + exponent
	print("Exponent: ".. exponent, "biased exp: ".. biased_exp)
	print("Mantissa fraction: ".. mantissa_fraction)
	
	-- Encode Exponent
	for i = 10, 0, -1 do
		local bitvalue = 2^i
		--print("Exponent bit: ".. i)
		if i > 3 and biased_exp >= bitvalue then
			--print("Exponent is bigger than bitvalue: ".. biased_exp .. ">=".. bitvalue, "2^"..(i-4))
			byteTbl[1] = byteTbl[1] + 2^(i-4)
			biased_exp = biased_exp - bitvalue
			
		elseif biased_exp >= bitvalue then
			--print("Exponent is bigger than bitvalue: ".. biased_exp .. ">=".. bitvalue, "2^"..(i+4))
			byteTbl[2] = byteTbl[2] + 2^(i+4)
			biased_exp = biased_exp - bitvalue
		end
	end
	--print("Biased Exponent should equal zero: ".. biased_exp)
	
	
	--local mantissa_string = ""
	--print("Calculating mantissa value")
	-- Calculate and Encode Mantissa Bits
	local byte, bit = 2, 3
	repeat
		
		local int, fraction = math.modf(mantissa_fraction * 2)
		--print("\tInt: ".. int, "fraction: ".. fraction, "Current Mantissa: ".. mantissa_fraction)
		if int == 1 then
			byteTbl[ byte ] = byteTbl[ byte ] + 2^bit
			--mantissa_string = mantissa_string .. "1"
			--print("\tCurrent mantissa byte: ".. byte .. " bit: ".. bit .. " = 1")
		else
			--mantissa_string = mantissa_string .. "0"
			--print("\tCurrent mantissa byte: ".. byte .. " bit: ".. bit .. " = 0")
		end
		
		mantissa_fraction = fraction
		--- Counter
		if bit ~= 0 then
			bit = bit - 1
		else
			byte = byte + 1
			bit = 7
		end
	until (mantissa_fraction == 0 or (byte == 8 and bit == 0))
	
	--[[
	print(self:byte2BinaryString(byteTbl[1]))
	print(self:byte2BinaryString(byteTbl[2]))
	print(self:byte2BinaryString(byteTbl[3]))
	print(self:byte2BinaryString(byteTbl[4]))
	print(self:byte2BinaryString(byteTbl[5]))
	print(self:byte2BinaryString(byteTbl[6]))
	print(self:byte2BinaryString(byteTbl[7]))
	print(self:byte2BinaryString(byteTbl[8]))
	]]
	
	return string.char(byteTbl[1], byteTbl[2], byteTbl[3], byteTbl[4], byteTbl[5], byteTbl[6], byteTbl[7], byteTbl[8])
end

---- Stream Functions
function streamlib:openStream(path, mode)
	local stream = {}
	setmetatable(stream, self)
	self.__index = self
	stream.stream = assert(io.open(path, mode))
	
	return stream
end
streamlib.open = streamlib.openStream

function streamlib:openReadStream(path)
	return self:open(path, "rb")
end

function streamlib:openWriteStream(path)
	return self:open(path, "wb")	-- "w" writes \r\n on Windows instead of just \n
end

function streamlib:closeStream()
	self.stream:close()
	-- self(.stream) = nil ?
end
streamlib.close = streamlib.closeStream

function streamlib:setPos(pos)
	self.stream:seek("set", pos)
end

function streamlib:shiftPos(amount)
	self.stream:seek("set", self.stream:seek() + amount)
end


--- Numbers

function streamlib:readUByte()
	return string.byte(self.stream:read(1))
end

function streamlib:readByte()
	local num = string.byte(self.stream:read(1))
	
	return (num > self.CONST.BYTE_MAX and (num - 2^8 + 1)) or num
end

function streamlib:writeByte(num)
	self.stream:write(string.char(num))
	return self
end

function streamlib:readUShort()
	local byte1, byte2 = self.stream:read(1), self.stream:read(1)
	
	if byte1 and byte2 then
		return (string.byte(byte1) * 2^8) + string.byte(byte2)
	end
	
	return nil
end

function streamlib:readShort()
	local num = self:readUShort()
	
	if num then
		return (num > self.CONST.SHORT_MAX and (num - 2^16 + 1)) or num
	end
	
	return nil
end

function streamlib:writeShort(num)
	self.stream:write(self:short2String(num))
	return self
end

function streamlib:readULongShort()
	local byte1, byte2, byte3 = self.stream:read(1), self.stream:read(1), self.stream:read(1)
	
	if byte1 and byte2 and byte3 then
		return (string.byte(byte1) * 2^16) + (string.byte(byte2) * 2^8) + string.byte(byte3)
	end
	
	return nil
end

function streamlib:readLongShort()
	local num = self:readULongShort()
	
	if num then
		return (num > self.CONST.LONGSHORT_MAX and (num - 2^24 + 1)) or num
	end
	
	return nil
end

function streamlib:writeLongShort(num)
	self.stream:write(self:longShort2String(num))
	return self
end

function streamlib:readUInt()
	-- @TODO string.byte (s [, i [, j]])
	local byte1, byte2, byte3, byte4 = self.stream:read(1), self.stream:read(1), self.stream:read(1), self.stream:read(1)
	
	if byte1 and byte2 and byte3 and byte4 then
		return (string.byte(byte1) * 2^24) + (string.byte(byte2) * 2^16) + (string.byte(byte3) * 2^8) + string.byte(byte4)
	end
	
	return nil
end

function streamlib:readInt()
	local num = self:readUInt()
	
	if num then
		return (num > self.CONST.INT_MAX and (num - 2^32 + 1)) or num
	end
	
	return nil
end

function streamlib:writeInt(num)
	self.stream:write(self:int2String(num))
	return self
end

function streamlib:readDouble()
	local byteTbl = {}
	
	for i = 1, 8 do
		local char = self.stream:read(1)	-- @TODO string.byte (s [, i [, j]])
		
		if char then
			byteTbl[ i ] = string.byte(char)
		else
			return nil
		end
	end
	
	return self:parseDouble(byteTbl)
end

function streamlib:writeDouble(num)
	self.stream:write(self:encodeDouble(num))
	return self
end

--- Strings

function streamlib:readLine()
	return self.stream:read("*l")
end

function streamlib:writeLine(line)
	self.stream:write((line or "") .. "\n")
	return self
end

function streamlib:readChar()
	return self.stream:read(1)
end

function streamlib:writeChar(char)
	self.stream:write(string.sub(char, 1, 1))
	return self
end

function streamlib:readPlainText(length)
	return self.stream:read(length)
end

function streamlib:writePlainText(str)
	self.stream:write(str)
	return self
end

function streamlib:readString()
	local length = self:readByte()
	
	if length then
		return self.stream:read(length)
	end
	
	return nil
end

function streamlib:writeString(str)
	local length = #str
	if length > 255 then
		print("[WARNING] Streamlib: String passed to writeString is longer than 255 and will be truncated!")
		length = 255
		str = str:sub(1, 255)
	end
	
	self:writeByte(length)
	self:writePlainText(str)
	return self
end

streamlib.writeLPString = streamlib.writeString

function streamlib:readNTString()
	local str = ""
	
	repeat
		-- TODO: Is reading in bigger chunks and applying string.find faster?
		local char = self.stream:read(1)
		
		if char ~= "\0" then
			str = str .. char
		else
			zerobytePos = self.stream:seek()
		end
	
	until zerobytePos
	
	return str
end

function streamlib:writeNTString(str)
	self:writePlainText(str .. "\0")
	return self
end

return streamlib