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

local argsDefined = {"serve","-b","-s","-p null_password"}

if argsDefined[1] == "serve" or argsDefined[1] == "host" then
    local background = false
    local program = nil
    local modem = nil
    local password = nil
    local secure = false
    local url = nil
    local nextarg = nil
    for _, arg in ipairs(argsDefined) do
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
elseif argsDefined[1] == "connect" and argsDefined[2] then
    local modem
    if argsDefined[3] then
        if peripheral.getType(argsDefined[3]) ~= "modem" then error("Peripheral on selected side is not a modem.") end
        modem = peripheral.wrap(argsDefined[3])
    end
    local handle = connect(argsDefined[2], modem, term.current())
    local ok, err = pcall(handle.run)
    if term.current().setVisible then term.current().setVisible(true) end
    handle.close()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    term.setCursorBlink(true)
    if not ok then error(err, 2) end
elseif argsDefined[1] == "get" and argsDefined[2] and argsDefined[3] then
    local modem
    if argsDefined[5] then
        if peripheral.getType(argsDefined[5]) ~= "modem" then error("Peripheral on selected side is not a modem.") end
        modem = peripheral.wrap(argsDefined[5])
    end
    local handle, delegate = connect(argsDefined[2], modem, nil)
    parallel.waitForAny(
        function() while not handle.fs do handle.update(delegate:receive()) end end,
        function() sleep(2) end)
    if not handle.fs then error("Connection failed: Server does not support filesystem transfers") end
    local infile, err = handle.fs.open(argsDefined[3], "rb")
    if not infile then error("Could not open remote file: " .. (err or "Unknown error")) end
    local outfile, err = fs.open(argsDefined[4] or shell.resolve(fs.getName(argsDefined[3])), "wb")
    if not outfile then
        infile.close()
        error("Could not open local file: " .. (err or "Unknown error"))
    end
    outfile.write(infile.readAll())
    infile.close()
    outfile.close()
    handle.close()
    print("Downloaded file as " .. (argsDefined[4] or shell.resolve(fs.getName(argsDefined[3]))))
elseif argsDefined[1] == "put" and argsDefined[2] and argsDefined[3] and argsDefined[4] then
    local modem
    if argsDefined[5] then
        if peripheral.getType(argsDefined[5]) ~= "modem" then error("Peripheral on selected side is not a modem.") end
        modem = peripheral.wrap(argsDefined[5])
    end
    local handle, delegate = connect(argsDefined[2], modem, nil)
    parallel.waitForAny(
        function() while not handle.fs do handle.update(delegate:receive()) end end,
        function() sleep(2) end)
    if not handle.fs then error("Connection failed: Server does not support filesystem transfers") end
    local infile, err = fs.open(argsDefined[3], "rb")
    if not infile then error("Could not open remote file: " .. (err or "Unknown error")) end
    local outfile, err = handle.fs.open(argsDefined[4] or shell.resolve(fs.getName(argsDefined[3])), "wb")
    if not outfile then
        infile.close()
        error("Could not open local file: " .. (err or "Unknown error"))
    end
    outfile.write(infile.readAll())
    infile.close()
    outfile.close()
    handle.close()
    print("Uploaded file as " .. (argsDefined[4] or shell.resolve(fs.getName(argsDefined[3]))))
elseif (argsDefined[1] == "ls" or argsDefined[1] == "list") and argsDefined[2] then
    local modem
    if argsDefined[4] then
        if peripheral.getType(argsDefined[5]) ~= "modem" then error("Peripheral on selected side is not a modem.") end
        modem = peripheral.wrap(argsDefined[5])
    end
    local handle, delegate = connect(argsDefined[2], modem, nil)
    parallel.waitForAny(
        function() while not handle.fs do handle.update(delegate:receive()) end end,
        function() sleep(2) end)
    if not handle.fs then error("Connection failed: Server does not support filesystem transfers") end
    local files = handle.fs.list(argsDefined[3] or "/")
    local fileList, dirList = {}, {}
    local showHidden = settings.get("list.show_hidden")
    for _, v in pairs(files) do
        if showHidden or v:sub(1, 1) ~= "." then
            local path = fs.combine(argsDefined[3] or "/", v)
            if handle.fs.isDir(path) then dirList[#dirList+1] = v
            else fileList[#fileList+1] = v end
        end
    end
    handle.close()
    table.sort(dirList)
    table.sort(fileList)
    if term.isColor() then textutils.pagedTabulate(colors.green, dirList, colors.white, fileList)
    else textutils.pagedTabulate(colors.lightGray, dirList, colors.white, fileList) end
elseif argsDefined[1] == "status" then
    hasRedrun, redrun = pcall(require, "redrun")
    if hasRedrun then
        local id = redrun.getid("rawshell_server")
        if not id then print("Status: Server is not running.")
        else print("Status: Server is running as ID " .. id .. ".") end
    else error("Background task running requires the RedRun library.") end
elseif argsDefined[1] == "stop" then
    hasRedrun, redrun = pcall(require, "redrun")
    if hasRedrun then
        local id = redrun.getid("rawshell_server")
        if not id then error("Server is not running.") end
        redrun.terminate(id)
    else error("Background task running requires the RedRun library.") end
end