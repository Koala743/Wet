local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local SERVICE_10H = {id = 16251, name = "10 Horas", icon = "💎"}
local IDENTIFIER_FILE = "System_Identifiers.txt"
local KEYS_FILE = "System_Keys.txt"
local PLATOBOOST_HOSTS = {"https://api.platoboost.com/", "https://api.platoboost.net/", "https://api.platoboost.app/"}

local juegos = {
    ["DBU"] = {3311165597, 5151400895, 114014249462644, 133153710156455, 138941735852322},
    ["MLGD"] = {3623096087},
    ["WAR_MACHINES"] = {12828227139},
    ["DRAGON_BALL_RAGE"] = {71315343, 3336119605, 1362482151, 15669378828, 3371469539, 1357512648}
}

local playersNoKey = {
    [""] = true,
    [""] = true,
    [""] = true,
    [""] = true
}

local requestFunc = http_request or request or HttpRequest or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or function(options)
    local success, result = pcall(function()
        if options.Method == "GET" then
            return {StatusCode = 200, Body = HttpService:GetAsync(options.Url)}
        else
            return {StatusCode = 200, Body = HttpService:PostAsync(options.Url, options.Body or "", Enum.HttpContentType.ApplicationJson)}
        end
    end)
    if success then return result end
    return {StatusCode = 500, Body = '{"success":false}'}
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

local function saveIdentifier(categoria, identifier)
    if not writefile then return end
    local data = categoria .. "|" .. identifier .. "\n"
    pcall(function()
        if isfile and isfile(IDENTIFIER_FILE) then
            local existing = readfile(IDENTIFIER_FILE)
            local found = false
            local lines = {}
            for line in existing:gmatch("[^\n]+") do
                local cat = line:match("^([^|]+)|")
                if cat == categoria then
                    table.insert(lines, data:gsub("\n", ""))
                    found = true
                else
                    table.insert(lines, line)
                end
            end
            if not found then
                table.insert(lines, data:gsub("\n", ""))
            end
            writefile(IDENTIFIER_FILE, table.concat(lines, "\n") .. "\n")
        else
            writefile(IDENTIFIER_FILE, data)
        end
    end)
end

local function loadIdentifier(categoria)
    if not isfile or not isfile(IDENTIFIER_FILE) then return nil end
    local success, content = pcall(readfile, IDENTIFIER_FILE)
    if not success then return nil end
    for line in content:gmatch("[^\n]+") do
        local cat, id = line:match("^([^|]+)|(.+)$")
        if cat == categoria then
            return id
        end
    end
    return nil
end

local function getOrCreateIdentifier(categoria)
    local existing = loadIdentifier(categoria)
    if existing then return existing end
    local newId = generateRandomIdentifier()
    saveIdentifier(categoria, newId)
    return newId
end

local function saveKey(categoria, key, host)
    if not writefile then return end
    local data = categoria .. "|" .. key .. "|" .. host .. "\n"
    pcall(function()
        if isfile and isfile(KEYS_FILE) then
            local existing = readfile(KEYS_FILE)
            local found = false
            local lines = {}
            for line in existing:gmatch("[^\n]+") do
                local cat = line:match("^([^|]+)|")
                if cat == categoria then
                    table.insert(lines, data:gsub("\n", ""))
                    found = true
                else
                    table.insert(lines, line)
                end
            end
            if not found then
                table.insert(lines, data:gsub("\n", ""))
            end
            writefile(KEYS_FILE, table.concat(lines, "\n") .. "\n")
        else
            writefile(KEYS_FILE, data)
        end
    end)
end

local function loadKey(categoria)
    if not isfile or not isfile(KEYS_FILE) then return nil, nil end
    local success, content = pcall(readfile, KEYS_FILE)
    if not success then return nil, nil end
    for line in content:gmatch("[^\n]+") do
        local cat, key, host = line:match("^([^|]+)|([^|]+)|(.+)$")
        if cat == categoria then
            return key, host
        end
    end
    return nil, nil
end

local function makeRequest(url, method, body, timeout, retries)
    timeout = timeout or 5
    retries = retries or 3
    for attempt = 1, retries do
        local result = nil
        local done = false
        local startTime = tick()
        task.spawn(function()
            local ok, res = pcall(function()
                return requestFunc({
                    Url = url,
                    Method = method or "GET",
                    Headers = {["Content-Type"] = "application/json", ["User-Agent"] = "Roblox/KeySystem"},
                    Body = body and HttpService:JSONEncode(body) or nil
                })
            end)
            if ok and res then result = res end
            done = true
        end)
        while not done and tick() - startTime < timeout do
            task.wait(0.05)
        end
        if result and result.StatusCode then return result end
        if attempt < retries then task.wait(attempt) end
    end
    return nil
