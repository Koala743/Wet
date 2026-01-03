local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local SERVICE_ID = 16251
local PLATOBOOST_HOSTS = {"https://api.platoboost.com/", "https://api.platoboost.net/", "https://api.platoboost.app/"}
local HOST_CACHE_FILE = "Platoboost_Host_Cache.json"
local IDENTIFIER_FILE = "Platoboost_Identifiers.json"
local requestFunc = http_request or request or HttpRequest or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or (krnl and krnl.request) or (Delta and Delta.request) or (Krnl and Krnl.request) or (Fluxus and Fluxus.request) or (getgenv().request) or function(options)
    local success, result = pcall(function()
        if options.Method == "GET" then
            return {StatusCode = 200, Body = HttpService:GetAsync(options.Url)}
        else
            return {StatusCode = 200, Body = HttpService:PostAsync(options.Url, options.Body or "", Enum.HttpContentType.ApplicationJson)}
        end
    end)
    if success then
        return result
    else
        if string.find(tostring(result), "429") or string.find(tostring(result), "TooManyRequests") or string.find(tostring(result), "rate limit") then
            return {StatusCode = 429, Body = '{"success":false,"message":"Rate limited"}'}
        end
        return {StatusCode = 500, Body = '{"success":false,"message":"' .. tostring(result):gsub('"', '\\"') .. '"}'}
    end
end
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 6
        })
    end)
end
local function generateRandomIdentifier()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    for i = 1, 32 do
        local rand = math.random(1, #chars)
        id = id .. chars:sub(rand, rand)
    end
    return id
end
local function saveIdentifier(identifier)
    local data = {}
    if isfile and isfile(IDENTIFIER_FILE) then
        local success, content = pcall(readfile, IDENTIFIER_FILE)
        if success then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if ok then data = decoded end
        end
    end
    if not data[LocalPlayer.Name] then data[LocalPlayer.Name] = {} end
    data[LocalPlayer.Name][SERVICE_ID] = {
        identifier = identifier,
        created = os.time(),
        userId = LocalPlayer.UserId
    }
    if writefile then
        pcall(function()
            writefile(IDENTIFIER_FILE, HttpService:JSONEncode(data))
        end)
    end
end
local function loadIdentifier()
    if not isfile or not isfile(IDENTIFIER_FILE) then return nil end
    local success, content = pcall(readfile, IDENTIFIER_FILE)
    if not success then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok or not data then return nil end
    if data[LocalPlayer.Name] and data[LocalPlayer.Name][SERVICE_ID] then
        local idData = data[LocalPlayer.Name][SERVICE_ID]
        if idData.userId == LocalPlayer.UserId then
            return idData.identifier
        end
    end
    return nil
end
local function getOrCreateIdentifier()
    local existing = loadIdentifier()
    if existing then
        return existing
    else
        local newId = generateRandomIdentifier()
        saveIdentifier(newId)
        return newId
    end
end
local universalHwid = getOrCreateIdentifier()
local function saveHostCache(host)
    local data = {
        host = host,
        timestamp = os.time(),
        player = LocalPlayer.Name
    }
    if writefile then
        pcall(function()
            writefile(HOST_CACHE_FILE, HttpService:JSONEncode(data))
        end)
    end
end
local function loadHostCache()
    if not isfile or not isfile(HOST_CACHE_FILE) then return nil end
    local success, content = pcall(readfile, HOST_CACHE_FILE)
    if not success then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok or not data then return nil end
    return data.host
end
local function makeRequest(url, method, body, timeout)
    local options = {
        Url = url,
        Method = method or "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "Roblox/KeySystem/v2.1"
        },
        Body = body and HttpService:JSONEncode(body) or nil
    }
    timeout = timeout or 8
    local result = nil
    local done = false
    local startTime = tick()
    task.spawn(function()
        local ok, res = pcall(function() return requestFunc(options) end)
        if ok and res then
            result = res
        end
        done = true
    end)
    while not done and tick() - startTime < timeout do
        task.wait(0.05)
    end
    if result and result.StatusCode then
        return result
    end
    return {StatusCode = 408, Body = '{"success":false,"message":"Timeout"}'}
