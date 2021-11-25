local args = {...}
args = {"serve","-b","-s","-p null_password"}

function runRawterm()
	--- rawterm.lua - CraftOS-PC raw mode protocol client/server API
	-- By JackMacWindows
	--
	-- @module rawterm
	--
	-- This API provides the ability to host terminals accessible from remote
	-- systems, as well as to render those terminals on the screen. It uses the raw
	-- mode protocol defined by CraftOS-PC to communicate between client and server.
	-- This means that this API can be used to host and connect to a CraftOS-PC
	-- instance running over a WebSocket connection (using an external server
	-- application).
	--
	-- In addition, this API supports raw mode version 1.1, which includes support
	-- for filesystem access. This lets the server send and receive files and query
	-- file information over the raw connection.
	--
	-- To allow the ability to use any type of connection medium to send/receive
	-- data, a delegate object is used for communication. This must have a send and
	-- receive method, and may also have additional methods as mentioned below.
	-- Built-in delegate constructors are provided for WebSockets and Rednet.
	--
	-- See the adjacent rawtermtest.lua file for an example of how to use this API.

	-- MIT License
	--
	-- Copyright (c) 2021 JackMacWindows
	--
	-- Permission is hereby granted, free of charge, to any person obtaining a copy
	-- of this software and associated documentation files (the "Software"), to deal
	-- in the Software without restriction, including without limitation the rights
	-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	-- copies of the Software, and to permit persons to whom the Software is
	-- furnished to do so, subject to the following conditions:
	--
	-- The above copyright notice and this permission notice shall be included in all
	-- copies or substantial portions of the Software.
	--
	-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	-- SOFTWARE.

	local expect = require "cc.expect"
	setmetatable(expect, {__call = function(_, ...) return expect.expect(...) end})

	local rawterm = {}

	local b64str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local keymap = {
		[1] = 0,
		[2] = keys.one,
		[3] = keys.two,
		[4] = keys.three,
		[5] = keys.four,
		[6] = keys.five,
		[7] = keys.six,
		[8] = keys.seven,
		[9] = keys.eight,
		[10] = keys.nine,
		[11] = keys.zero,
		[12] = keys.minus,
		[13] = keys.equals,
		[14] = keys.backspace,
		[15] = keys.tab,
		[16] = keys.q,
		[17] = keys.w,
		[18] = keys.e,
		[19] = keys.r,
		[20] = keys.t,
		[21] = keys.y,
		[22] = keys.u,
		[23] = keys.i,
		[24] = keys.o,
		[25] = keys.p,
		[26] = keys.leftBracket,
		[27] = keys.rightBracket,
		[28] = keys.enter,
		[29] = keys.leftCtrl,
		[30] = keys.a,
		[31] = keys.s,
		[32] = keys.d,
		[33] = keys.f,
		[34] = keys.g,
		[35] = keys.h,
		[36] = keys.j,
		[37] = keys.k,
		[38] = keys.l,
		[39] = keys.semiColon,
		[40] = keys.apostrophe,
		[41] = keys.grave,
		[42] = keys.leftShift,
		[43] = keys.backslash,
		[44] = keys.z,
		[45] = keys.x,
		[46] = keys.c,
		[47] = keys.v,
		[48] = keys.b,
		[49] = keys.n,
		[50] = keys.m,
		[51] = keys.comma,
		[52] = keys.period,
		[53] = keys.slash,
		[54] = keys.rightShift,
		[55] = keys.multiply,
		[56] = keys.leftAlt,
		[57] = keys.space,
		[58] = keys.capsLock,
		[59] = keys.f1,
		[60] = keys.f2,
		[61] = keys.f3,
		[62] = keys.f4,
		[63] = keys.f5,
		[64] = keys.f6,
		[65] = keys.f7,
		[66] = keys.f8,
		[67] = keys.f9,
		[68] = keys.f10,
		[69] = keys.numLock,
		[70] = keys.scrollLock,
		[71] = keys.numPad7,
		[72] = keys.numPad8,
		[73] = keys.numPad9,
		[74] = keys.numPadSubtract,
		[75] = keys.numPad4,
		[76] = keys.numPad5,
		[77] = keys.numPad6,
		[78] = keys.numPadAdd,
		[79] = keys.numPad1,
		[80] = keys.numPad2,
		[81] = keys.numPad3,
		[82] = keys.numPad0,
		[83] = keys.numPadDecimal,
		[87] = keys.f11,
		[88] = keys.f12,
		[100] = keys.f13,
		[101] = keys.f14,
		[102] = keys.f15,
		[111] = keys.kana,
		[121] = keys.convert,
		[123] = keys.noconvert,
		[125] = keys.yen,
		[141] = keys.numPadEquals,
		[144] = keys.cimcumflex,
		[145] = keys.at,
		[146] = keys.colon,
		[147] = keys.underscore,
		[148] = keys.kanji,
		[149] = keys.stop,
		[150] = keys.ax,
		[156] = keys.numPadEnter,
		[157] = keys.rightCtrl,
		[179] = keys.numPadComma,
		[181] = keys.numPadDivide,
		[184] = keys.rightAlt,
		[197] = keys.pause,
		[199] = keys.home,
		[200] = keys.up,
		[201] = keys.pageUp,
		[203] = keys.left,
		[205] = keys.right,
		[207] = keys["end"],
		[208] = keys.down,
		[209] = keys.pageDown,
		[210] = keys.insert,
		[211] = keys.delete
	}
	local keymap_rev = {
		[0] = 1,
		[keys.one] = 2,
		[keys.two] = 3,
		[keys.three] = 4,
		[keys.four] = 5,
		[keys.five] = 6,
		[keys.six] = 7,
		[keys.seven] = 8,
		[keys.eight] = 9,
		[keys.nine] = 10,
		[keys.zero] = 11,
		[keys.minus] = 12,
		[keys.equals] = 13,
		[keys.backspace] = 14,
		[keys.tab] = 15,
		[keys.q] = 16,
		[keys.w] = 17,
		[keys.e] = 18,
		[keys.r] = 19,
		[keys.t] = 20,
		[keys.y] = 21,
		[keys.u] = 22,
		[keys.i] = 23,
		[keys.o] = 24,
		[keys.p] = 25,
		[keys.leftBracket] = 26,
		[keys.rightBracket] = 27,
		[keys.enter] = 28,
		[keys.leftCtrl] = 29,
		[keys.a] = 30,
		[keys.s] = 31,
		[keys.d] = 32,
		[keys.f] = 33,
		[keys.g] = 34,
		[keys.h] = 35,
		[keys.j] = 36,
		[keys.k] = 37,
		[keys.l] = 38,
		[keys.semicolon or keys.semiColon] = 39,
		[keys.apostrophe] = 40,
		[keys.grave] = 41,
		[keys.leftShift] = 42,
		[keys.backslash] = 43,
		[keys.z] = 44,
		[keys.x] = 45,
		[keys.c] = 46,
		[keys.v] = 47,
		[keys.b] = 48,
		[keys.n] = 49,
		[keys.m] = 50,
		[keys.comma] = 51,
		[keys.period] = 52,
		[keys.slash] = 53,
		[keys.rightShift] = 54,
		[keys.leftAlt] = 56,
		[keys.space] = 57,
		[keys.capsLock] = 58,
		[keys.f1] = 59,
		[keys.f2] = 60,
		[keys.f3] = 61,
		[keys.f4] = 62,
		[keys.f5] = 63,
		[keys.f6] = 64,
		[keys.f7] = 65,
		[keys.f8] = 66,
		[keys.f9] = 67,
		[keys.f10] = 68,
		[keys.numLock] = 69,
		[keys.scollLock or keys.scrollLock] = 70,
		[keys.numPad7] = 71,
		[keys.numPad8] = 72,
		[keys.numPad9] = 73,
		[keys.numPadSubtract] = 74,
		[keys.numPad4] = 75,
		[keys.numPad5] = 76,
		[keys.numPad6] = 77,
		[keys.numPadAdd] = 78,
		[keys.numPad1] = 79,
		[keys.numPad2] = 80,
		[keys.numPad3] = 81,
		[keys.numPad0] = 82,
		[keys.numPadDecimal] = 83,
		[keys.f11] = 87,
		[keys.f12] = 88,
		[keys.f13] = 100,
		[keys.f14] = 101,
		[keys.f15] = 102,
		[keys.numPadEquals or keys.numPadEqual] = 141,
		[keys.numPadEnter] = 156,
		[keys.rightCtrl] = 157,
		[keys.rightAlt] = 184,
		[keys.pause] = 197,
		[keys.home] = 199,
		[keys.up] = 200,
		[keys.pageUp] = 201,
		[keys.left] = 203,
		[keys.right] = 205,
		[keys["end"]] = 207,
		[keys.down] = 208,
		[keys.pageDown] = 209,
		[keys.insert] = 210,
		[keys.delete] = 211
	}

	local function minver(version)
		local res
		if _CC_VERSION then res = version <= _CC_VERSION
		elseif not _HOST then res = version <= os.version():gsub("CraftOS ", "")
		else res = version <= _HOST:match("ComputerCraft ([0-9%.]+)") end
		assert(res, "This program requires ComputerCraft " .. version .. " or later.")
	end

	local function base64encode(str)
		local retval = ""
		for s in str:gmatch "..." do
			local n = s:byte(1) * 65536 + s:byte(2) * 256 + s:byte(3)
			local a, b, c, d = bit32.extract(n, 18, 6), bit32.extract(n, 12, 6), bit32.extract(n, 6, 6), bit32.extract(n, 0, 6)
			retval = retval .. b64str:sub(a+1, a+1) .. b64str:sub(b+1, b+1) .. b64str:sub(c+1, c+1) .. b64str:sub(d+1, d+1)
		end
		if #str % 3 == 1 then
			local n = str:byte(-1)
			local a, b = bit32.rshift(n, 2), bit32.lshift(bit32.band(n, 3), 4)
			retval = retval .. b64str:sub(a+1, a+1) .. b64str:sub(b+1, b+1) .. "=="
		elseif #str % 3 == 2 then
			local n = str:byte(-2) * 256 + str:byte(-1)
			local a, b, c, d = bit32.extract(n, 10, 6), bit32.extract(n, 4, 6), bit32.lshift(bit32.extract(n, 0, 4), 2)
			retval = retval .. b64str:sub(a+1, a+1) .. b64str:sub(b+1, b+1) .. b64str:sub(c+1, c+1) .. "="
		end
		return retval
	end

	local function base64decode(str)
		local retval = ""
		for s in str:gmatch "...." do
			if s:sub(3, 4) == '==' then
				retval = retval .. string.char(bit32.bor(bit32.lshift(b64str:find(s:sub(1, 1)) - 1, 2), bit32.rshift(b64str:find(s:sub(2, 2)) - 1, 4)))
			elseif s:sub(4, 4) == '=' then
				local n = (b64str:find(s:sub(1, 1))-1) * 4096 + (b64str:find(s:sub(2, 2))-1) * 64 + (b64str:find(s:sub(3, 3))-1)
				retval = retval .. string.char(bit32.extract(n, 10, 8)) .. string.char(bit32.extract(n, 2, 8))
			else
				local n = (b64str:find(s:sub(1, 1))-1) * 262144 + (b64str:find(s:sub(2, 2))-1) * 4096 + (b64str:find(s:sub(3, 3))-1) * 64 + (b64str:find(s:sub(4, 4))-1)
				retval = retval .. string.char(bit32.extract(n, 16, 8)) .. string.char(bit32.extract(n, 8, 8)) .. string.char(bit32.extract(n, 0, 8))
			end
		end
		return retval
	end

	local crctable
	local function crc32(str)
		-- calculate CRC-table
		if not crctable then
			crctable = {}
			for i = 0, 0xFF do
				local rem = i
				for j = 1, 8 do
					if bit32.band(rem, 1) == 1 then
						rem = bit32.rshift(rem, 1)
						rem = bit32.bxor(rem, 0xEDB88320)
					else rem = bit32.rshift(rem, 1) end
				end
				crctable[i] = rem
			end
		end
		local crc = 0xFFFFFFFF
		for x = 1, #str do crc = bit32.bxor(bit32.rshift(crc, 8), crctable[bit32.bxor(bit32.band(crc, 0xFF), str:byte(x))]) end
		return bit32.bxor(crc, 0xFFFFFFFF)
	end

	local function decodeIBT(data, pos)
		local ptyp = data:byte(pos)
		pos = pos + 1
		local pat
		if ptyp == 0 then pat = "<j"
		elseif ptyp == 1 then pat = "<n"
		elseif ptyp == 2 then pat = "<B"
		elseif ptyp == 3 then pat = "<z"
		elseif ptyp == 4 then
			local t, keys = {}, {}
			local nent = data:byte(pos)
			pos = pos + 1
			for i = 1, nent do keys[i], pos = decodeIBT(data, pos) end
			for i = 1, nent do t[keys[i]], pos = decodeIBT(data, pos) end
			return t, pos
		else return nil, pos end
		local d = string.unpack(pat, data, pos)
		if ptyp == 2 then d = d ~= 0 end
		pos = pos + string.packsize(pat)
		return d, pos
	end

	local function encodeIBT(val)
		if type(val) == "number" then
			if val % 1 == 0 and val >= -0x80000000 and val < 0x80000000 then return string.pack("<Bj", 0, val)
			else return string.pack("<Bn", 1, val) end
		elseif type(val) == "boolean" then return string.pack("<BB", 2, val and 1 or 0)
		elseif type(val) == "string" then return string.pack("<Bz", 3, val)
		elseif type(val) == "nil" then return "\5"
		elseif type(val) == "table" then
			local keys, vals = {}, {}
			local i = 1
			for k,v in pairs(val) do keys[i], vals[i], i = k, v, i + 1 end
			local s = string.pack("<BB", 4, i - 1)
			for j = 1, i - 1 do s = s .. encodeIBT(keys[j]) end
			for j = 1, i - 1 do s = s .. encodeIBT(vals[j]) end
			return s
		else error("Cannot encode type " .. type(val)) end
	end

	local mouse_events = {[0] = "mouse_click", "mouse_up", "mouse_scroll", "mouse_drag"}
	local fsFunctions = {[0] = fs.exists, fs.isDir, fs.isReadOnly, fs.getSize, fs.getDrive, fs.getCapacity, fs.getFreeSpace, fs.list, fs.attributes, fs.find, fs.makeDir, fs.delete, fs.copy, fs.move, function() end, function() end}
	local openModes = {[0] = "r", "w", "r", "a", "rb", "wb", "rb", "ab"}
	local localEvents = {key = true, key_up = true, char = true, mouse_click = true, mouse_up = true, mouse_drag = true, mouse_scroll = true, mouse_move = true, term_resize = true, paste = true}

	minver "1.91.0"

	--- Creates a new server window object with the specified properties.
	-- This object functions like an object from the window API, and can be used as
	-- a redirection target. It also has a few additional functions to control the
	-- client and connection.
	-- @param delegate The delegate object. This must have two methods named
	-- `:send(data)` and `:receive()`, and may additionally have a `:close()` method
	-- that's called when the server is closed. Every method is called with the `:`
	-- operator, meaning its first argument is the delegate object itself.
	-- @param width The width of the new window.
	-- @param height The height of the new window.
	-- @param id The ID of the window. Multiple window IDs can be sent over one
	-- connection. This defaults to 0.
	-- @param title The title of the window. This defaults to "CraftOS Raw Terminal".
	-- @param parent The parent window to draw to. This allows rendering on both the
	-- screen and a remote terminal. If unspecified, output will only be sent to the
	-- remote terminal.
	-- @param x If parent is specified, the X coordinate to start at. This defaults to 1.
	-- @param y If parent is specified, the Y coordinate to start at. This defaults to 1.
	-- @param blockFSAccess Set this to true to disable filesystem access for clients.
	-- @return The new window object.
	function rawterm.server(delegate, width, height, id, title, parent, x, y, blockFSAccess)
		expect(1, delegate, "table")
		expect(2, width, "number")
		expect(3, height, "number")
		expect(4, id, "number", "nil")
		expect(5, title, "string", "nil")
		expect(6, parent, "table", "nil")
		expect(7, x, "number", "nil")
		expect(8, y, "number", "nil")
		expect.field(delegate, "send", "function")
		expect.field(delegate, "receive", "function")
		expect.field(delegate, "close", "function", "nil")
		title = title or "CraftOS Raw Terminal"
		x = x or 1
		y = y or 1

		local win, mode, cursorX, cursorY, current_colors, visible, canBlink, isClosed, changed = {}, 0, 1, 1, 0xF0, true, false, false, true
		local screen, colors, pixels, palette, fileHandles = {}, {}, {}, {}, {}
		local flags = {
			isVersion11 = false,
			filesystem = false,
			binaryChecksum = false
		}
		for i = 1, height do screen[i], colors[i] = (" "):rep(width), ("\xF0"):rep(width) end
		for i = 1, height*9 do pixels[i] = ("\x0F"):rep(width*6) end
		for i = 0, 15 do palette[i] = {(parent or term).getPaletteColor(2^i)} end
		for i = 16, 255 do palette[i] = {0, 0, 0} end

		local function makePacket(type, id, data)
			local payload = base64encode(string.char(type) .. string.char(id or 0) .. data)
			local d
			if #data > 65535 and flags.isVersion11 then d = "!CPD" .. string.format("%012X", #payload)
			else d = "!CPC" .. string.format("%04X", #payload) end
			d = d .. payload
			if flags.binaryChecksum then d = d .. ("%08X"):format(crc32(string.char(type) .. string.char(id or 0) .. data))
			else d = d .. ("%08X"):format(crc32(payload)) end
			return d .. "\n"
		end

		-- Term functions

		function win.write(text)
			text = tostring(text)
			expect(1, text, "string")
			if cursorY < 1 or cursorY > height then return
			elseif cursorX > width or cursorX + #text < 1 then
				cursorX = cursorX + #text
				return
			elseif cursorX < 1 then
				text = text:sub(-cursorX + 2)
				cursorX = 1
			end
			local ntext = #text
			if cursorX + #text > width then text = text:sub(1, width - cursorX + 1) end
			screen[cursorY] = screen[cursorY]:sub(1, cursorX - 1) .. text .. screen[cursorY]:sub(cursorX + #text)
			colors[cursorY] = colors[cursorY]:sub(1, cursorX - 1) .. string.char(current_colors):rep(#text) .. colors[cursorY]:sub(cursorX + #text)
			cursorX = cursorX + ntext
			changed = true
			win.redraw()
		end

		function win.blit(text, fg, bg)
			text = tostring(text)
			expect(1, text, "string")
			expect(2, fg, "string")
			expect(3, bg, "string")
			if #text ~= #fg or #fg ~= #bg then error("Arguments must be the same length", 2) end
			if cursorY < 1 or cursorY > height then return
			elseif cursorX > width or cursorX < 1 - #text then
				cursorX = cursorX + #text
				win.redraw()
				return
			elseif cursorX < 1 then
				text, fg, bg = text:sub(-cursorX + 2), fg:sub(-cursorX + 2), bg:sub(-cursorX + 2)
				cursorX = 1
				win.redraw()
			end
			local ntext = #text
			if cursorX + #text > width then text, fg, bg = text:sub(1, width - cursorX + 1), fg:sub(1, width - cursorX + 1), bg:sub(1, width - cursorX + 1) end
			local col = ""
			for i = 1, #text do col = col .. string.char((tonumber(bg:sub(i, i), 16) or 0) * 16 + (tonumber(fg:sub(i, i), 16) or 0)) end
			screen[cursorY] = screen[cursorY]:sub(1, cursorX - 1) .. text .. screen[cursorY]:sub(cursorX + #text)
			colors[cursorY] = colors[cursorY]:sub(1, cursorX - 1) .. col .. colors[cursorY]:sub(cursorX + #text)
			cursorX = cursorX + ntext
			changed = true
			win.redraw()
		end

		function win.clear()
			if mode == 0 then
				for i = 1, height do screen[i], colors[i] = (" "):rep(width), string.char(current_colors):rep(width) end
			else
				for i = 1, height*9 do pixels[i] = ("\x0F"):rep(width*6) end
			end
			changed = true
			win.redraw()
		end

		function win.clearLine()
			if cursorY >= 1 and cursorY <= height then
				screen[cursorY], colors[cursorY] = (" "):rep(width), string.char(current_colors):rep(width)
				changed = true
				win.redraw()
			end
		end

		function win.getCursorPos()
			return cursorX, cursorY
		end

		function win.setCursorPos(cx, cy)
			expect(1, cx, "number")
			expect(2, cy, "number")
			if cx == cursorX and cy == cursorY then return end
			cursorX, cursorY = cx, cy
			changed = true
			win.redraw()
		end

		function win.getCursorBlink()
			return canBlink
		end

		function win.setCursorBlink(b)
			expect(1, b, "boolean")
			canBlink = b
			if parent then parent.setCursorBlink(b) end
			win.redraw()
		end

		function win.isColor()
			if parent then return parent.isColor() end
			return true
		end

		function win.getSize(m)
			if (type(m) == "number" and m > 1) or (type(m) == "boolean" and m == true) then return width * 6, height * 9
			else return width, height end
		end

		function win.scroll(lines)
			expect(1, lines, "number")
			if math.abs(lines) >= width then
				for i = 1, height do screen[i], colors[i] = (" "):rep(width), string.char(current_colors):rep(width) end
			elseif lines > 0 then
				for i = lines + 1, height do screen[i - lines], colors[i - lines] = screen[i], colors[i] end
				for i = height - lines + 1, height do screen[i], colors[i] = (" "):rep(width), string.char(current_colors):rep(width) end
			elseif lines < 0 then
				for i = 1, height + lines do screen[i - lines], colors[i - lines] = screen[i], colors[i] end
				for i = 1, -lines do screen[i], colors[i] = (" "):rep(width), string.char(current_colors):rep(width) end
			else return end
			changed = true
			win.redraw()
		end

		function win.getTextColor()
			return 2^bit32.band(current_colors, 0x0F)
		end

		function win.setTextColor(color)
			expect(1, color, "number")
			current_colors = bit32.band(current_colors, 0xF0) + bit32.band(math.floor(math.log(color, 2)), 0x0F)
		end

		function win.getBackgroundColor()
			return 2^bit32.rshift(current_colors, 4)
		end

		function win.setBackgroundColor(color)
			expect(1, color, "number")
			current_colors = bit32.band(current_colors, 0x0F) + bit32.band(math.floor(math.log(color, 2)), 0x0F) * 16
		end

		function win.getPaletteColor(color)
			expect(1, color, "number")
			if mode == 2 then if color < 0 or color > 255 then error("bad argument #1 (value out of range)", 2) end
			else color = bit32.band(math.floor(math.log(color, 2)), 0x0F) end
			return table.unpack(palette[color])
		end

		function win.setPaletteColor(color, r, g, b)
			expect(1, color, "number")
			expect(2, r, "number")
			expect(3, g, "number")
			expect(4, b, "number")
			if r < 0 or r > 1 then error("bad argument #2 (value out of range)", 2) end
			if g < 0 or g > 1 then error("bad argument #3 (value out of range)", 2) end
			if b < 0 or b > 1 then error("bad argument #4 (value out of range)", 2) end
			if mode == 2 then if color < 0 or color > 255 then error("bad argument #1 (value out of range)", 2) end
			else color = bit32.band(math.floor(math.log(color, 2)), 0x0F) end
			palette[color] = {r, g, b}
			changed = true
			win.redraw()
		end

		-- Graphics functions

		function win.getGraphicsMode()
			if mode == 0 then return false
			else return mode end
		end

		function win.setGraphicsMode(m)
			expect(1, m, "boolean", "number")
			local om = mode
			if m == false then mode = 0
			elseif m == true then mode = 1
			elseif m >= 0 and m <= 2 then mode = math.floor(m)
			else error("bad argument #1 (invalid mode)", 2) end
			if mode ~= om then changed = true win.redraw() end
		end

		function win.getPixel(px, py)
			expect(1, px, "number")
			expect(2, py, "number")
			if px < 0 or px >= width or py < 0 or py >= height then return nil end
			local c = pixels[py + 1]:byte(px + 1, px + 1)
			return mode == 2 and c or 2^c
		end

		function win.setPixel(px, py, color)
			expect(1, px, "number")
			expect(2, py, "number")
			expect(3, color, "number")
			if mode == 2 then if color < 0 or color > 255 then error("bad argument #3 (value out of range)", 2) end
			else color = bit32.band(math.floor(math.log(color, 2)), 0x0F) end
			pixels[py + 1] = pixels[py + 1]:sub(1, px) .. string.char(color) .. pixels[py + 1]:sub(px + 2)
			changed = true
			win.redraw()
		end

		function win.drawPixels(px, py, pix, pw, ph)
			expect(1, px, "number")
			expect(2, py, "number")
			expect(3, pix, "table", "number")
			expect(4, pw, "number", type(pix) ~= "number" and "nil" or nil)
			expect(5, ph, "number", type(pix) ~= "number" and "nil" or nil)
			if type(pix) == "number" then
				if mode == 2 then if pix < 0 or pix > 255 then error("bad argument #3 (value out of range)", 2) end
				else pix = bit32.band(math.floor(math.log(pix, 2)), 0x0F) end
				for cy = py + 1, py + ph do pixels[cy] = pixels[cy]:sub(1, px) .. string.char(pix):rep(pw) .. pixels[cy]:sub(px + pw + 1) end
			else
				for cy = py + 1, py + (ph or #pix) do
					local row = pix[cy - py]
					if type(row) == "string" then
						pixels[cy] = pixels[cy]:sub(1, px) .. row:sub(1, pw or -1) .. pixels[cy]:sub(px + (pw or #row) + 1)
					elseif type(row) == "table" then
						local str = ""
						for cx = 1, pw or #row do str = str .. string.char(row[cx] or pixels[cy]:byte(px + cx)) end
						pixels[cy] = pixels[cy]:sub(1, px) .. str .. pixels[cy]:sub(px + #str + 1)
					end
				end
			end
			changed = true
			win.redraw()
		end

		function win.getPixels(px, py, pw, ph, str)
			expect(1, px, "number")
			expect(2, py, "number")
			expect(3, pw, "number")
			expect(4, ph, "number")
			expect(5, str, "boolean", "nil")
			local retval = {}
			for cy = py + 1, py + ph do
				if str then retval[cy - py] = pixels[cy]:sub(px + 1, px + pw) else
					retval[cy - py] = {pixels[cy]:byte(px + 1, px + pw)}
					if mode < 2 then for i = 1, pw do retval[cy - py][i] = 2^retval[cy - py][i] end end
				end
			end
			return retval
		end

		win.isColour = win.isColor
		win.getTextColour = win.getTextColor
		win.setTextColour = win.setTextColor
		win.getBackgroundColour = win.getBackgroundColor
		win.setBackgroundColour = win.setBackgroundColor
		win.getPaletteColour = win.getPaletteColor
		win.setPaletteColour = win.setPaletteColor

		-- Window functions

		function win.getLine(cy)
			if cy < 1 or cy > height then return nil end
			local fg, bg = "", ""
			for c in colors[cy]:gmatch "." do
				fg, bg = fg .. ("%x"):format(bit32.band(c:byte(), 0x0F)), bg .. ("%x"):format(bit32.rshift(c:byte(), 4))
			end
			return screen[cy], fg, bg
		end

		function win.isVisible()
			return visible
		end

		function win.setVisible(v)
			expect(1, v, "boolean")
			visible = v
			win.redraw()
		end

		function win.redraw()
			if visible and changed then
				-- Draw to parent screen
				if parent then
					-- This is NOT efficient, but it's not really supposed to be anyway.
					if parent.getGraphicsMode and (parent.getGraphicsMode() or 0) ~= mode then parent.setGraphicsMode(mode) end
					if mode == 0 then
						local b = parent.getCursorBlink()
						parent.setCursorBlink(false)
						for cy = 1, height do
							parent.setCursorPos(x, y + cy - 1)
							parent.blit(win.getLine(cy))
						end
						parent.setCursorBlink(b)
						win.restoreCursor()
					elseif parent.drawPixels then
						parent.drawPixels((x - 1) * 6, (y - 1) * 9, pixels, width, height)
					end
				end
				-- Draw to raw target
				if not isClosed then
					local rleText = ""
					if mode == 0 then
						local c, n = screen[1]:sub(1, 1), 0
						for cy = 1, height do
							for ch in screen[cy]:gmatch "." do
								if ch ~= c or n == 255 then
									rleText = rleText .. c .. string.char(n)
									c, n = ch, 0
								end
								n=n+1
							end
						end
						if n > 0 then rleText = rleText .. c .. string.char(n) end
						c, n = colors[1]:sub(1, 1), 0
						for cy = 1, height do
							for ch in colors[cy]:gmatch "." do
								if ch ~= c or n == 255 then
									rleText = rleText .. c .. string.char(n)
									c, n = ch, 0
								end
								n=n+1
							end
						end
						if n > 0 then rleText = rleText .. c .. string.char(n) end
					else
						local c, n = pixels[1]:sub(1, 1), 0
						for cy = 1, height * 9 do
							for ch in pixels[cy]:gmatch "." do
								if ch ~= c or n == 255 then
									rleText = rleText .. c .. string.char(n)
									c, n = ch, 0
								end
								n=n+1
							end
						end
					end
					for i = 0, (mode == 2 and 255 or 15) do rleText = rleText .. string.char(palette[i][1] * 255) .. string.char(palette[i][2] * 255) .. string.char(palette[i][3] * 255) end
					delegate:send(makePacket(0, id, string.pack("<BBHHHHBxxx", mode, canBlink and 1 or 0, width, height, math.min(math.max(cursorX - 1, 0), 0xFFFFFFFF), math.min(math.max(cursorY - 1, 0), 0xFFFFFFFF), parent and (parent.isColor() and 0 or 1) or 0) .. rleText))
				end
				changed = false
			end
		end

		function win.restoreCursor()
			if parent then parent.setCursorPos(x + cursorX - 1, y + cursorY - 1) end
		end

		function win.getPosition()
			return x, y
		end

		function win.reposition(nx, ny, nwidth, nheight, nparent)
			expect(1, nx, "number", "nil")
			expect(2, ny, "number", "nil")
			expect(3, nwidth, "number", "nil")
			expect(4, nheight, "number", "nil")
			expect(5, nparent, "table", "nil")
			x, y, parent = nx or x, ny or y, nparent or parent
			local resized = (nwidth and nwidth ~= width) or (nheight and nheight ~= height)
			if nwidth then
				if nwidth < width then
					for cy = 1, height do
						screen[cy], colors[cy] = screen[cy]:sub(1, nwidth), colors[cy]:sub(1, nwidth)
						for i = 1, 9 do pixels[(cy - 1)*9 + i] = pixels[(cy - 1)*9 + i]:sub(1, nwidth * 6) end
					end
				elseif nwidth > width then
					for cy = 1, height do
						screen[cy], colors[cy] = screen[cy] .. (" "):rep(nwidth - width), colors[cy] .. string.char(current_colors):rep(nwidth - width)
						for i = 1, 9 do pixels[(cy - 1)*9 + i] = pixels[(cy - 1)*9 + i] .. ("\x0F"):rep((nwidth - width) * 6) end
					end
				end
				width = nwidth
			end
			if nheight then
				if nheight < height then
					for cy = nheight + 1, height do
						screen[cy], colors[cy] = nil
						for i = 1, 9 do pixels[(cy - 1)*9 + i] = nil end
					end
				elseif nheight > height then
					for cy = height + 1, nheight do
						screen[cy], colors[cy] = (" "):rep(width), string.char(current_colors):rep(width)
						for i = 1, 9 do pixels[(cy - 1)*9 + i] = ("\x0F"):rep(width * 6) end
					end
				end
				height = nheight
			end
			if resized and not isClosed then delegate:send(makePacket(4, id, string.pack("<BBHHz", 0, os.computerID(), width, height, title))) end
			changed = true
			win.redraw()
		end

		-- Raw functions

		--- A wrapper for os.pullEvent() that also listens for raw events, and returns
		-- them if found.
		-- @param filter A filter for the event.
		-- @param ignoreLocalEvents Set this to a truthy value to ignore receiving
		-- input events from the local computer, making the terminal otherwise
		-- isolated from the rest of the system.
		-- @return The event name and arguments.
		function win.pullEvent(filter, ignoreLocalEvents)
			expect(1, filter, "string", "nil")
			local ev
			parallel.waitForAny(function()
				if isClosed then while true do coroutine.yield() end end
				while true do
					local msg = delegate:receive()
					if not msg then
						isClosed = true
						while true do coroutine.yield() end
					end
					if msg:sub(1, 3) == "!CP" then
						local off = 8
						if msg:sub(4, 4) == 'D' then off = 16 end
						local size = tonumber(msg:sub(5, off), 16)
						local payload = msg:sub(off + 1, off + size)
						local expected = tonumber(msg:sub(off + size + 1, off + size + 8), 16)
						local data = base64decode(payload)
						if crc32(flags.binaryChecksum and data or payload) == expected then
							local typ, wid = data:byte(1, 2)
							if wid == id then
								if typ == 1 then
									local ch, flags = data:byte(3, 4)
									if bit32.btest(flags, 8) then ev = {"char", string.char(ch)}
									elseif bit32.btest(flags, 1) then ev = {"key", keymap[ch], bit32.btest(flags, 2)}
									else ev = {"key_up", keymap[ch]} end
									if not filter or ev[1] == filter then return else ev = nil end
								elseif typ == 2 then
									local evt, button, mx, my = string.unpack("<BBII", data, 3)
									ev = {mouse_events[evt], evt == 2 and button * 2 - 1 or button, mx, my}
									if not filter or ev[1] == filter then return else ev = nil end
								elseif typ == 3 then
									local nparam, name = string.unpack("<Bz", data, 3)
									ev = {name}
									local pos = #name + 5
									for i = 2, nparam + 1 do ev[i], pos = decodeIBT(data, pos) end
									if not filter or ev[1] == filter then return else ev = nil end
								elseif typ == 4 then
									local flags, _, w, h = string.unpack("<BBHH", data, 3)
									if flags == 0 then
										if w ~= 0 and h ~= 0 then
											win.reposition(nil, nil, w, h, nil)
											ev = {"term_resize"}
										end
									elseif flags == 1 or flags == 2 then
										win.close()
										ev = {"win_close"}
									end
									if not filter or ev[1] == filter then return else ev = nil end
								elseif typ == 7 and flags.filesystem then
									local reqtype, reqid, path, path2 = string.unpack("<BBz", data, 3)
									if reqtype == 12 or reqtype == 13 then path2 = string.unpack("<z", data, path2) else path2 = nil end
									if bit32.band(reqtype, 0xF0) == 0 then
										local ok, val = pcall(fsFunctions[reqtype], path, path2)
										if ok then
											if type(val) == "boolean" then delegate:send(makePacket(8, id, string.pack("<BBB", reqtype, reqid, val and 1 or 0)))
											elseif type(val) == "number" then delegate:send(makePacket(8, id, string.pack("<BBI4", reqtype, reqid, val)))
											elseif type(val) == "string" then delegate:send(makePacket(8, id, string.pack("<BBz", reqtype, reqid, val)))
											elseif reqtype == 8 then
												if val then delegate:send(makePacket(8, id, string.pack("<BBI4I8I8BBBB", reqtype, reqid, val.size, val.created, val.modified, val.isDir and 1 or 0, val.isReadOnly and 1 or 0, 0, 0)))
												else delegate:send(makePacket(8, id, string.pack("<BBI4I8I8BBBB", reqtype, reqid, 0, 0, 0, 0, 0, 1, 0))) end
											elseif type(val) == "table" then
												local list = ""
												for i = 1, #val do list = list .. val[i] .. "\0" end
												delegate:send(makePacket(8, id, string.pack("<BBI4", reqtype, reqid, #val) .. list))
											else delegate:send(makePacket(8, id, string.pack("<BBB", reqtype, reqid, 0))) end
										else
											if reqtype == 0 or reqtype == 1 or reqtype == 2 then delegate:send(makePacket(8, id, string.pack("<BBB", reqtype, reqid, 2)))
											elseif reqtype == 3 or reqtype == 5 or reqtype == 6 then delegate:send(makePacket(8, id, string.pack("<BBI4", reqtype, reqid, 0xFFFFFFFF)))
											elseif reqtype == 4 or reqtype == 7 or reqtype == 9 then delegate:send(makePacket(8, id, string.pack("<BBz", reqtype, reqid, "")))
											elseif reqtype == 8 then delegate:send(makePacket(8, id, string.pack("<BBI4I8I8BBBB", reqtype, reqid, 0, 0, 0, 0, 0, 2, 0)))
											else delegate:send(makePacket(8, id, string.pack("<BBz", reqtype, reqid, val))) end
										end
									elseif bit32.band(reqtype, 0xF0) == 0x10 then
										local file, err = fs.open(path, openModes[bit32.band(reqtype, 7)])
										if file then
											if bit32.btest(reqtype, 1) then fileHandles[reqid] = file else
												delegate:send(makePacket(9, id, string.pack("<BBs4", 0, reqid, file.readAll())))
												file.close()
											end
										else
											if bit32.btest(reqtype, 1) then delegate:send(makePacket(8, id, string.pack("<BBz", reqtype, reqid, err)))
											else delegate:send(makePacket(9, id, string.pack("<BBs4", 1, reqid, err))) end
										end
									end
								elseif typ == 9 and flags.filesystem then
									local _, reqid, size = string.unpack("<BBI4", data, 3)
									local str = data:sub(9, size + 8)
									if fileHandles[reqid] ~= nil then
										fileHandles[reqid].write(str)
										fileHandles[reqid].close()
										fileHandles[reqid] = nil
										delegate:send(makePacket(8, id, string.pack("<BBB", 17, reqid, 0)))
									else delegate:send(makePacket(8, id, string.pack("<BBz", 17, reqid, "Unknown request ID"))) end
								end
							end
							if typ == 6 then
								flags.isVersion11 = true
								local f = string.unpack("<H", data, 3)
								if wid == id then delegate:send(makePacket(6, wid, string.pack("<H", 1 + (blockFSAccess and 0 or 2)))) end
								if bit32.btest(f, 0x01) then flags.binaryChecksum = true end
								if bit32.btest(f, 0x02) and not blockFSAccess then flags.filesystem = true end
								if bit32.btest(f, 0x04) then delegate:send(makePacket(4, id, string.pack("<BBHHz", 0, os.computerID(), width, height, title))) changed = true end
							end
						end
					end
				end
			end, function()
				repeat
					ev = nil
					ev = table.pack(os.pullEventRaw(filter))
				until not ignoreLocalEvents or not localEvents[ev[1]]
			end)
			return table.unpack(ev, 1, ev.n or #ev)
		end

		--- Sets the window's title and sends a message to the client.
		-- @param t The new title of the window.
		function win.setTitle(t)
			expect(1, title, "string")
			title = t
			if isClosed then return end
			delegate:send(makePacket(4, id, string.pack("<BBHHz", 0, os.computerID(), width, height, title)))
		end

		--- Sends a message to the client.
		-- @param type Either "error", "warning", or "info" to specify an icon to show.
		-- @param title The title of the message.
		-- @param message The message to display.
		function win.sendMessage(type, title, message)
			expect(1, title, "string")
			expect(2, message, "string")
			expect(3, type, "string", "nil")
			if isClosed then return end
			local flags = 0
			if type == "error" then type = 0x10
			elseif type == "warning" then type = 0x20
			elseif type == "info" then type = 0x40
			elseif type then error("bad argument #3 (invalid type '" .. type .. "')", 2) end
			delegate:send(makePacket(5, id, string.pack("<Izz", flags, title, message)))
		end

		--- Closes the window connection. Any changes made to the screen will still
		-- show on the parent window if defined.
		function win.close()
			if isClosed then return end
			delegate:send(makePacket(4, id, string.pack("<BBHHz", 1, 0, 0, 0, "")))
			if delegate.close then delegate:close() end
			isClosed = true
		end

		delegate:send(makePacket(4, id, string.pack("<BBHHz", 0, os.computerID() % 256, width, height, title)))

		return win
	end

	--- Creates a new client handle that listens for the specified window ID, and
	-- renders to a window.
	-- @param delegate The delegate object. This must have two methods named
	-- `:send(data)` and `:receive()`, and may additionally have a `:close()` method
	-- that's called when the server is closed. It may also have `:setTitle(title)`
	-- to set the title of the window, `:showMessage(type, title, message)` to show
	-- a message on the screen (type may be `error`, `warning`, or `info`), and
	-- `:windowNotification(id, width, height, title)` which is called when an
	-- unknown window ID gets a window update (this may be used to discover new
	-- window alerts from the server). Every method is called with the `:` operator,
	-- meaning its first argument is the delegate object itself.
	-- @param id The ID of the window to listen for. (If in doubt, use 0.)
	-- @param window The window to render to.
	-- @return The new client handle.
	function rawterm.client(delegate, id, window)
		expect(1, delegate, "table")
		expect(2, id, "number")
		expect(3, window, "table", "nil")
		expect.field(delegate, "send", "function")
		expect.field(delegate, "receive", "function")
		expect.field(delegate, "close", "function", "nil")
		expect.field(delegate, "setTitle", "function", "nil")
		expect.field(delegate, "showMessage", "function", "nil")
		expect.field(delegate, "windowNotification", "function", "nil")

		local handle = {}
		local flags = {
			isVersion11 = false,
			binaryChecksum = false,
			filesystem = false
		}
		local isClosed = false
		local nextFSID = 0

		local function makePacket(type, id, data)
			local payload = base64encode(string.char(type) .. string.char(id or 0) .. data)
			local d
			if #data > 65535 and flags.isVersion11 then d = "!CPD" .. string.format("%012X", #payload)
			else d = "!CPC" .. string.format("%04X", #payload) end
			d = d .. payload
			if flags.binaryChecksum then d = d .. ("%08X"):format(crc32(string.char(type) .. string.char(id or 0) .. data))
			else d = d .. ("%08X"):format(crc32(payload)) end
			return d .. "\n"
		end

		local function makeFSFunction(fid, type, p2)
			local f = function(path, path2)
				expect(1, path, "string")
				if p2 then expect(2, path, "string") end
				local n = nextFSID
				delegate:send(makePacket(7, id, string.pack(p2 and "<BBzz" or "<BBz", fid, n, path, path2)))
				nextFSID = (nextFSID + 1) % 256
				local data
				while not data or data:byte(4) ~= n do data = handle.update(delegate:receive()) end
				if type == "nil" then
					local v = string.unpack("z", data, 5)
					if v ~= "" then error(v, 2)
					else return end
				elseif type == "boolean" then
					local v = data:byte(5)
					if v == 2 then error("Failure", 2)
					else return v ~= 0 end
				elseif type == "number" then
					local v = string.unpack("<I4", data, 5)
					if v == 0xFFFFFFFF then error("Failure", 2)
					else return v end
				elseif type == "string" then
					local v = string.unpack("<I4", data, 5)
					if v == "" then error("Failure", 2)
					else return v end
				elseif type == "table" then
					local size = string.unpack("<I4", data, 5)
					if size == 0xFFFFFFFF then error("Failure", 2) end
					local retval, pos = {}, 9
					for i = 1, size do retval[i], pos = string.unpack("z", data, pos) end
					return retval
				elseif type == "attributes" then
					local attr, err = {}
					attr.size, attr.created, attr.modified, attr.isDir, attr.isReadOnly, err = string.unpack("<I4I8I8BBB", data, 5)
					if err == 1 then return nil
					elseif err == 2 then error("Failure", 2)
					else return attr end
				end
			end
			if p2 then return f else return function(path) return f(path) end end
		end

		local fsHandle = {
			exists = makeFSFunction(0, "boolean"),
			isDir = makeFSFunction(1, "boolean"),
			isReadOnly = makeFSFunction(2, "boolean"),
			getSize = makeFSFunction(3, "number"),
			getDrive = makeFSFunction(4, "string"),
			getCapacity = makeFSFunction(5, "number"),
			getFreeSpace = makeFSFunction(6, "number"),
			list = makeFSFunction(7, "table"),
			attributes = makeFSFunction(8, "attributes"),
			find = makeFSFunction(9, "table"),
			makeDir = makeFSFunction(10, "nil"),
			delete = makeFSFunction(11, "nil"),
			copy = makeFSFunction(12, "nil", true),
			move = makeFSFunction(13, "nil", true),
			open = function(path, mode)
				expect(1, path, "string")
				expect(2, mode, "string")
				local m
				for i = 0, 7 do if openModes[i] == mode then m = i break end end
				if not m then error("Invalid mode", 2) end
				if bit32.btest(m, 1) then
					local buf, closed = "", false
					return {
						write = function(d)
							if closed then error("attempt to use closed file", 2) end
							if bit32.btest(m, 4) and type(d) == "number" then buf = buf .. string.char(d)
							else buf = buf .. tostring(d) end
						end,
						writeLine = function(d)
							if closed then error("attempt to use closed file", 2) end
							buf = buf .. tostring(d) .. "\n"
						end,
						flush = function()
							if closed then error("attempt to use closed file", 2) end
							local n = nextFSID
							delegate:send(makePacket(7, id, string.pack("<BBz", 16 + m, n, path)))
							delegate:send(makePacket(9, id, string.pack("<BBs4", 0, n, buf)))
							nextFSID = (nextFSID + 1) % 256
							buf, m = "", bit32.bor(m, 2)
							local d
							while not d or d:byte(4) ~= n do d = handle.update(delegate:receive()) end
							local v = string.unpack("z", d, 5)
							if v ~= "" then error(v, 2) end
						end,
						close = function()
							if closed then error("attempt to use closed file", 2) end
							closed = true
							local n = nextFSID
							delegate:send(makePacket(7, id, string.pack("<BBz", 16 + m, n, path)))
							delegate:send(makePacket(9, id, string.pack("<BBs4", 0, n, buf)))
							nextFSID = (nextFSID + 1) % 256
							buf, m = "", bit32.bor(m, 2)
							local d
							while not d or d:byte(4) ~= n do d = handle.update(delegate:receive()) end
							local v = string.unpack("z", d, 5)
							if v ~= "" then error(v, 2) end
						end
					}
				else
					local n = nextFSID
					delegate:send(makePacket(7, id, string.pack("<BBz", 16 + m, n, path)))
					nextFSID = (nextFSID + 1) % 256
					local d
					while not d or d:byte(4) ~= n do d = handle.update(delegate:receive()) end
					local size = string.unpack("<I4", d, 5)
					local data = d:sub(9, 8 + size)
					if d:byte(3) ~= 0 then return nil, data end
					local pos, closed = 1, false
					return {
						read = function(n)
							expect(1, n, "number", "nil")
							if closed then error("attempt to use closed file", 2) end
							if pos >= #data then return nil end
							if n == nil then
								if bit32.btest(m, 4) then
									pos = pos + 1
									return data:byte(pos - 1)
								else n = 1 end
							end
							pos = pos + n
							return data:sub(pos - n, pos - 1)
						end,
						readLine = function(strip)
							if closed then error("attempt to use closed file", 2) end
							if pos >= #data then return nil end
							local oldpos, line = pos
							line, pos = data:match("([^\n]" .. (strip and "+)\n" or "*\n)") .. "()", pos)
							if not pos then
								line = data:sub(pos)
								pos = #data
							end
							return line
						end,
						readAll = function()
							if closed then error("attempt to use closed file", 2) end
							if pos >= #data then return nil end
							local d = data:sub(pos)
							pos = #data
							return d
						end,
						close = function()
							if closed then error("attempt to use closed file", 2) end
							closed = true
						end,
						seek = bit32.btest(m, 4) and function(whence, offset)
							expect(1, whence, "string", "nil")
							expect(2, offset, "number", "nil")
							whence = whence or "cur"
							offset = offset or 0
							if closed then error("attempt to use closed file", 2) end
							if whence == "set" then pos = offset
							elseif whence == "cur" then pos = pos + offset
							elseif whence == "end" then pos = #data - offset
							else error("Invalid whence", 2) end
							return pos
						end or nil
					}
				end
			end
		}

		--- Updates the window with the raw message provided.
		-- @param message A raw message to parse.
		function handle.update(message)
			expect(1, message, "string")
			if message:sub(1, 3) == "!CP" then
				local off = 8
				if message:sub(4, 4) == 'D' then off = 16 end
				local size = tonumber(message:sub(5, off), 16)
				local payload = message:sub(off + 1, off + size)
				local expected = tonumber(message:sub(off + size + 1, off + size + 8), 16)
				local data = base64decode(payload)
				if crc32(flags.binaryChecksum and data or payload) == expected then
					local typ, wid = data:byte(1, 2)
					if wid == id then
						if typ == 0 and window then
							local mode, blink, width, height, cursorX, cursorY, grayscale = string.unpack("<BBHHHHB", data, 3)
							local c, n, pos = string.unpack("c1B", data, 17)
							window.setCursorBlink(false)
							if window.setVisible then window.setVisible(false) end
							if window.getGraphicsMode and window.getGraphicsMode() ~= mode then window.setGraphicsMode(mode) end
							window.clear()
							-- These RLE routines could probably be optimized with string.rep.
							if mode == 0 then
								local text = {}
								for y = 1, height do
									text[y] = ""
									for x = 1, width do
										text[y] = text[y] .. c
										n = n - 1
										if n == 0 then c, n, pos = string.unpack("c1B", data, pos) end
									end
								end
								c = c:byte()
								for y = 1, height do
									local fg, bg = "", ""
									for x = 1, width do
										fg, bg = fg .. ("%x"):format(bit32.band(c, 0x0F)), bg .. ("%x"):format(bit32.rshift(c, 4))
										n = n - 1
										if n == 0 then c, n, pos = string.unpack("BB", data, pos) end
									end
									window.setCursorPos(1, y)
									window.blit(text[y], fg, bg)
								end
							else
								local pixels = {}
								for y = 1, height * 9 do
									pixels[y] = ""
									for x = 1, width * 6 do
										pixels[y] = pixels[y] .. c
										n = n - 1
										if n == 0 then c, n, pos = string.unpack("c1B", data, pos) end
									end
								end
								if window.drawPixels then window.drawPixels(0, 0, pixels) end
							end
							pos = pos - 2
							local r, g, b
							if mode ~= 2 then
								for i = 0, 15 do
									r, g, b, pos = string.unpack("BBB", data, pos)
									window.setPaletteColor(2^i, r / 255, g / 255, b / 255)
								end
							else
								for i = 0, 255 do
									r, g, b, pos = string.unpack("BBB", data, pos)
									window.setPaletteColor(i, r / 255, g / 255, b / 255)
								end
							end
							window.setCursorBlink(blink ~= 0)
							window.setCursorPos(cursorX + 1, cursorY + 1)
							if window.setVisible then window.setVisible(true) end
						elseif typ == 4 then
							local flags, _, w, h, title = string.unpack("<BBHHz", data, 3)
							if flags == 0 then
								if w ~= 0 and h ~= 0 and window and window.reposition then
									local x, y = window.getPosition()
									window.reposition(x, y, w, h)
								end
								if delegate.setTitle then delegate:setTitle(title) end
							elseif flags == 1 or flags == 2 then
								if not isClosed then
									delegate:send("\n")
									if delegate.close then delegate:close() end
									isClosed = true
								end
							end
						elseif typ == 5 then
							local flags, title, msg = string.unpack("<Izz", data, 3)
							local mtyp
							if bit32.btest(flags, 0x10) then mtyp = "error"
							elseif bit32.btest(flags, 0x20) then mtyp = "warning"
							elseif bit32.btest(flags, 0x40) then mtyp = "info" end
							if delegate.showMessage then delegate:showMessage(mtyp, title, msg) end
						elseif typ == 8 or typ == 9 then
							return data
						end
					elseif typ == 4 then
						local flags, _, w, h, title = string.unpack("<BBHHz", data, 3)
						if flags == 0 and delegate.windowNotification then delegate:windowNotification(wid, w, h, title) end
					end
					if typ == 6 then
						flags.isVersion11 = true
						local f = string.unpack("<H", data, 3)
						if bit32.btest(f, 0x01) then flags.binaryChecksum = true end
						if bit32.btest(f, 0x02) then flags.filesystem = true handle.fs = fsHandle end
					end
				end
			end
		end

		--- Sends an event to the server. This functions like os.queueEvent.
		-- @param ev The name of the event to send.
		-- @param ... The event parameters. This must not contain any functions,
		-- coroutines, or userdata.
		function handle.queueEvent(ev, ...)
			expect(1, ev, "string")
			if isClosed then return end
			local params = table.pack(...)
			if ev == "key" then delegate:send(makePacket(1, id, string.pack("<BB", keymap_rev[params[1]], bit32.bor(1, params[2] and 2 or 0))))
			elseif ev == "key_up" then delegate:send(makePacket(1, id, string.pack("<BB", keymap_rev[params[1]], 0)))
			elseif ev == "char" then delegate:send(makePacket(1, id, string.pack("<BB", params[1]:byte(), 9)))
			elseif ev == "mouse_click" then delegate:send(makePacket(2, id, string.pack("<BBII", 0, params[1], params[2], params[3])))
			elseif ev == "mouse_up" then delegate:send(makePacket(2, id, string.pack("<BBII", 1, params[1], params[2], params[3])))
			elseif ev == "mouse_scroll" then delegate:send(makePacket(2, id, string.pack("<BBII", 2, params[1] < 0 and 0 or 1, params[2], params[3])))
			elseif ev == "mouse_drag" then delegate:send(makePacket(2, id, string.pack("<BBII", 3, params[1], params[2], params[3])))
			elseif ev == "term_resize" then
				if window then
					local w, h = window.getSize()
					delegate:send(makePacket(4, id, string.pack("<BBHHz", 0, 0, w, h, "")))
				end
			else
				local s = ""
				for i = 1, params.n do s = s .. encodeIBT(params[i]) end
				delegate:send(makePacket(3, id, string.pack("<Bz", params.n, ev) .. s))
			end
		end

		--- Sends a resize request to the server and resizes the window.
		-- @param w The width of the window.
		-- @param h The height of the window.
		function handle.resize(w, h)
			expect(1, w, "number")
			expect(2, h, "number")
			if window and window.reposition then
				local x, y = window.getPosition()
				window.reposition(x, y, w, h)
			end
			if isClosed then return end
			delegate:send(makePacket(4, id, string.pack("<BBHHz", 0, 0, w, h, "")))
		end

		--- Closes the window connection.
		function handle.close()
			if isClosed then return end
			delegate:send(makePacket(4, id, string.pack("<BBHHz", 1, 0, 0, 0, "")))
			delegate:send("\n")
			if delegate.close then delegate:close() end
			isClosed = true
		end

		--- A simple function that sends input events to the server, as well as
		-- updating the window with messages from the server.
		function handle.run()
			parallel.waitForAny(function() while not isClosed do
				local msg = delegate:receive()
				if msg == nil then isClosed = true
				else handle.update(msg) end
			end end,
			function() while true do
				local ev = table.pack(os.pullEventRaw())
				if ev[1] == "key" or ev[1] == "key_up" or ev[1] == "char" or
					ev[1] == "mouse_click" or ev[1] == "mouse_up" or ev[1] == "mouse_scroll" or ev[1] == "mouse_drag" or
					ev[1] == "paste" or ev[1] == "terminate" or ev[1] == "term_resize" then
					handle.queueEvent(table.unpack(ev, 1, ev.n))
				end
			end end)
		end

		-- This field is normally left empty, but if the remote server supports
		-- filesystem transfers it becomes a table with various functions for
		-- accessing the remote filesystem. The functions are a subset of the FS API
		-- as implemented by the raw mode protocol.
		handle.fs = nil

		delegate:send(makePacket(6, id, string.pack("<H", 7)))

		return handle
	end

	local wsDelegate, rednetDelegate = {}, {}
	wsDelegate.__index, rednetDelegate.__index = wsDelegate, rednetDelegate
	function wsDelegate:send(data) return self._ws.send(data) end
	function wsDelegate:receive(timeout) return self._ws.receive(timeout) end
	function wsDelegate:close() return self._ws.close() end
	function rednetDelegate:send(data) return rednet.send(self._id, data, self._protocol) end
	function rednetDelegate:receive(timeout)
		local tm = os.startTimer(timeout)
		repeat
			local ev = {os.pullEvent()}
			if ev[1] == "rednet_message" and ev[2] == self._id and (not self._protocol or ev[4] == self._protocol) then
				os.cancelTimer(tm)
				return ev[3]
			end
		until ev[1] == "timer" and ev[2] == tm
	end

	--- Creates a basic delegate object that connects to a WebSocket server.
	-- @param url The URL of the WebSocket to connect to.
	-- @return The new delegate, or nil on error.
	-- @return If error, the error message.
	function rawterm.wsDelegate(url)
		expect(1, url, "string")
		local ws, err = http.websocket(url)
		if not ws then return nil, err end
		return setmetatable({_ws = ws}, wsDelegate)
	end

	--- Creates a basic delegate object that communicates over Rednet.
	-- @param id The ID of the computer to connect to.
	-- @param protocol The protocol to communicate over. Defaults to "ccpc_raw_terminal".
	function rawterm.rednetDelegate(id, protocol)
		expect(1, id, "number")
		expect(2, protocol, "string", "nil")
		return setmetatable({_id = id, _protocol = protocol or "ccpc_raw_terminal"}, rednetDelegate)
	end

	return rawterm
end

function runECC()
	-- Elliptic Curve Cryptography in Computercraft

	---- Update (Jun  4 2021)
	-- Fix compatibility with CraftOS-PC
	---- Update (Jul 30 2020)
	-- Make randomModQ and use it instead of hashing from random.random()
	---- Update (Feb 10 2020)
	-- Make a more robust encoding/decoding implementation
	---- Update (Dec 30 2019)
	-- Fix rng not accumulating entropy from loop
	-- (older versions should be fine from other sources + stored in disk)
	---- Update (Dec 28 2019)
	-- Slightly better integer multiplication and squaring
	-- Fix global variable declarations in modQ division and verify() (no security concerns)
	-- Small tweaks from SquidDev's illuaminate (https://github.com/SquidDev/illuaminate/)

	local byteTableMT = {
		__tostring = function(a) return string.char(unpack(a)) end,
		__index = {
			toHex = function(self) return ("%02x"):rep(#self):format(unpack(self)) end,
			isEqual = function(self, t)
				if type(t) ~= "table" then return false end
				if #self ~= #t then return false end
				local ret = 0
				for i = 1, #self do
					ret = bit32.bor(ret, bit32.bxor(self[i], t[i]))
				end
				return ret == 0
			end
		}
	}

	-- SHA-256, HMAC and PBKDF2 functions in ComputerCraft
	-- By Anavrins
	-- For help and details, you can PM me on the CC forums
	-- You may use this code in your projects without asking me, as long as credit is given and this header is kept intact
	-- http://www.computercraft.info/forums2/index.php?/user/12870-anavrins
	-- http://pastebin.com/6UV4qfNF
	-- Last update: October 10, 2017
	local sha256 = (function()
		local mod32 = 2^32
		local band    = bit32 and bit32.band or bit.band
		local bnot    = bit32 and bit32.bnot or bit.bnot
		local bxor    = bit32 and bit32.bxor or bit.bxor
		local blshift = bit32 and bit32.lshift or bit.blshift
		local upack   = unpack

		local function rrotate(n, b)
			local s = n/(2^b)
			local f = s%1
			return (s-f) + f*mod32
		end
		local function brshift(int, by) -- Thanks bit32 for bad rshift
			local s = int / (2^by)
			return s - s%1
		end

		local H = {
			0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
			0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
		}

		local K = {
			0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
			0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
			0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
			0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
			0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
			0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
			0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
			0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
		}

		local function counter(incr)
			local t1, t2 = 0, 0
			if 0xFFFFFFFF - t1 < incr then
				t2 = t2 + 1
				t1 = incr - (0xFFFFFFFF - t1) - 1       
			else t1 = t1 + incr
			end
			return t2, t1
		end

		local function BE_toInt(bs, i)
			return blshift((bs[i] or 0), 24) + blshift((bs[i+1] or 0), 16) + blshift((bs[i+2] or 0), 8) + (bs[i+3] or 0)
		end

		local function preprocess(data)
			local len = #data
			local proc = {}
			data[#data+1] = 0x80
			while #data%64~=56 do data[#data+1] = 0 end
			local blocks = math.ceil(#data/64)
			for i = 1, blocks do
				proc[i] = {}
				for j = 1, 16 do
					proc[i][j] = BE_toInt(data, 1+((i-1)*64)+((j-1)*4))
				end
			end
			proc[blocks][15], proc[blocks][16] = counter(len*8)
			return proc
		end

		local function digestblock(w, C)
			for j = 17, 64 do
				local s0 = bxor(bxor(rrotate(w[j-15], 7), rrotate(w[j-15], 18)), brshift(w[j-15], 3))
				local s1 = bxor(bxor(rrotate(w[j-2], 17), rrotate(w[j-2], 19)), brshift(w[j-2], 10))
				w[j] = (w[j-16] + s0 + w[j-7] + s1)%mod32
			end
			local a, b, c, d, e, f, g, h = upack(C)
			for j = 1, 64 do
				local S1 = bxor(bxor(rrotate(e, 6), rrotate(e, 11)), rrotate(e, 25))
				local ch = bxor(band(e, f), band(bnot(e), g))
				local temp1 = (h + S1 + ch + K[j] + w[j])%mod32
				local S0 = bxor(bxor(rrotate(a, 2), rrotate(a, 13)), rrotate(a, 22))
				local maj = bxor(bxor(band(a, b), band(a, c)), band(b, c))
				local temp2 = (S0 + maj)%mod32
				h, g, f, e, d, c, b, a = g, f, e, (d+temp1)%mod32, c, b, a, (temp1+temp2)%mod32
			end
			C[1] = (C[1] + a)%mod32
			C[2] = (C[2] + b)%mod32
			C[3] = (C[3] + c)%mod32
			C[4] = (C[4] + d)%mod32
			C[5] = (C[5] + e)%mod32
			C[6] = (C[6] + f)%mod32
			C[7] = (C[7] + g)%mod32
			C[8] = (C[8] + h)%mod32
			return C
		end

		local function toBytes(t, n)
			local b = {}
			for i = 1, n do
				b[(i-1)*4+1] = band(brshift(t[i], 24), 0xFF)
				b[(i-1)*4+2] = band(brshift(t[i], 16), 0xFF)
				b[(i-1)*4+3] = band(brshift(t[i], 8), 0xFF)
				b[(i-1)*4+4] = band(t[i], 0xFF)
			end
			return setmetatable(b, byteTableMT)
		end

		local function digest(data)
			data = data or ""
			data = type(data) == "table" and {upack(data)} or {tostring(data):byte(1,-1)}

			data = preprocess(data)
			local C = {upack(H)}
			for i = 1, #data do C = digestblock(data[i], C) end
			return toBytes(C, 8)
		end

		local function hmac(data, key)
			local data = type(data) == "table" and {upack(data)} or {tostring(data):byte(1,-1)}
			local key = type(key) == "table" and {upack(key)} or {tostring(key):byte(1,-1)}

			local blocksize = 64

			key = #key > blocksize and digest(key) or key

			local ipad = {}
			local opad = {}
			local padded_key = {}

			for i = 1, blocksize do
				ipad[i] = bxor(0x36, key[i] or 0)
				opad[i] = bxor(0x5C, key[i] or 0)
			end

			for i = 1, #data do
				ipad[blocksize+i] = data[i]
			end

			ipad = digest(ipad)

			for i = 1, blocksize do
				padded_key[i] = opad[i]
				padded_key[blocksize+i] = ipad[i]
			end

			return digest(padded_key)
		end

		local function pbkdf2(pass, salt, iter, dklen)
			local salt = type(salt) == "table" and salt or {tostring(salt):byte(1,-1)}
			local hashlen = 32
			local dklen = dklen or 32
			local block = 1
			local out = {}

			while dklen > 0 do
				local ikey = {}
				local isalt = {upack(salt)}
				local clen = dklen > hashlen and hashlen or dklen

				isalt[#isalt+1] = band(brshift(block, 24), 0xFF)
				isalt[#isalt+1] = band(brshift(block, 16), 0xFF)
				isalt[#isalt+1] = band(brshift(block, 8), 0xFF)
				isalt[#isalt+1] = band(block, 0xFF)

				for j = 1, iter do
					isalt = hmac(isalt, pass)
					for k = 1, clen do ikey[k] = bxor(isalt[k], ikey[k] or 0) end
					if j % 200 == 0 then os.queueEvent("PBKDF2", j) coroutine.yield("PBKDF2") end
				end
				dklen = dklen - clen
				block = block+1
				for k = 1, clen do out[#out+1] = ikey[k] end
			end

			return setmetatable(out, byteTableMT)
		end

		return {
			digest = digest,
			hmac = hmac,
			pbkdf2 = pbkdf2
		}
	end)()

	-- Chacha20 cipher in ComputerCraft
	-- By Anavrins
	-- For help and details, you can PM me on the CC forums
	-- You may use this code in your projects without asking me, as long as credit is given and this header is kept intact
	-- http://www.computercraft.info/forums2/index.php?/user/12870-anavrins
	-- http://pastebin.com/GPzf9JSa
	-- Last update: April 17, 2017
	local chacha20 = (function()
		local bxor = bit32.bxor
		local band = bit32.band
		local blshift = bit32.lshift
		local brshift = bit32.arshift

		local mod = 2^32
		local tau = {("expand 16-byte k"):byte(1,-1)}
		local sigma = {("expand 32-byte k"):byte(1,-1)}

		local function rotl(n, b)
			local s = n/(2^(32-b))
			local f = s%1
			return (s-f) + f*mod
		end

		local function quarterRound(s, a, b, c, d)
			s[a] = (s[a]+s[b])%mod; s[d] = rotl(bxor(s[d], s[a]), 16)
			s[c] = (s[c]+s[d])%mod; s[b] = rotl(bxor(s[b], s[c]), 12)
			s[a] = (s[a]+s[b])%mod; s[d] = rotl(bxor(s[d], s[a]), 8)
			s[c] = (s[c]+s[d])%mod; s[b] = rotl(bxor(s[b], s[c]), 7)
			return s
		end

		local function hashBlock(state, rnd)
			local s = {unpack(state)}
			for i = 1, rnd do
				local r = i%2==1
				s = r and quarterRound(s, 1, 5,  9, 13) or quarterRound(s, 1, 6, 11, 16)
				s = r and quarterRound(s, 2, 6, 10, 14) or quarterRound(s, 2, 7, 12, 13)
				s = r and quarterRound(s, 3, 7, 11, 15) or quarterRound(s, 3, 8,  9, 14)
				s = r and quarterRound(s, 4, 8, 12, 16) or quarterRound(s, 4, 5, 10, 15)
			end
			for i = 1, 16 do s[i] = (s[i]+state[i])%mod end
			return s
		end

		local function LE_toInt(bs, i)
			return (bs[i+1] or 0)+
			blshift((bs[i+2] or 0), 8)+
			blshift((bs[i+3] or 0), 16)+
			blshift((bs[i+4] or 0), 24)
		end

		local function initState(key, nonce, counter)
			local isKey256 = #key == 32
			local const = isKey256 and sigma or tau
			local state = {}

			state[ 1] = LE_toInt(const, 0)
			state[ 2] = LE_toInt(const, 4)
			state[ 3] = LE_toInt(const, 8)
			state[ 4] = LE_toInt(const, 12)

			state[ 5] = LE_toInt(key, 0)
			state[ 6] = LE_toInt(key, 4)
			state[ 7] = LE_toInt(key, 8)
			state[ 8] = LE_toInt(key, 12)
			state[ 9] = LE_toInt(key, isKey256 and 16 or 0)
			state[10] = LE_toInt(key, isKey256 and 20 or 4)
			state[11] = LE_toInt(key, isKey256 and 24 or 8)
			state[12] = LE_toInt(key, isKey256 and 28 or 12)

			state[13] = counter
			state[14] = LE_toInt(nonce, 0)
			state[15] = LE_toInt(nonce, 4)
			state[16] = LE_toInt(nonce, 8)

			return state
		end

		local function serialize(state)
			local r = {}
			for i = 1, 16 do
				r[#r+1] = band(state[i], 0xFF)
				r[#r+1] = band(brshift(state[i], 8), 0xFF)
				r[#r+1] = band(brshift(state[i], 16), 0xFF)
				r[#r+1] = band(brshift(state[i], 24), 0xFF)
			end
			return r
		end

		local function crypt(data, key, nonce, cntr, round)
			assert(type(key) == "table", "ChaCha20: Invalid key format ("..type(key).."), must be table")
			assert(type(nonce) == "table", "ChaCha20: Invalid nonce format ("..type(nonce).."), must be table")
			assert(#key == 16 or #key == 32, "ChaCha20: Invalid key length ("..#key.."), must be 16 or 32")
			assert(#nonce == 12, "ChaCha20: Invalid nonce length ("..#nonce.."), must be 12")

			local data = type(data) == "table" and {unpack(data)} or {tostring(data):byte(1,-1)}
			cntr = tonumber(cntr) or 1
			round = tonumber(round) or 20

			local out = {}
			local state = initState(key, nonce, cntr)
			local blockAmt = math.floor(#data/64)
			for i = 0, blockAmt do
				local ks = serialize(hashBlock(state, round))
				state[13] = (state[13]+1) % mod

				local block = {}
				for j = 1, 64 do
					block[j] = data[((i)*64)+j]
				end
				for j = 1, #block do
					out[#out+1] = bxor(block[j], ks[j])
				end

				if i % 1000 == 0 then
					os.queueEvent("")
					os.pullEvent("")
				end
			end
			return setmetatable(out, byteTableMT)
		end

		return {
			crypt = crypt
		}
	end)()

	-- random.lua - Random Byte Generator
	local random = (function()
		local entropy = ""
		local accumulator = ""
		local entropyPath = "/.random"

		local function feed(data)
			accumulator = accumulator .. (data or "")
		end

		local function digest()
			entropy = tostring(sha256.digest(entropy .. accumulator))
			accumulator = ""
		end

		if fs.exists(entropyPath) then
			local entropyFile = fs.open(entropyPath, "rb")
			feed(entropyFile.readAll())
			entropyFile.close()
		end

		feed("init")
		feed(tostring(math.random(1, 2^31 - 1)))
		feed("|")
		feed(tostring(math.random(1, 2^31 - 1)))
		feed("|")
		feed(tostring(math.random(1, 2^4)))
		feed("|")
		feed(tostring(os.epoch("utc")))
		feed("|")
		for _ = 1, 10000 do
			feed(tostring({}):sub(-8))
		end
		digest()
		feed(tostring(os.epoch("utc")))
		digest()

		local function save()
			feed("save")
			feed(tostring(os.epoch("utc")))
			feed(tostring({}))
			digest()

			local entropyFile = fs.open(entropyPath, "wb")
			entropyFile.write(tostring(sha256.hmac("save", entropy)))
			entropy = tostring(sha256.digest(entropy))
			entropyFile.close()
		end
		save()

		local function seed(data)
			feed("seed")
			feed(tostring(os.epoch("utc")))
			feed(tostring({}))
			feed(data)
			digest()
			save()
		end

		local function random()
			feed("random")
			feed(tostring(os.epoch("utc")))
			feed(tostring({}))
			digest()
			save()

			local result = sha256.hmac("out", entropy)
			entropy = tostring(sha256.digest(entropy))
			
			return result
		end

		return {
			seed = seed,
			save = save,
			random = random
		}
	end)()

	-- Big integer arithmetic for 168-bit (and 336-bit) numbers
	-- Numbers are represented as little-endian tables of 24-bit integers
	local arith = (function()
		local function isEqual(a, b)
			return (
				a[1] == b[1]
				and a[2] == b[2]
				and a[3] == b[3]
				and a[4] == b[4]
				and a[5] == b[5]
				and a[6] == b[6]
				and a[7] == b[7]
			)
		end

		local function compare(a, b)
			for i = 7, 1, -1 do
				if a[i] > b[i] then
					return 1
				elseif a[i] < b[i] then
					return -1
				end
			end

			return 0
		end

		local function add(a, b)
			-- c7 may be greater than 2^24 before reduction
			local c1 = a[1] + b[1]
			local c2 = a[2] + b[2]
			local c3 = a[3] + b[3]
			local c4 = a[4] + b[4]
			local c5 = a[5] + b[5]
			local c6 = a[6] + b[6]
			local c7 = a[7] + b[7]

			if c1 > 0xffffff then
				c2 = c2 + 1
				c1 = c1 - 0x1000000
			end
			if c2 > 0xffffff then
				c3 = c3 + 1
				c2 = c2 - 0x1000000
			end
			if c3 > 0xffffff then
				c4 = c4 + 1
				c3 = c3 - 0x1000000
			end
			if c4 > 0xffffff then
				c5 = c5 + 1
				c4 = c4 - 0x1000000
			end
			if c5 > 0xffffff then
				c6 = c6 + 1
				c5 = c5 - 0x1000000
			end
			if c6 > 0xffffff then
				c7 = c7 + 1
				c6 = c6 - 0x1000000
			end
			
			return {c1, c2, c3, c4, c5, c6, c7}
		end

		local function sub(a, b)
			-- c7 may be negative before reduction
			local c1 = a[1] - b[1]
			local c2 = a[2] - b[2]
			local c3 = a[3] - b[3]
			local c4 = a[4] - b[4]
			local c5 = a[5] - b[5]
			local c6 = a[6] - b[6]
			local c7 = a[7] - b[7]

			if c1 < 0 then
				c2 = c2 - 1
				c1 = c1 + 0x1000000
			end
			if c2 < 0 then
				c3 = c3 - 1
				c2 = c2 + 0x1000000
			end
			if c3 < 0 then
				c4 = c4 - 1
				c3 = c3 + 0x1000000
			end
			if c4 < 0 then
				c5 = c5 - 1
				c4 = c4 + 0x1000000
			end
			if c5 < 0 then
				c6 = c6 - 1
				c5 = c5 + 0x1000000
			end
			if c6 < 0 then
				c7 = c7 - 1
				c6 = c6 + 0x1000000
			end
			
			return {c1, c2, c3, c4, c5, c6, c7}
		end

		local function rShift(a)
			local c1 = a[1]
			local c2 = a[2]
			local c3 = a[3]
			local c4 = a[4]
			local c5 = a[5]
			local c6 = a[6]
			local c7 = a[7]

			c1 = c1 / 2
			c1 = c1 - c1 % 1
			c1 = c1 + (c2 % 2) * 0x800000
			c2 = c2 / 2
			c2 = c2 - c2 % 1
			c2 = c2 + (c3 % 2) * 0x800000
			c3 = c3 / 2
			c3 = c3 - c3 % 1
			c3 = c3 + (c4 % 2) * 0x800000
			c4 = c4 / 2
			c4 = c4 - c4 % 1
			c4 = c4 + (c5 % 2) * 0x800000
			c5 = c5 / 2
			c5 = c5 - c5 % 1
			c5 = c5 + (c6 % 2) * 0x800000
			c6 = c6 / 2
			c6 = c6 - c6 % 1
			c6 = c6 + (c7 % 2) * 0x800000
			c7 = c7 / 2
			c7 = c7 - c7 % 1

			return {c1, c2, c3, c4, c5, c6, c7}
		end

		local function addDouble(a, b)
			-- a and b are 336-bit integers (14 words)
			local c1 = a[1] + b[1]
			local c2 = a[2] + b[2]
			local c3 = a[3] + b[3]
			local c4 = a[4] + b[4]
			local c5 = a[5] + b[5]
			local c6 = a[6] + b[6]
			local c7 = a[7] + b[7]
			local c8 = a[8] + b[8]
			local c9 = a[9] + b[9]
			local c10 = a[10] + b[10]
			local c11 = a[11] + b[11]
			local c12 = a[12] + b[12]
			local c13 = a[13] + b[13]
			local c14 = a[14] + b[14]

			if c1 > 0xffffff then
				c2 = c2 + 1
				c1 = c1 - 0x1000000
			end
			if c2 > 0xffffff then
				c3 = c3 + 1
				c2 = c2 - 0x1000000
			end
			if c3 > 0xffffff then
				c4 = c4 + 1
				c3 = c3 - 0x1000000
			end
			if c4 > 0xffffff then
				c5 = c5 + 1
				c4 = c4 - 0x1000000
			end
			if c5 > 0xffffff then
				c6 = c6 + 1
				c5 = c5 - 0x1000000
			end
			if c6 > 0xffffff then
				c7 = c7 + 1
				c6 = c6 - 0x1000000
			end
			if c7 > 0xffffff then
				c8 = c8 + 1
				c7 = c7 - 0x1000000
			end
			if c8 > 0xffffff then
				c9 = c9 + 1
				c8 = c8 - 0x1000000
			end
			if c9 > 0xffffff then
				c10 = c10 + 1
				c9 = c9 - 0x1000000
			end
			if c10 > 0xffffff then
				c11 = c11 + 1
				c10 = c10 - 0x1000000
			end
			if c11 > 0xffffff then
				c12 = c12 + 1
				c11 = c11 - 0x1000000
			end
			if c12 > 0xffffff then
				c13 = c13 + 1
				c12 = c12 - 0x1000000
			end
			if c13 > 0xffffff then
				c14 = c14 + 1
				c13 = c13 - 0x1000000
			end

			return {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14}
		end

		local function mult(a, b, half_multiply)
			local a1, a2, a3, a4, a5, a6, a7 = unpack(a)
			local b1, b2, b3, b4, b5, b6, b7 = unpack(b)
			
			local c1 = a1 * b1
			local c2 = a1 * b2 + a2 * b1
			local c3 = a1 * b3 + a2 * b2 + a3 * b1
			local c4 = a1 * b4 + a2 * b3 + a3 * b2 + a4 * b1
			local c5 = a1 * b5 + a2 * b4 + a3 * b3 + a4 * b2 + a5 * b1
			local c6 = a1 * b6 + a2 * b5 + a3 * b4 + a4 * b3 + a5 * b2 + a6 * b1
			local c7 = a1 * b7 + a2 * b6 + a3 * b5 + a4 * b4 + a5 * b3 + a6 * b2
					   + a7 * b1
			local c8, c9, c10, c11, c12, c13, c14
			if not half_multiply then
				c8 = a2 * b7 + a3 * b6 + a4 * b5 + a5 * b4 + a6 * b3 + a7 * b2
				c9 = a3 * b7 + a4 * b6 + a5 * b5 + a6 * b4 + a7 * b3
				c10 = a4 * b7 + a5 * b6 + a6 * b5 + a7 * b4
				c11 = a5 * b7 + a6 * b6 + a7 * b5
				c12 = a6 * b7 + a7 * b6
				c13 = a7 * b7
				c14 = 0
			else
				c8 = 0
			end

			local temp
			temp = c1
			c1 = c1 % 0x1000000
			c2 = c2 + (temp - c1) / 0x1000000
			temp = c2
			c2 = c2 % 0x1000000
			c3 = c3 + (temp - c2) / 0x1000000
			temp = c3
			c3 = c3 % 0x1000000
			c4 = c4 + (temp - c3) / 0x1000000
			temp = c4
			c4 = c4 % 0x1000000
			c5 = c5 + (temp - c4) / 0x1000000
			temp = c5
			c5 = c5 % 0x1000000
			c6 = c6 + (temp - c5) / 0x1000000
			temp = c6
			c6 = c6 % 0x1000000
			c7 = c7 + (temp - c6) / 0x1000000
			temp = c7
			c7 = c7 % 0x1000000
			if not half_multiply then
				c8 = c8 + (temp - c7) / 0x1000000
				temp = c8
				c8 = c8 % 0x1000000
				c9 = c9 + (temp - c8) / 0x1000000
				temp = c9
				c9 = c9 % 0x1000000
				c10 = c10 + (temp - c9) / 0x1000000
				temp = c10
				c10 = c10 % 0x1000000
				c11 = c11 + (temp - c10) / 0x1000000
				temp = c11
				c11 = c11 % 0x1000000
				c12 = c12 + (temp - c11) / 0x1000000
				temp = c12
				c12 = c12 % 0x1000000
				c13 = c13 + (temp - c12) / 0x1000000
				temp = c13
				c13 = c13 % 0x1000000
				c14 = c14 + (temp - c13) / 0x1000000
			end

			return {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14}
		end

		local function square(a)
			-- returns a 336-bit integer (14 words)
			local a1, a2, a3, a4, a5, a6, a7 = unpack(a)
			
			local c1 = a1 * a1
			local c2 = a1 * a2 * 2
			local c3 = a1 * a3 * 2 + a2 * a2
			local c4 = a1 * a4 * 2 + a2 * a3 * 2
			local c5 = a1 * a5 * 2 + a2 * a4 * 2 + a3 * a3
			local c6 = a1 * a6 * 2 + a2 * a5 * 2 + a3 * a4 * 2
			local c7 = a1 * a7 * 2 + a2 * a6 * 2 + a3 * a5 * 2 + a4 * a4
			local c8 = a2 * a7 * 2 + a3 * a6 * 2 + a4 * a5 * 2
			local c9 = a3 * a7 * 2 + a4 * a6 * 2 + a5 * a5
			local c10 = a4 * a7 * 2 + a5 * a6 * 2
			local c11 = a5 * a7 * 2 + a6 * a6
			local c12 = a6 * a7 * 2
			local c13 = a7 * a7
			local c14 = 0

			local temp
			temp = c1
			c1 = c1 % 0x1000000
			c2 = c2 + (temp - c1) / 0x1000000
			temp = c2
			c2 = c2 % 0x1000000
			c3 = c3 + (temp - c2) / 0x1000000
			temp = c3
			c3 = c3 % 0x1000000
			c4 = c4 + (temp - c3) / 0x1000000
			temp = c4
			c4 = c4 % 0x1000000
			c5 = c5 + (temp - c4) / 0x1000000
			temp = c5
			c5 = c5 % 0x1000000
			c6 = c6 + (temp - c5) / 0x1000000
			temp = c6
			c6 = c6 % 0x1000000
			c7 = c7 + (temp - c6) / 0x1000000
			temp = c7
			c7 = c7 % 0x1000000
			c8 = c8 + (temp - c7) / 0x1000000
			temp = c8
			c8 = c8 % 0x1000000
			c9 = c9 + (temp - c8) / 0x1000000
			temp = c9
			c9 = c9 % 0x1000000
			c10 = c10 + (temp - c9) / 0x1000000
			temp = c10
			c10 = c10 % 0x1000000
			c11 = c11 + (temp - c10) / 0x1000000
			temp = c11
			c11 = c11 % 0x1000000
			c12 = c12 + (temp - c11) / 0x1000000
			temp = c12
			c12 = c12 % 0x1000000
			c13 = c13 + (temp - c12) / 0x1000000
			temp = c13
			c13 = c13 % 0x1000000
			c14 = c14 + (temp - c13) / 0x1000000

			return {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14}
		end

		local function encodeInt(a)
			local enc = {}

			for i = 1, 7 do
				local word = a[i]
				for j = 1, 3 do
					enc[#enc + 1] = word % 256
					word = math.floor(word / 256)
				end
			end

			return enc
		end

		local function decodeInt(enc)
			local a = {}
			local encCopy = {}

			for i = 1, 21 do
				local byte = enc[i]
				assert(type(byte) == "number", "integer decoding failure")
				assert(byte >= 0 and byte <= 255, "integer decoding failure")
				assert(byte % 1 == 0, "integer decoding failure")
				encCopy[i] = byte
			end

			for i = 1, 21, 3 do
				local word = 0
				for j = 2, 0, -1 do
					word = word * 256
					word = word + encCopy[i + j]
				end
				a[#a + 1] = word
			end

			return a
		end

		local function mods(d, w)
			local result = d[1] % 2^w

			if result >= 2^(w - 1) then
				result = result - 2^w
			end

			return result
		end

		-- Represents a 168-bit number as the (2^w)-ary Non-Adjacent Form
		local function NAF(d, w)
			local t = {}
			local d = {unpack(d)}

			for i = 1, 168 do
				if d[1] % 2 == 1 then
					t[#t + 1] = mods(d, w)
					d = sub(d, {t[#t], 0, 0, 0, 0, 0, 0})
				else
					t[#t + 1] = 0
				end

				d = rShift(d)
			end

			return t
		end

		return {
			isEqual = isEqual,
			compare = compare,
			add = add,
			sub = sub,
			addDouble = addDouble,
			mult = mult,
			square = square,
			encodeInt = encodeInt,
			decodeInt = decodeInt,
			NAF = NAF
		}
	end)()

	-- Arithmetic on the finite field of integers modulo p
	-- Where p is the finite field modulus
	local modp = (function()
		local add = arith.add
		local sub = arith.sub
		local addDouble = arith.addDouble
		local mult = arith.mult
		local square = arith.square

		local p = {3, 0, 0, 0, 0, 0, 15761408}

		-- We're using the Montgomery Reduction for fast modular multiplication.
		-- https://en.wikipedia.org/wiki/Montgomery_modular_multiplication 
		-- r = 2^168
		-- p * pInverse = -1 (mod r)
		-- r2 = r * r (mod p)
		local pInverse = {5592405, 5592405, 5592405, 5592405, 5592405, 5592405, 14800213}
		local r2 = {13533400, 837116, 6278376, 13533388, 837116, 6278376, 7504076}

		local function multByP(a)
			local a1, a2, a3, a4, a5, a6, a7 = unpack(a)

			local c1 = a1 * 3
			local c2 = a2 * 3
			local c3 = a3 * 3
			local c4 = a4 * 3
			local c5 = a5 * 3
			local c6 = a6 * 3
			local c7 = a1 * 15761408
			c7 = c7 + a7 * 3
			local c8 = a2 * 15761408
			local c9 = a3 * 15761408
			local c10 = a4 * 15761408
			local c11 = a5 * 15761408
			local c12 = a6 * 15761408
			local c13 = a7 * 15761408
			local c14 = 0

			local temp
			temp = c1 / 0x1000000
			c2 = c2 + (temp - temp % 1)
			c1 = c1 % 0x1000000
			temp = c2 / 0x1000000
			c3 = c3 + (temp - temp % 1)
			c2 = c2 % 0x1000000
			temp = c3 / 0x1000000
			c4 = c4 + (temp - temp % 1)
			c3 = c3 % 0x1000000
			temp = c4 / 0x1000000
			c5 = c5 + (temp - temp % 1)
			c4 = c4 % 0x1000000
			temp = c5 / 0x1000000
			c6 = c6 + (temp - temp % 1)
			c5 = c5 % 0x1000000
			temp = c6 / 0x1000000
			c7 = c7 + (temp - temp % 1)
			c6 = c6 % 0x1000000
			temp = c7 / 0x1000000
			c8 = c8 + (temp - temp % 1)
			c7 = c7 % 0x1000000
			temp = c8 / 0x1000000
			c9 = c9 + (temp - temp % 1)
			c8 = c8 % 0x1000000
			temp = c9 / 0x1000000
			c10 = c10 + (temp - temp % 1)
			c9 = c9 % 0x1000000
			temp = c10 / 0x1000000
			c11 = c11 + (temp - temp % 1)
			c10 = c10 % 0x1000000
			temp = c11 / 0x1000000
			c12 = c12 + (temp - temp % 1)
			c11 = c11 % 0x1000000
			temp = c12 / 0x1000000
			c13 = c13 + (temp - temp % 1)
			c12 = c12 % 0x1000000
			temp = c13 / 0x1000000
			c14 = c14 + (temp - temp % 1)
			c13 = c13 % 0x1000000

			return {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14}
		end

		-- Reduces a number from [0, 2p - 1] to [0, p - 1]
		local function reduceModP(a)
			-- a < p
			if a[7] < 15761408 or a[7] == 15761408 and a[1] < 3 then
				return {unpack(a)}
			end

			-- a > p
			local c1 = a[1]
			local c2 = a[2]
			local c3 = a[3]
			local c4 = a[4]
			local c5 = a[5]
			local c6 = a[6]
			local c7 = a[7]

			c1 = c1 - 3
			c7 = c7 - 15761408

			if c1 < 0 then
				c2 = c2 - 1
				c1 = c1 + 0x1000000
			end
			if c2 < 0 then
				c3 = c3 - 1
				c2 = c2 + 0x1000000
			end
			if c3 < 0 then
				c4 = c4 - 1
				c3 = c3 + 0x1000000
			end
			if c4 < 0 then
				c5 = c5 - 1
				c4 = c4 + 0x1000000
			end
			if c5 < 0 then
				c6 = c6 - 1
				c5 = c5 + 0x1000000
			end
			if c6 < 0 then
				c7 = c7 - 1
				c6 = c6 + 0x1000000
			end

			return {c1, c2, c3, c4, c5, c6, c7}
		end

		local function addModP(a, b)
			return reduceModP(add(a, b))
		end

		local function subModP(a, b)
			local result = sub(a, b)

			if result[7] < 0 then
				result = add(result, p)
			end
			
			return result
		end

		-- Montgomery REDC algorithn
		-- Reduces a number from [0, p^2 - 1] to [0, p - 1]
		local function REDC(T)
			local m = mult(T, pInverse, true)
			local t = {unpack(addDouble(T, multByP(m)), 8, 14)}

			return reduceModP(t)
		end

		local function multModP(a, b)
			-- Only works with a, b in Montgomery form
			return REDC(mult(a, b))
		end

		local function squareModP(a)
			-- Only works with a in Montgomery form
			return REDC(square(a))
		end

		local function montgomeryModP(a)
			return multModP(a, r2)
		end

		local function inverseMontgomeryModP(a)
			local a = {unpack(a)}

			for i = 8, 14 do
				a[i] = 0
			end

			return REDC(a)
		end

		local ONE = montgomeryModP({1, 0, 0, 0, 0, 0, 0})

		local function expModP(base, exponentBinary)
			local base = {unpack(base)}
			local result = {unpack(ONE)}

			for i = 1, 168 do
				if exponentBinary[i] == 1 then
					result = multModP(result, base)
				end
				base = squareModP(base)
			end 

			return result
		end

		return {
			addModP = addModP,
			subModP = subModP,
			multModP = multModP,
			squareModP = squareModP,
			montgomeryModP = montgomeryModP,
			inverseMontgomeryModP = inverseMontgomeryModP,
			expModP = expModP
		}
	end)()

	-- Arithmetic on the Finite Field of Integers modulo q
	-- Where q is the generator's subgroup order.
	local modq = (function()
		local isEqual = arith.isEqual
		local compare = arith.compare
		local add = arith.add
		local sub = arith.sub
		local addDouble = arith.addDouble
		local mult = arith.mult
		local square = arith.square
		local encodeInt = arith.encodeInt
		local decodeInt = arith.decodeInt

		local modQMT

		local q = {9622359, 6699217, 13940450, 16775734, 16777215, 16777215, 3940351}
		local qMinusTwoBinary = {1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1}
		
		-- We're using the Montgomery Reduction for fast modular multiplication.
		-- https://en.wikipedia.org/wiki/Montgomery_modular_multiplication 
		-- r = 2^168
		-- q * qInverse = -1 (mod r)
		-- r2 = r * r (mod q)
		local qInverse = {15218585, 5740955, 3271338, 9903997, 9067368, 7173545, 6988392}
		local r2 = {1336213, 11071705, 9716828, 11083885, 9188643, 1494868, 3306114}

		-- Reduces a number from [0, 2q - 1] to [0, q - 1]
		local function reduceModQ(a)
			local result = {unpack(a)}

			if compare(result, q) >= 0 then
				result = sub(result, q)
			end

			return setmetatable(result, modQMT)
		end

		local function addModQ(a, b)
			return reduceModQ(add(a, b))
		end

		local function subModQ(a, b)
			local result = sub(a, b)

			if result[7] < 0 then
				result = add(result, q)
			end
			
			return setmetatable(result, modQMT)
		end

		-- Montgomery REDC algorithn
		-- Reduces a number from [0, q^2 - 1] to [0, q - 1]
		local function REDC(T)
			local m = {unpack(mult({unpack(T, 1, 7)}, qInverse, true), 1, 7)}
			local t = {unpack(addDouble(T, mult(m, q)), 8, 14)}

			return reduceModQ(t)
		end

		local function multModQ(a, b)
			-- Only works with a, b in Montgomery form
			return REDC(mult(a, b))
		end

		local function squareModQ(a)
			-- Only works with a in Montgomery form
			return REDC(square(a))
		end

		local function montgomeryModQ(a)
			return multModQ(a, r2)
		end

		local function inverseMontgomeryModQ(a)
			local a = {unpack(a)}

			for i = 8, 14 do
				a[i] = 0
			end

			return REDC(a)
		end

		local ONE = montgomeryModQ({1, 0, 0, 0, 0, 0, 0})

		local function expModQ(base, exponentBinary)
			local base = {unpack(base)}
			local result = {unpack(ONE)}

			for i = 1, 168 do
				if exponentBinary[i] == 1 then
					result = multModQ(result, base)
				end
				base = squareModQ(base)
			end 

			return result
		end

		local function intExpModQ(base, exponent)
			local base = {unpack(base)}
			local result = setmetatable({unpack(ONE)}, modQMT)

			if exponent < 0 then
				base = expModQ(base, qMinusTwoBinary)
				exponent = -exponent
			end

			while exponent > 0 do
				if exponent % 2 == 1 then
					result = multModQ(result, base)
				end
				base = squareModQ(base)
				exponent = exponent / 2
				exponent = exponent - exponent % 1
			end 

			return result
		end

		local function encodeModQ(a)
			local result = encodeInt(a)

			return setmetatable(result, byteTableMT)
		end

		local function decodeModQ(s)
			s = type(s) == "table" and {unpack(s, 1, 21)} or {tostring(s):byte(1, 21)}
			local result = decodeInt(s)
			result[7] = result[7] % q[7]

			return setmetatable(result, modQMT)
		end

		local function randomModQ()
			while true do
				local s = {unpack(random.random(), 1, 21)}
				local result = decodeInt(s)
				if result[7] < q[7] then
					return setmetatable(result, modQMT)
				end
			end
		end

		local function hashModQ(data)
			return decodeModQ(sha256.digest(data))
		end

		modQMT = {
			__index = {
				encode = function(self)
					return encodeModQ(self)
				end
			},

			__tostring = function(self)
				return self:encode():toHex()
			end,

			__add = function(self, other)
				if type(self) == "number" then
					return other + self
				end

				if type(other) == "number" then
					assert(other < 2^24, "number operand too big")
					other = montgomeryModQ({other, 0, 0, 0, 0, 0, 0})
				end

				return addModQ(self, other)
			end,

			__sub = function(a, b)
				if type(a) == "number" then
					assert(a < 2^24, "number operand too big")
					a = montgomeryModQ({a, 0, 0, 0, 0, 0, 0})
				end

				if type(b) == "number" then
					assert(b < 2^24, "number operand too big")
					b = montgomeryModQ({b, 0, 0, 0, 0, 0, 0})
				end

				return subModQ(a, b)
			end,

			__unm = function(self)
				return subModQ(q, self)
			end,

			__eq = function(self, other)
				return isEqual(self, other)
			end,

			__mul = function(self, other)
				if type(self) == "number" then
					return other * self
				end

				-- EC point
				-- Use the point's metatable to handle multiplication
				if type(other) == "table" and type(other[1]) == "table" then
					return other * self
				end

				if type(other) == "number" then
					assert(other < 2^24, "number operand too big")
					other = montgomeryModQ({other, 0, 0, 0, 0, 0, 0})
				end

				return multModQ(self, other)
			end,

			__div = function(a, b)
				if type(a) == "number" then
					assert(a < 2^24, "number operand too big")
					a = montgomeryModQ({a, 0, 0, 0, 0, 0, 0})
				end

				if type(b) == "number" then
					assert(b < 2^24, "number operand too big")
					b = montgomeryModQ({b, 0, 0, 0, 0, 0, 0})
				end

				local bInv = expModQ(b, qMinusTwoBinary)

				return multModQ(a, bInv)
			end,

			__pow = function(self, other)
				return intExpModQ(self, other)
			end
		}

		return {
			hashModQ = hashModQ,
			randomModQ = randomModQ,
			decodeModQ = decodeModQ,
			inverseMontgomeryModQ = inverseMontgomeryModQ
		}
	end)()

	-- Elliptic curve arithmetic
	local curve = (function()
		---- About the Curve Itself
		-- Field Size: 168 bits
		-- Field Modulus (p): 481 * 2^159 + 3
		-- Equation: x^2 + y^2 = 1 + 122 * x^2 * y^2
		-- Parameters: Edwards Curve with d = 122
		-- Curve Order (n): 351491143778082151827986174289773107581916088585564
		-- Cofactor (h): 4
		-- Generator Order (q): 87872785944520537956996543572443276895479022146391
		---- About the Curve's Security
		-- Current best attack security: 81.777 bits (Small Subgroup + Rho)
		-- Rho Security: log2(0.884 * sqrt(q)) = 82.777 bits
		-- Transfer Security? Yes: p ~= q; k > 20
		-- Field Discriminant Security? Yes:
		--    t = 27978492958645335688000168
		--    s = 10
		--    |D| = 6231685068753619775430107799412237267322159383147 > 2^100
		-- Rigidity? No, not at all.
		-- XZ/YZ Ladder Security? No: Single coordinate ladders are insecure.
		-- Small Subgroup Security? No.
		-- Invalid Curve Security? Yes: Points are checked before every operation.
		-- Invalid Curve Twist Security? No: Don't use single coordinate ladders.
		-- Completeness? Yes: The curve is complete.
		-- Indistinguishability? Yes (Elligator 2), but not implemented.

		local isEqual = arith.isEqual
		local NAF = arith.NAF
		local encodeInt = arith.encodeInt
		local decodeInt = arith.decodeInt
		local multModP = modp.multModP
		local squareModP = modp.squareModP
		local addModP = modp.addModP
		local subModP = modp.subModP
		local montgomeryModP = modp.montgomeryModP
		local expModP = modp.expModP
		local inverseMontgomeryModQ = modq.inverseMontgomeryModQ
		
		local pointMT
		local ZERO = {0, 0, 0, 0, 0, 0, 0}
		local ONE = montgomeryModP({1, 0, 0, 0, 0, 0, 0})

		-- Curve Parameters
		local d = montgomeryModP({122, 0, 0, 0, 0, 0, 0})
		local p = {3, 0, 0, 0, 0, 0, 15761408}
		local pMinusTwoBinary = {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1}
		local pMinusThreeOverFourBinary = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1}
		local G = {
			{6636044, 10381432, 15741790, 2914241, 5785600, 264923, 4550291},
			{13512827, 8449886, 5647959, 1135556, 5489843, 7177356, 8002203},
			{unpack(ONE)}
		}
		local O = {
			{unpack(ZERO)},
			{unpack(ONE)},
			{unpack(ONE)}
		}

		-- Projective Coordinates for Edwards curves for point addition/doubling.
		-- Points are represented as: (X:Y:Z) where x = X/Z and y = Y/Z
		-- The identity element is represented by (0:1:1)
		-- Point operation formulas are available on the EFD:
		-- https://www.hyperelliptic.org/EFD/g1p/auto-edwards-projective.html
		local function pointDouble(P1)
			-- 3M + 4S
			local X1, Y1, Z1 = unpack(P1)

			local b = addModP(X1, Y1)
			local B = squareModP(b)
			local C = squareModP(X1)
			local D = squareModP(Y1)
			local E = addModP(C, D)
			local H = squareModP(Z1)
			local J = subModP(E, addModP(H, H))
			local X3 = multModP(subModP(B, E), J)
			local Y3 = multModP(E, subModP(C, D))
			local Z3 = multModP(E, J)
			local P3 = {X3, Y3, Z3}

			return setmetatable(P3, pointMT)
		end

		local function pointAdd(P1, P2)
			-- 10M + 1S
			local X1, Y1, Z1 = unpack(P1)
			local X2, Y2, Z2 = unpack(P2)

			local A = multModP(Z1, Z2)
			local B = squareModP(A)
			local C = multModP(X1, X2)
			local D = multModP(Y1, Y2)
			local E = multModP(d, multModP(C, D))
			local F = subModP(B, E)
			local G = addModP(B, E)
			local X3 = multModP(A, multModP(F, subModP(multModP(addModP(X1, Y1), addModP(X2, Y2)), addModP(C, D))))
			local Y3 = multModP(A, multModP(G, subModP(D, C)))
			local Z3 = multModP(F, G)
			local P3 = {X3, Y3, Z3}

			return setmetatable(P3, pointMT)
		end

		local function pointNeg(P1)
			local X1, Y1, Z1 = unpack(P1)

			local X3 = subModP(ZERO, X1)
			local Y3 = {unpack(Y1)}
			local Z3 = {unpack(Z1)}
			local P3 = {X3, Y3, Z3}

			return setmetatable(P3, pointMT)
		end

		local function pointSub(P1, P2)
			return pointAdd(P1, pointNeg(P2))
		end

		-- Converts (X:Y:Z) into (X:Y:1) = (x:y:1)
		local function pointScale(P1)
			local X1, Y1, Z1 = unpack(P1)

			local A = expModP(Z1, pMinusTwoBinary)
			local X3 = multModP(X1, A)
			local Y3 = multModP(Y1, A)
			local Z3 = {unpack(ONE)}
			local P3 = {X3, Y3, Z3}

			return setmetatable(P3, pointMT)
		end

		local function pointIsEqual(P1, P2)
			local X1, Y1, Z1 = unpack(P1)
			local X2, Y2, Z2 = unpack(P2)

			local A1 = multModP(X1, Z2)
			local B1 = multModP(Y1, Z2)
			local A2 = multModP(X2, Z1)
			local B2 = multModP(Y2, Z1)

			return isEqual(A1, A2) and isEqual(B1, B2)
		end

		-- Checks if a projective point satisfies the curve equation
		local function pointIsOnCurve(P1)
			local X1, Y1, Z1 = unpack(P1)

			local X12 = squareModP(X1)
			local Y12 = squareModP(Y1)
			local Z12 = squareModP(Z1)
			local Z14 = squareModP(Z12)
			local a = addModP(X12, Y12)
			a = multModP(a, Z12)
			local b = multModP(d, multModP(X12, Y12))
			b = addModP(Z14, b)

			return isEqual(a, b)
		end

		local function pointIsInf(P1)
			return isEqual(P1[1], ZERO)
		end

		-- W-ary Non-Adjacent Form (wNAF) method for scalar multiplication:
		-- https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#w-ary_non-adjacent_form_(wNAF)_method
		local function scalarMult(multiplier, P1)
			-- w = 5
			local naf = NAF(multiplier, 5)
			local PTable = {P1}
			local P2 = pointDouble(P1)
			local Q = {{unpack(ZERO)}, {unpack(ONE)}, {unpack(ONE)}}

			for i = 3, 31, 2 do
				PTable[i] = pointAdd(PTable[i - 2], P2)
			end

			for i = #naf, 1, -1 do
				Q = pointDouble(Q)
				if naf[i] > 0 then
					Q = pointAdd(Q, PTable[naf[i]])
				elseif naf[i] < 0 then
					Q = pointSub(Q, PTable[-naf[i]])
				end
			end

			return setmetatable(Q, pointMT)
		end

		-- Lookup table 4-ary NAF method for scalar multiplication by G.
		-- Precomputations for the regular NAF method are done before the multiplication.
		local GTable = {G}
		for i = 2, 168 do
			GTable[i] = pointDouble(GTable[i - 1])
		end

		local function scalarMultG(multiplier)
			local naf = NAF(multiplier, 2)
			local Q = {{unpack(ZERO)}, {unpack(ONE)}, {unpack(ONE)}}

			for i = 1, 168 do
				if naf[i] == 1 then
					Q = pointAdd(Q, GTable[i])
				elseif naf[i] == -1 then
					Q = pointSub(Q, GTable[i])
				end
			end

			return setmetatable(Q, pointMT)
		end

		-- Point compression and encoding.
		-- Compresses curve points to 22 bytes.
		local function pointEncode(P1)
			P1 = pointScale(P1)
			local result = {}
			local x, y = unpack(P1)

			-- Encode y
			result = encodeInt(y)
			-- Encode one bit from x
			result[22] = x[1] % 2

			return setmetatable(result, byteTableMT)
		end

		local function pointDecode(enc)
			enc = type(enc) == "table" and {unpack(enc, 1, 22)} or {tostring(enc):byte(1, 22)}
			-- Decode y
			local y = decodeInt(enc)
			y[7] = y[7] % p[7]
			-- Find {x, -x} using curve equation
			local y2 = squareModP(y)
			local u = subModP(y2, ONE)
			local v = subModP(multModP(d, y2), ONE)
			local u2 = squareModP(u)
			local u3 = multModP(u, u2)
			local u5 = multModP(u3, u2)
			local v3 = multModP(v, squareModP(v))
			local w = multModP(u5, v3)
			local x = multModP(u3, multModP(v, expModP(w, pMinusThreeOverFourBinary)))
			-- Use enc[22] to find x from {x, -x}
			if x[1] % 2 ~= enc[22] then
				x = subModP(ZERO, x)
			end
			local P3 = {x, y, {unpack(ONE)}}

			return setmetatable(P3, pointMT)
		end

		pointMT = {
			__index = {
				isOnCurve = function(self)
					return pointIsOnCurve(self)
				end,

				isInf = function(self)
					return self:isOnCurve() and pointIsInf(self)
				end,

				encode = function(self)
					return pointEncode(self)
				end
			},

			__tostring = function(self)
				return self:encode():toHex()
			end,

			__add = function(P1, P2)
				assert(P1:isOnCurve(), "invalid point")
				assert(P2:isOnCurve(), "invalid point")
				
				return pointAdd(P1, P2)
			end,

			__sub = function(P1, P2)
				assert(P1:isOnCurve(), "invalid point")
				assert(P2:isOnCurve(), "invalid point")
				
				return pointSub(P1, P2)
			end,

			__unm = function(self)
				assert(self:isOnCurve(), "invalid point")
				
				return pointNeg(self)
			end,

			__eq = function(P1, P2)
				assert(P1:isOnCurve(), "invalid point")
				assert(P2:isOnCurve(), "invalid point")
				
				return pointIsEqual(P1, P2)
			end,

			__mul = function(P1, s)
				if type(P1) == "number" then
					return s * P1
				end

				if type(s) == "number" then
					assert(s < 2^24, "number multiplier too big")
					s = {s, 0, 0, 0, 0, 0, 0}
				else
					s = inverseMontgomeryModQ(s)
				end

				if P1 == G then
					return scalarMultG(s)
				else
					return scalarMult(s, P1)
				end
			end
		}

		G = setmetatable(G, pointMT)
		O = setmetatable(O, pointMT)

		return {
			G = G,
			O = O,
			pointDecode = pointDecode
		}
	end)()

	local function getNonceFromEpoch()
		local nonce = {}
		local epoch = os.epoch("utc")
		for i = 1, 12 do
			nonce[#nonce + 1] = epoch % 256
			epoch = epoch / 256
			epoch = epoch - epoch % 1
		end

		return nonce
	end

	local function encrypt(data, key)
		local encKey = sha256.hmac("encKey", key)
		local macKey = sha256.hmac("macKey", key)
		local nonce = getNonceFromEpoch()
		local ciphertext = chacha20.crypt(data, encKey, nonce)
		local result = nonce
		for i = 1, #ciphertext do
			result[#result + 1] = ciphertext[i]
		end
		local mac = sha256.hmac(result, macKey)
		for i = 1, #mac do
			result[#result + 1] = mac[i]
		end

		return setmetatable(result, byteTableMT)
	end

	local function decrypt(data, key)
		local data = type(data) == "table" and {unpack(data)} or {tostring(data):byte(1,-1)}
		local encKey = sha256.hmac("encKey", key)
		local macKey = sha256.hmac("macKey", key)
		local mac = sha256.hmac({unpack(data, 1, #data - 32)}, macKey)
		local messageMac = {unpack(data, #data - 31)}
		assert(mac:isEqual(messageMac), "invalid mac")
		local nonce = {unpack(data, 1, 12)}
		local ciphertext = {unpack(data, 13, #data - 32)}
		local result = chacha20.crypt(ciphertext, encKey, nonce)

		return setmetatable(result, byteTableMT)
	end

	local function keypair(seed)
		local x
		if seed then
			x = modq.hashModQ(seed)
		else
			x = modq.randomModQ()
		end
		local Y = curve.G * x

		local privateKey = x:encode()
		local publicKey = Y:encode()

		return privateKey, publicKey
	end

	local function exchange(privateKey, publicKey)
		local x = modq.decodeModQ(privateKey)
		local Y = curve.pointDecode(publicKey)

		local Z = Y * x

		local sharedSecret = sha256.digest(Z:encode())

		return sharedSecret
	end

	local function sign(privateKey, message)
		local message = type(message) == "table" and string.char(unpack(message)) or tostring(message)
		local privateKey = type(privateKey) == "table" and string.char(unpack(privateKey)) or tostring(privateKey)
		local x = modq.decodeModQ(privateKey)
		local k = modq.randomModQ()
		local R = curve.G * k
		local e = modq.hashModQ(message .. tostring(R))
		local s = k - x * e

		e = e:encode()
		s = s:encode()

		local result = e
		for i = 1, #s do
			result[#result + 1] = s[i]
		end

		return setmetatable(result, byteTableMT)
	end

	local function verify(publicKey, message, signature)
		local message = type(message) == "table" and string.char(unpack(message)) or tostring(message)
		local Y = curve.pointDecode(publicKey)
		local e = modq.decodeModQ({unpack(signature, 1, #signature / 2)})
		local s = modq.decodeModQ({unpack(signature, #signature / 2 + 1)})
		local Rv = curve.G * s + Y * e
		local ev = modq.hashModQ(message .. tostring(Rv))

		return ev == e
	end

	return {
		chacha20 = chacha20,
		sha256 = sha256,
		random = random,
		encrypt = encrypt,
		decrypt = decrypt,
		keypair = keypair,
		exchange = exchange,
		sign = sign,
		verify = verify
	}
end

function runRedrun(...)
	--- RedRun - A very tiny background task runner using the native top-level coroutine
	-- By JackMacWindows
	-- Licensed under CC0, though I'd appreciate it if this notice was left in place.
	-- @module redrun

	-- Note: RedRun is not intended for use as a fully-featured multitasking environment. It is meant
	-- to allow running small asynchronous tasks that just listen for events and respond (like
	-- rednet.run does). While it is certainly possible to use this to make a functioning kernel, you
	-- should not do this as a) any time spent in the processes is time taken from Rednet, and b) there
	-- is no filtering for user-initiated events, or automatic terminal redirect handling.
	-- Yes: Background network file transfer, asynchronous GPS host, remote shell host (if implemented correctly)
	-- No: Window server, multishell, music player

	local expect = require "cc.expect".expect

	local redrun = {}
	local coroutines = {}

	--- Initializes the RedRun runtime. This is called automatically, but it's still available if desired.
	-- @param silent Set to any truthy value to inhibit the status message.
	function redrun.init(silent)
		-- We hijack the DNS response mechanism to inject code through rednet.send (which luckily uses the rednet table instead of the local environment, unlike with isOpen)
		local oldSend = rednet.send
		rednet.send = function(id, ...)
			local env = getfenv(2)
			if id == "redrun" and env.isOpen ~= nil then
				if env.__redrun_coroutines then
					-- RedRun was already initialized, so just grab the coroutine table and run
					coroutines = env.__redrun_coroutines
				else
					-- For the actual code execution, we go through os.pullEventRaw which is the only function called unconditionally each loop
					-- To avoid breaking real os, we set this through the environment of the function
					-- We also use a metatable to avoid writing every other function out
					env.os = setmetatable({
						pullEventRaw = function()
							local ev = table.pack(coroutine.yield())
							local delete = {}
							for k,v in pairs(coroutines) do
								if v.terminate or v.filter == nil or v.filter == ev[1] or ev[1] == "terminate" then
									local ok
									if v.terminate then ok, v.filter = coroutine.resume(v.coro, "terminate")
									else ok, v.filter = coroutine.resume(v.coro, table.unpack(ev, 1, ev.n)) end
									if not ok or coroutine.status(v.coro) ~= "suspended" or v.terminate then delete[#delete+1] = k end
								end
							end
							for _,v in ipairs(delete) do coroutines[v] = nil end
							return table.unpack(ev, 1, ev.n)
						end
					}, {__index = os, __isredrun = true})
					-- Add the coroutine table to the environment to be fetched by init later
					env.__redrun_coroutines = coroutines
					if not silent then print("Successfully registered RedRun.") end
				end
			else return oldSend(id, ...) end
		end
		-- Execute the code as rednet.run by making a successful DNS request
		rednet.host("redrun_register", "a") -- host looks up the host name on other computers, which may take two seconds if rednet is open
		os.queueEvent("rednet_message", "redrun", {sType = "lookup", sProtocol = "redrun_register"}, "dns") -- rednet.run doesn't check the ID's type, so we use a string to be unique
		os.queueEvent("redrun_pause") -- We queue two events since it has to yield twice (first gives rednet.run the current event, second gives rednet.run the rednet_message)
		-- Keep any other events added in the queue
		while true do
			local ev = table.pack(os.pullEvent())
			if ev[1] == "redrun_pause" then break
			else os.queueEvent(table.unpack(ev, 1, ev.n)) end
		end
		-- Clean up
		rednet.unhost("redrun_register", "a")
		rednet.send = oldSend
	end

	--- Starts a coroutine running in the background.
	-- @param func The function to run.
	-- @param name A value to use to identify this task later. Can be any value, including nil/none.
	-- @return The ID of the started task.
	function redrun.start(func, name)
		expect(1, func, "function")
		local id = #coroutines+1
		coroutines[id] = {coro = coroutine.create(func), name = name}
		return id
	end

	--- Returns the task ID for a named task.
	-- @param name The name of the task.
	-- @return The ID of the task with the name, or nil if not found.
	function redrun.getid(name)
		for k,v in pairs(coroutines) do if v.name == name then return k end end
		return nil
	end

	--- Kills a task immediately.
	-- @param id The ID of the task.
	function redrun.kill(id)
		expect(1, id, "number")
		coroutines[id] = nil
	end

	--- Terminates a task. This sends it one terminate event, and then removes it from the queue.
	-- @param id The ID of the task.
	function redrun.terminate(id)
		expect(1, id, "number")
		if coroutines[id] == nil then error("Task ID " .. id .. " is not running", 2) end
		coroutines[id].terminate = true
		os.queueEvent("redrun_pause")
		while true do
			local ev = table.pack(os.pullEvent())
			if ev[1] == "redrun_pause" then break
			else os.queueEvent(table.unpack(ev, 1, ev.n)) end
		end
	end

	redrun.init(...)
	return redrun
end

function runRawshell(shellArgs)
	-- MIT License
	--
	-- Copyright (c) 2021 JackMacWindows
	--
	-- Permission is hereby granted, free of charge, to any person obtaining a copy
	-- of this software and associated documentation files (the "Software"), to deal
	-- in the Software without restriction, including without limitation the rights
	-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	-- copies of the Software, and to permit persons to whom the Software is
	-- furnished to do so, subject to the following conditions:
	--
	-- The above copyright notice and this permission notice shall be included in all
	-- copies or substantial portions of the Software.
	--
	-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	-- SOFTWARE.

	local rawterm = require "rawterm" -- https://gist.github.com/MCJack123/50b211c55ceca4376e51d33435026006
	local hasECC, ecc                 -- https://pastebin.com/ZGJGBJdg (comment out `os.pullEvent`s)
	local hasRedrun, redrun           -- https://gist.github.com/MCJack123/473475f07b980d57dd2bd818026c97e8

	local localEvents = {key = true, key_up = true, char = true, mouse_click = true, mouse_up = true, mouse_drag = true, mouse_scroll = true, mouse_move = true, term_resize = true, paste = true}
	local serverRunning = false

	local function randomString()
		local str = ""
		for i = 1, 16 do str = str .. string.char(math.random(32, 127)) end
		return str
	end

	local function singleserver(delegate, func, ...)
		local server = rawterm.server(delegate, 51, 19, 0, "Remote Shell")
		delegate.server = server
		local coro = coroutine.create(func)
		local oldterm = term.redirect(server)
		local ok, filter = coroutine.resume(coro, ...)
		term.redirect(oldterm)
		server.setVisible(false)
		local lastRender = os.epoch "utc"
		while ok and coroutine.status(coro) == "suspended" and not delegate.closed do
			local ev = table.pack(server.pullEvent(filter, true))
			oldterm = term.redirect(server)
			ok, filter = coroutine.resume(coro, table.unpack(ev, 1, ev.n))
			term.redirect(oldterm)
			if os.epoch "utc" - lastRender >= 50 then
				server.setVisible(true)
				server.setVisible(false)
				lastRender = os.epoch "utc"
			end
		end
		if not ok then printError(filter) end
		server.close()
		if coroutine.status(coro) == "suspended" then
			oldterm = term.redirect(server)
			filter = coroutine.resume(coro, "terminate")
			term.redirect(oldterm)
		end
	end

	local delegate_mt = {}
	delegate_mt.__index = delegate_mt
	function delegate_mt:send(data)
		if self.closed then return end
		if self.key then data = string.char(table.unpack(ecc.encrypt(randomString() .. data, self.key))) end
		self.modem.transmit(self.port, self.port, {id = os.computerID(), data = data})
	end
	function delegate_mt:receive()
		if self.closed then return nil end
		while true do
			local ev, side, channel, reply, message = os.pullEventRaw("modem_message")
			if ev == "modem_message" and channel == self.port and type(message) == "table" and message.id == self.id then
				message = message.data
				if self.key then
					message = string.char(table.unpack(ecc.decrypt(message, self.key)))
					--[[ argh, decrypt yields and that will break this, so we have to run it in a coroutine!
					local coro = coroutine.create(ecc.decrypt)
					local ok, a
					while coroutine.status(coro) == "suspended" do ok, a = coroutine.resume(coro, message, self.key) end
					if not ok then printError(message) return end
					message = string.char(table.unpack(a))
					]]
					if #message > 16 and not self.nonces[message:sub(1, 16)] then
						self.nonces[message:sub(1, 16)] = true
						self.port = reply
						return message:sub(17)
					end
				else
					self.port = reply
					return message
				end
			end
		end
	end
	function delegate_mt:close()
		if self.closed then return end
		if not self.silent then print("> Closed connection on port " .. self.port) end
		self.modem.close(self.port)
		self.key = nil
		self.nonces = nil
		self.closed = true
	end

	local function makeDelegate(modem, port, key, id, silent)
		modem.open(port)
		return setmetatable({
			modem = modem,
			port = port,
			key = key,
			id = id,
			silent = silent,
			closed = false,
			nonces = key and {}
		}, delegate_mt)
	end

	local function serve(password, secure, modem, program, url, background)
		if secure and not hasECC then error("Secure mode requires the ECC library to function.", 2)
		elseif password and not secure then
			term.setTextColor(colors.yellow)
			print("Warning: A password was set, but secure mode is disabled. Password will be sent in plaintext.")
			term.setTextColor(colors.white)
		end
		modem = modem or peripheral.find("modem")
		if not modem then error("Please attach a modem.", 2) end
		modem.open(5731)
		local priv, pub
		if secure then
			priv, pub = ecc.keypair(ecc.random.random())
			if password then password = ecc.sha256.digest(password):toHex() end
		end
		print("Server is now listening for connections.")
		local threads = {}
		local usedChallenges = {}
		serverRunning = true
		while serverRunning do
			local ev = table.pack(coroutine.yield())
			if ev[1] == "modem_message" and ev[3] == 5731 and type(ev[5]) == "table" and ev[5].server == os.computerID() then
				if not ev[5].id then
					modem.transmit(5731, 5731, {server = os.computerID(), status = "Missing ID"})
				elseif secure and (not ev[5].key or not ev[5].challenge) then
					modem.transmit(5731, 5731, {server = os.computerID(), id = ev[5].id, status = "Secure connection required", key = pub, challenge = randomString()})
				elseif secure and (not ev[5].response or string.char(table.unpack(ecc.decrypt(ev[5].response, ecc.exchange(priv, ev[5].key)) or {})) ~= ev[5].challenge) then
					modem.transmit(5731, 5731, {server = os.computerID(), id = ev[5].id, status = "Challenge failed", key = pub, challenge = randomString()})
				elseif password and not ev[5].password then
					modem.transmit(5731, 5731, {server = os.computerID(), id = ev[5].id, status = "Password required"})
				else
					local ok = true
					local key
					if secure then key = ecc.exchange(priv, ev[5].key) end
					if password then
						if secure then ok = not usedChallenges[ev[5].challenge] and string.char(table.unpack(ecc.decrypt(ev[5].password, key))) == password .. ev[5].challenge
						else ok = ev[5].password == password end
					end
					if ok then
						if secure then usedChallenges[ev[5].challenge] = true end
						local port = math.random(1000, 65500)
						while modem.isOpen(port) do port = math.random(1000, 65500) end
						if not background then print("> New connection from ID " .. ev[5].id .. " on port " .. port) end
						modem.transmit(5731, port, {server = os.computerID(), id = ev[5].id, status = "Opening connection"})
						local coro = coroutine.create(singleserver)
						local delegate = makeDelegate(modem, port, key, ev[5].id, background)
						local ok, filter
						if background then
							if program then program = program:gsub("^%S+", shell.resolveProgram) end
							ok, filter = coroutine.resume(coro, delegate, os.run, setmetatable({}, {__index = _G}), program or "rom/programs/shell.lua")
						else ok, filter = coroutine.resume(coro, delegate, shell.run, program or "shell") end
						if ok then threads[#threads+1] = {delegate = delegate, coro = coro, filter = filter}
						else printError(filter) end
					else
						modem.transmit(5731, 5731, {server = os.computerID(), id = ev[5].id, status = "Password incorrect"})
					end
				end
			elseif ev[1] == "terminate" then serverRunning = false
			else
				local ok
				local delete = {}
				for i,v in pairs(threads) do
					if (v.filter == nil or v.filter == ev[1]) and not localEvents[ev[1]] then
						ok, v.filter = coroutine.resume(v.coro, table.unpack(ev, 1, ev.n))
						if not ok or coroutine.status(v.coro) ~= "suspended" then
							if not ok then printError(v.filter) end
							delete[#delete+1] = i
						end
					end
				end
				for _,v in ipairs(delete) do threads[v] = nil end
			end
		end
		for _,v in pairs(threads) do
			if coroutine.status(v.coro) == "suspended" then coroutine.resume(v.coro, "terminate") end
			v.delegate.server.close()
		end
		print("Server closed.")
	end

	local function recv(id)
		local tm = os.startTimer(5)
		while true do
			local ev = table.pack(os.pullEvent())
			if ev[1] == "modem_message" and ev[3] == 5731 and type(ev[5]) == "table" and ev[5].server == id then return ev[5], ev[4]
			elseif ev[1] == "timer" and ev[2] == tm then return nil end
		end
	end

	local function connect(id, modem, win)
		if not tonumber(id) then
			if not http.checkURL(id:gsub("wss?://", "http://")) then error("ID argument must be a number or URL", 2) end
			local delegate = rawterm.wsDelegate(id)
			return rawterm.client(delegate, 0, win), delegate
		end
		id = tonumber(id)
		modem = modem or peripheral.find("modem")
		if not modem then error("Please attach a modem.", 2) end
		modem.open(5731)
		local req = {server = id, id = os.computerID()}
		local key, res, port
		while true do
			modem.transmit(5731, 5731, req)
			res, port = recv(id)
			if not res then error("Connection failed: Timeout") end
			if res.status == "Secure connection required" then
				if not hasECC then hasECC, ecc = pcall(require, "ecc") end
				if not hasECC then error("Connection failed: Server requires secure connection, but ECC library is not installed.", 2) end
				local priv, pub = ecc.keypair(ecc.random.random())
				key = ecc.exchange(priv, res.key)
				req.key = pub
				req.challenge = res.challenge
				req.response = string.char(table.unpack(ecc.encrypt(res.challenge, key)))
			elseif res.status == "Password required" then
				if not key then print("Warning: This connection is not secure. Your password will be sent unencrypted.") end
				write("Password: ")
				req.password = read("\7")
				if key then req.password = string.char(table.unpack(ecc.encrypt(ecc.sha256.digest(req.password):toHex() .. req.challenge, key))) end
			elseif res.status == "Opening connection" then break
			else error("Connection failed: " .. res.status, 2) end
		end
		local delegate = makeDelegate(modem, port, key, id, true)
		return rawterm.client(delegate, 0, win), delegate
	end

	local args = shellArgs

	if args[1] == "serve" or args[1] == "host" then
		local background = false
		local program = nil
		local modem = nil
		local password = nil
		local secure = false
		local url = nil
		local nextarg = nil
		for _, arg in ipairs(args) do
			if nextarg then
				if nextarg == 1 then program = arg
				elseif nextarg == 2 then modem = arg
				elseif nextarg == 3 then password = arg
				elseif nextarg == 4 then url = arg end
				nextarg = nil
			elseif arg == "-b" then
				hasRedrun, redrun = pcall(require, "redrun")
				background = true
			elseif arg == "-s" then
				hasECC, ecc = pcall(require, "ecc")
				secure = true
			elseif arg == "-c" then nextarg = 1
			elseif arg == "-m" then nextarg = 2
			elseif arg == "-p" then nextarg = 3
			elseif arg == "-w" then nextarg = 4 end
		end

		if modem then
			if peripheral.getType(modem) ~= "modem" then error("Peripheral on selected side is not a modem.") end
			modem = peripheral.wrap(modem)
		end
		if background then
			if not hasRedrun then error("Background task running requires the RedRun library.") end
			if url then
				redrun.start(function() return singleserver(rawterm.wsDelegate(url, {["X-Rawterm-Is-Server"] = "Yes"}), os.run, setmetatable({}, {__index = _G}), program or "rom/programs/shell.lua") end, "rawshell_server")
			else
				redrun.start(function() return serve(password, secure, modem, program, url, true) end, "rawshell_server")
				while not serverRunning do coroutine.yield() end
			end
		elseif url then singleserver(rawterm.wsDelegate(url, {["X-Rawterm-Is-Server"] = "Yes"}), shell.run, program or "shell")
		else serve(password, secure, modem, program, url, false) end
	elseif args[1] == "connect" and args[2] then
		local modem
		if args[3] then
			if peripheral.getType(args[3]) ~= "modem" then error("Peripheral on selected side is not a modem.") end
			modem = peripheral.wrap(args[3])
		end
		local handle = connect(args[2], modem, term.current())
		local ok, err = pcall(handle.run)
		if term.current().setVisible then term.current().setVisible(true) end
		handle.close()
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1, 1)
		term.setCursorBlink(true)
		if not ok then error(err, 2) end
	elseif args[1] == "get" and args[2] and args[3] then
		local modem
		if args[5] then
			if peripheral.getType(args[5]) ~= "modem" then error("Peripheral on selected side is not a modem.") end
			modem = peripheral.wrap(args[5])
		end
		local handle, delegate = connect(args[2], modem, nil)
		parallel.waitForAny(
			function() while not handle.fs do handle.update(delegate:receive()) end end,
			function() sleep(2) end)
		if not handle.fs then error("Connection failed: Server does not support filesystem transfers") end
		local infile, err = handle.fs.open(args[3], "rb")
		if not infile then error("Could not open remote file: " .. (err or "Unknown error")) end
		local outfile, err = fs.open(args[4] or shell.resolve(fs.getName(args[3])), "wb")
		if not outfile then
			infile.close()
			error("Could not open local file: " .. (err or "Unknown error"))
		end
		outfile.write(infile.readAll())
		infile.close()
		outfile.close()
		handle.close()
		print("Downloaded file as " .. (args[4] or shell.resolve(fs.getName(args[3]))))
	elseif args[1] == "put" and args[2] and args[3] and args[4] then
		local modem
		if args[5] then
			if peripheral.getType(args[5]) ~= "modem" then error("Peripheral on selected side is not a modem.") end
			modem = peripheral.wrap(args[5])
		end
		local handle, delegate = connect(args[2], modem, nil)
		parallel.waitForAny(
			function() while not handle.fs do handle.update(delegate:receive()) end end,
			function() sleep(2) end)
		if not handle.fs then error("Connection failed: Server does not support filesystem transfers") end
		local infile, err = fs.open(args[3], "rb")
		if not infile then error("Could not open remote file: " .. (err or "Unknown error")) end
		local outfile, err = handle.fs.open(args[4] or shell.resolve(fs.getName(args[3])), "wb")
		if not outfile then
			infile.close()
			error("Could not open local file: " .. (err or "Unknown error"))
		end
		outfile.write(infile.readAll())
		infile.close()
		outfile.close()
		handle.close()
		print("Uploaded file as " .. (args[4] or shell.resolve(fs.getName(args[3]))))
	elseif (args[1] == "ls" or args[1] == "list") and args[2] then
		local modem
		if args[4] then
			if peripheral.getType(args[5]) ~= "modem" then error("Peripheral on selected side is not a modem.") end
			modem = peripheral.wrap(args[5])
		end
		local handle, delegate = connect(args[2], modem, nil)
		parallel.waitForAny(
			function() while not handle.fs do handle.update(delegate:receive()) end end,
			function() sleep(2) end)
		if not handle.fs then error("Connection failed: Server does not support filesystem transfers") end
		local files = handle.fs.list(args[3] or "/")
		local fileList, dirList = {}, {}
		local showHidden = settings.get("list.show_hidden")
		for _, v in pairs(files) do
			if showHidden or v:sub(1, 1) ~= "." then
				local path = fs.combine(args[3] or "/", v)
				if handle.fs.isDir(path) then dirList[#dirList+1] = v
				else fileList[#fileList+1] = v end
			end
		end
		handle.close()
		table.sort(dirList)
		table.sort(fileList)
		if term.isColor() then textutils.pagedTabulate(colors.green, dirList, colors.white, fileList)
		else textutils.pagedTabulate(colors.lightGray, dirList, colors.white, fileList) end
	elseif args[1] == "status" then
		hasRedrun, redrun = pcall(require, "redrun")
		if hasRedrun then
			local id = redrun.getid("rawshell_server")
			if not id then print("Status: Server is not running.")
			else print("Status: Server is running as ID " .. id .. ".") end
		else error("Background task running requires the RedRun library.") end
	elseif args[1] == "stop" then
		hasRedrun, redrun = pcall(require, "redrun")
		if hasRedrun then
			local id = redrun.getid("rawshell_server")
			if not id then error("Server is not running.") end
			redrun.terminate(id)
		else error("Background task running requires the RedRun library.") end
	else
		term.setTextColor(colors.red)
		textutils.pagedPrint[[
	Usage:
		rawshell connect <id> [side]
		rawshell get <id> <remote path> [local path] [side]
		rawshell put <id> <local path> <remote path> [side]
		raswhell ls <id> [remote path]
		rawshell serve [-c <program>] [-m <side>] [-p <password>] [-w <url>] [-b] [-s]
		rawshell status
		rawshell stop
	Arguments:
		<id>                The ID of the server to connect to, or a WebSocket URL
		-b                  Run in background (requires RedRun)
		-c <program>        Program to run on connection (defaults to "shell")
		-m <side> / [side]  Use modem attached to the selected side
		-p <password>       Require password to log in
		-s                  Use secure connection (requires ECC)
		-w <url>            Serve to a WebSocket URL instead of over a modem]]
		term.setTextColor(colors.white)
	end
end

runRawshell(args)