end

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

local function testHost(host)
    local res = makeRequest(host .. "public/connectivity", "GET", nil, 3, 1)
    if res and res.StatusCode == 200 then
        return true
    end
    return false
end

local function findWorkingHost()
    for _, host in ipairs(PLATOBOOST_HOSTS) do
        if testHost(host) then
            return host
        end
    end
    return nil
end

local function getCategoria(placeId)
    for categoria, ids in pairs(juegos) do
        for _, id in ipairs(ids) do
            if id == placeId then return categoria end
        end
    end
    return nil
end

local function ejecutarScriptPremium()
    
end

local function generateKeyLink(categoria)
    local host = findWorkingHost()
    if not host then
        return nil, "Sin conexión", nil
    end
    local identifier = getOrCreateIdentifier(categoria)
    local body = {
        service = SERVICE_10H.id,
        identifier = identifier,
        timestamp = os.time(),
        random = math.random(100000, 999999)
    }
    local res = makeRequest(host .. "public/start", "POST", body, 8, 2)
    if res and res.StatusCode == 200 and res.Body then
        local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok and data and data.success and data.data and data.data.url then
            return data.data.url, nil, host
        end
    end
    return nil, "Error al generar link", nil
end

local function verificarKey(key, categoria, host)
    if not host then
        host = findWorkingHost()
        if not host then
            return false, "Sin conexión"
        end
    end
    local identifier = getOrCreateIdentifier(categoria)
    local endpoint = string.format("public/whitelist/%d?identifier=%s&key=%s",
        SERVICE_10H.id,
        HttpService:UrlEncode(identifier),
        HttpService:UrlEncode(key))
    local res = makeRequest(host .. endpoint, "GET", nil, 8, 2)
    if res and res.StatusCode == 200 and res.Body then
        local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok and data and data.success and data.data and data.data.valid then
            saveKey(categoria, key, host)
            return true, "Key válida"
        end
    end
    return false, "Key inválida"
end

local function verificarKeyGuardada(categoria)
    local key, host = loadKey(categoria)
    if not key or not host then return false end
    local identifier = getOrCreateIdentifier(categoria)
    local endpoint = string.format("public/whitelist/%d?identifier=%s&key=%s",
        SERVICE_10H.id,
        HttpService:UrlEncode(identifier),
        HttpService:UrlEncode(key))
    local res = makeRequest(host .. endpoint, "GET", nil, 8, 2)
    if res and res.StatusCode == 200 and res.Body then
        local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok and data and data.success and data.data and data.data.valid then
            return true
        end
    end
    if isfile and isfile(KEYS_FILE) then
        pcall(function()
            local content = readfile(KEYS_FILE)
            local lines = {}
            for line in content:gmatch("[^\n]+") do
                local cat = line:match("^([^|]+)|")
                if cat ~= categoria then
                    table.insert(lines, line)
                end
            end
            writefile(KEYS_FILE, table.concat(lines, "\n") .. (next(lines) and "\n" or ""))
        end)
    end
    return false
end

notify("🚀 Sistema Iniciando", "Verificando acceso...", 3)
local categoria = getCategoria(game.PlaceId)
if not categoria then
    notify("❌ Error", "Juego no permitido", 6)
    return
end
if playersNoKey[LocalPlayer.Name] then
    notify("👑 Acceso VIP", "Ejecutando script...", 4)
    ejecutarScriptPremium()
    return
end
if verificarKeyGuardada(categoria) then
    notify("✅ Acceso Concedido", "Key válida detectada", 4)
    ejecutarScriptPremium()
    return
end
if game.CoreGui:FindFirstChild("KeySystemGui") then
    game.CoreGui.KeySystemGui:Destroy()