end
local function testSingleHost(host)
    local startTime = tick()
    local res = makeRequest(host .. "public/connectivity", "GET", nil, 3)
    local responseTime = tick() - startTime
    if res and res.StatusCode == 200 then
        return true, responseTime
    end
    return false, 999
end
local function testHost()
    local cachedHost = loadHostCache()
    if cachedHost then
        local working, responseTime = testSingleHost(cachedHost)
        if working then
            return cachedHost
        end
    end
    local hostResults = {}
    for _, host in ipairs(PLATOBOOST_HOSTS) do
        local working, responseTime = testSingleHost(host)
        if working then
            table.insert(hostResults, {host = host, responseTime = responseTime, working = true})
        else
            table.insert(hostResults, {host = host, responseTime = 999, working = false})
        end
    end
    table.sort(hostResults, function(a, b)
        if a.working and not b.working then return true end
        if not a.working and b.working then return false end
        return a.responseTime < b.responseTime
    end)
    if #hostResults > 0 and hostResults[1].working then
        saveHostCache(hostResults[1].host)
        return hostResults[1].host
    end
    local errorDetails = "Hosts fallidos: "
    for i, h in ipairs(hostResults) do
        errorDetails = errorDetails .. h.host
        if i < #hostResults then errorDetails = errorDetails .. ", " end
    end
    return nil, errorDetails
end
local function tryMultipleHosts(endpoint, method, body, validator)
    for attempt = 1, 2 do
        local host, hostError = testHost()
        if not host then
            if attempt == 2 then
                return nil, "Sin conexión a Platoboost. " .. (hostError or "")
            end
            task.wait(2)
        else
            local url = host .. endpoint
            local res = makeRequest(url, method, body, 8)
            if res and res.StatusCode == 200 and res.Body then
                local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
                if ok and data then
                    if validator then
                        local valid, result = validator(data)
                        if valid then
                            return result, nil
                        end
                    else
                        return data, nil
                    end
                end
            end
            if attempt == 1 then
                task.wait(2)
            end
        end
    end
    return nil, "Error de conexión después de múltiples intentos"
end
local function generateLink()
    notify("🔗 Generando", "Creando enlace Platoboost...", 3)
    local body = {
        service = SERVICE_ID,
        identifier = universalHwid
    }
    local validator = function(data)
        if data.success and data.data and data.data.url then
            return true, data.data.url
        end
        return false
    end
    local result, error = tryMultipleHosts("public/start", "POST", body, validator)
    if result then
        notify("✅ Link Generado", "Copiado al portapapeles exitosamente", 5)
        if setclipboard then
            pcall(function() setclipboard(result) end)
        end
        print("LINK GENERADO:", result)
        print("HWID:", universalHwid)
        return result
    else
        local fullError = "ERROR: " .. tostring(error or "Sin respuesta del servidor")
        notify("❌ Error Generación", fullError, 8)
        print(fullError)
        print("HWID usado:", universalHwid)
        print("Service ID:", SERVICE_ID)
        return nil
    end
end
local function verifyKey(key)
    notify("⏳ Verificando", "Comprobando clave...", 3)
    local nonce = HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 16)
    local endpoint = string.format("public/whitelist/%d?identifier=%s&key=%s&nonce=%s",
        SERVICE_ID,
        HttpService:URLEncode(universalHwid),
        HttpService:URLEncode(key),
        nonce)
    local validator = function(data)
        if data.success and data.data and data.data.valid then
            return true, true
        end
        return false
    end
    local result, error = tryMultipleHosts(endpoint, "GET", nil, validator)
    if result then
        notify("✅ Clave Verificada", "Acceso concedido correctamente", 5)
        print("CLAVE VÁLIDA:", key)
        print("HWID:", universalHwid)
        return true
    else
        local fullError = "ERROR: " .. tostring(error or "Clave inválida o expirada")
        notify("❌ Error Verificación", fullError, 8)
        print(fullError)
        print("Key usada:", key)
        print("HWID usado:", universalHwid)
        return false
    end