end
local Gui = Instance.new("ScreenGui", game.CoreGui)
Gui.Name = "KeySystemGui"
Gui.ResetOnSpawn = false
local Frame = Instance.new("Frame", Gui)
Frame.Size = UDim2.new(0, 300, 0, 250)
Frame.Position = UDim2.new(0.5, -150, 1.5, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 12)
local UIStroke = Instance.new("UIStroke", Frame)
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(100, 80, 200)
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 10)
Title.Text = "💎 SISTEMA 10 HORAS"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
local Subtitle = Instance.new("TextLabel", Frame)
Subtitle.Size = UDim2.new(1, -20, 0, 20)
Subtitle.Position = UDim2.new(0, 10, 0, 45)
Subtitle.Text = "🎮 " .. categoria
Subtitle.TextColor3 = Color3.fromRGB(180, 160, 220)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 12
local KeyInput = Instance.new("TextBox", Frame)
KeyInput.Size = UDim2.new(1, -20, 0, 40)
KeyInput.Position = UDim2.new(0, 10, 0, 80)
KeyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.TextSize = 14
KeyInput.Font = Enum.Font.Gotham
KeyInput.PlaceholderText = "🔑 Ingresa tu clave..."
KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 150)
KeyInput.BorderSizePixel = 0
local UICornerInput = Instance.new("UICorner", KeyInput)
UICornerInput.CornerRadius = UDim.new(0, 8)
local VerifyButton = Instance.new("TextButton", Frame)
VerifyButton.Size = UDim2.new(1, -20, 0, 40)
VerifyButton.Position = UDim2.new(0, 10, 0, 135)
VerifyButton.Text = "✓ VERIFICAR KEY"
VerifyButton.Font = Enum.Font.GothamBold
VerifyButton.TextSize = 14
VerifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyButton.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
VerifyButton.BorderSizePixel = 0
local UICornerVerify = Instance.new("UICorner", VerifyButton)
UICornerVerify.CornerRadius = UDim.new(0, 8)
local GenerateButton = Instance.new("TextButton", Frame)
GenerateButton.Size = UDim2.new(1, -20, 0, 40)
GenerateButton.Position = UDim2.new(0, 10, 0, 190)
GenerateButton.Text = "🔗 OBTENER KEY"
GenerateButton.Font = Enum.Font.GothamBold
GenerateButton.TextSize = 14
GenerateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GenerateButton.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
GenerateButton.BorderSizePixel = 0
local UICornerGenerate = Instance.new("UICorner", GenerateButton)
UICornerGenerate.CornerRadius = UDim.new(0, 8)
local StatusText = Instance.new("TextLabel", Frame)
StatusText.Size = UDim2.new(1, -20, 0, 15)
StatusText.Position = UDim2.new(0, 10, 1, -25)
StatusText.Text = ""
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 10
StatusText.TextWrapped = true
VerifyButton.MouseButton1Click:Connect(function()
    local key = KeyInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if key == "" then
        StatusText.Text = "⚠️ Ingresa una clave"
        StatusText.TextColor3 = Color3.fromRGB(255, 180, 80)
        return
    end
    StatusText.Text = "⏳ Verificando..."
    StatusText.TextColor3 = Color3.fromRGB(255, 220, 150)
    VerifyButton.Text = "⏳ VERIFICANDO..."
    task.spawn(function()
        local savedKey, savedHost = loadKey(categoria)
        local ok, msg = verificarKey(key, categoria, savedHost)
        VerifyButton.Text = "✓ VERIFICAR KEY"
        if ok then
            StatusText.Text = "✅ " .. msg
            StatusText.TextColor3 = Color3.fromRGB(120, 255, 150)
            notify("✅ Acceso Concedido", msg, 5)
            task.wait(1)
            ejecutarScriptPremium()
            Gui:Destroy()
        else
            StatusText.Text = "❌ " .. msg
            StatusText.TextColor3 = Color3.fromRGB(255, 120, 120)
        end
    end)
end)
GenerateButton.MouseButton1Click:Connect(function()
    StatusText.Text = "🔗 Generando..."
    StatusText.TextColor3 = Color3.fromRGB(255, 220, 150)
    GenerateButton.Text = "⏳ GENERANDO..."
    task.spawn(function()
        local link, error, host = generateKeyLink(categoria)
        GenerateButton.Text = "🔗 OBTENER KEY"
        if link then
            pcall(function()
                if setclipboard then
                    setclipboard(link)
                    StatusText.Text = "✅ Link copiado"
                    StatusText.TextColor3 = Color3.fromRGB(120, 255, 150)
                    notify("🔗 Link Generado", "Copiado al portapapeles", 5)
                else
                    StatusText.Text = "✅ Link: " .. link:sub(1, 25) .. "..."
                    StatusText.TextColor3 = Color3.fromRGB(120, 255, 150)
                    notify("🔗 Link Generado", link, 8)
                end
            end)
        else
            StatusText.Text = "❌ " .. (error or "Error")
            StatusText.TextColor3 = Color3.fromRGB(255, 120, 120)
        end
    end)
end)
local entranceTween = TweenService:Create(Frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.5, -125)})
entranceTween:Play()