end
if game.CoreGui:FindFirstChild("MiniKeyTest") then
    game.CoreGui.MiniKeyTest:Destroy()
end
local Gui = Instance.new("ScreenGui", game.CoreGui)
Gui.Name = "MiniKeyTest"
local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.new(0, 300, 0, 220)
Frame.Position = UDim2.new(0.5, -150, 0.5, -110)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(100, 100, 255)
Frame.Active = true
Frame.Draggable = true
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
Title.Text = "🔑 TEST KEY SYSTEM - 10H"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.BorderSizePixel = 0
local InfoLabel = Instance.new("TextLabel", Frame)
InfoLabel.Size = UDim2.new(1, -20, 0, 30)
InfoLabel.Position = UDim2.new(0, 10, 0, 45)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "HWID: " .. universalHwid:sub(1, 12) .. "..."
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 9
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
local KeyInput = Instance.new("TextBox", Frame)
KeyInput.Size = UDim2.new(1, -40, 0, 35)
KeyInput.Position = UDim2.new(0, 20, 0, 80)
KeyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.Font = Enum.Font.Gotham
KeyInput.TextSize = 12
KeyInput.PlaceholderText = "Ingresa tu clave aquí..."
KeyInput.Text = ""
KeyInput.BorderSizePixel = 1
KeyInput.BorderColor3 = Color3.fromRGB(100, 100, 255)
local GenerateBtn = Instance.new("TextButton", Frame)
GenerateBtn.Size = UDim2.new(1, -40, 0, 35)
GenerateBtn.Position = UDim2.new(0, 20, 0, 125)
GenerateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
GenerateBtn.Text = "🔗 GENERAR LINK"
GenerateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GenerateBtn.Font = Enum.Font.GothamBold
GenerateBtn.TextSize = 12
GenerateBtn.BorderSizePixel = 0
local VerifyBtn = Instance.new("TextButton", Frame)
VerifyBtn.Size = UDim2.new(1, -40, 0, 35)
VerifyBtn.Position = UDim2.new(0, 20, 0, 170)
VerifyBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
VerifyBtn.Text = "✅ VERIFICAR CLAVE"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.TextSize = 12
VerifyBtn.BorderSizePixel = 0
GenerateBtn.MouseButton1Click:Connect(function()
    GenerateBtn.Text = "⏳ Generando..."
    GenerateBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    task.spawn(function()
        local link = generateLink()
        task.wait(1)
        GenerateBtn.Text = "🔗 GENERAR LINK"
        GenerateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    end)
end)
VerifyBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if key == "" then
        notify("⚠️ Error Input", "Debes ingresar una clave primero", 6)
        return
    end
    VerifyBtn.Text = "⏳ Verificando..."
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    task.spawn(function()
        local isValid = verifyKey(key)
        task.wait(1)
        if isValid then
            VerifyBtn.Text = "✅ VÁLIDA!"
            VerifyBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            task.wait(2)
            Gui:Destroy()
        else
            VerifyBtn.Text = "❌ INVÁLIDA"
            VerifyBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            task.wait(2)
            VerifyBtn.Text = "✅ VERIFICAR CLAVE"
            VerifyBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        end
    end)
end)
GenerateBtn.MouseEnter:Connect(function()
    GenerateBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 255)
end)
GenerateBtn.MouseLeave:Connect(function()
    GenerateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
end)
VerifyBtn.MouseEnter:Connect(function()
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(120, 255, 120)
end)
VerifyBtn.MouseLeave:Connect(function()
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
end)
notify("🚀 Sistema Iniciado", "HWID: " .. universalHwid:sub(1, 16) .. "...", 5)
print("=== MINI KEY SYSTEM TEST ===")
print("HWID:", universalHwid)
print("Service ID:", SERVICE_ID)
print("Executor:", identifyexecutor and identifyexecutor() or "Unknown")