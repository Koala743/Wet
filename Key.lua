local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    ServiceId = 1951,
    ProxyUrl = "https://jolly-bush-a809.armijosfeo.workers.dev",
    ApiHosts = {
        "https://api.platoboost.com",
        "https://api.platoboost.net",
        "https://api.platoboost.app"
    },
    Timeout = 15,
    MaxRetries = 2,
    KeyFile = "SavedKeys.json"
}

local cachedLink = nil
local cachedTime = 0
local currentIdentifier = nil

repeat task.wait(0.5) until game:IsLoaded()

local requestFunction = (
    http_request or 
    request or 
    (syn and syn.request) or
    (http and http.request)
)

local function getIdentifier()
    if currentIdentifier then return currentIdentifier end
    local success, hwid = pcall(function() return gethwid and gethwid() or nil end)
    if success and hwid then
        currentIdentifier = tostring(hwid)
    else
        currentIdentifier = tostring(player.UserId) .. "_" .. tostring(game.JobId):sub(1, 8)
    end
    return currentIdentifier
end

local function saveKey(key)
    if not writefile then return false end
    local data = {
        key = key,
        identifier = getIdentifier(),
        userId = player.UserId,
        username = player.Name,
        timestamp = os.time()
    }
    pcall(function()
        writefile(CONFIG.KeyFile, HttpService:JSONEncode(data))
    end)
    return true
end

local function loadSavedKey()
    if not isfile or not readfile or not isfile(CONFIG.KeyFile) then return nil end
    local success, content = pcall(readfile, CONFIG.KeyFile)
    if not success then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok or not data then return nil end
    if data.userId == player.UserId and data.identifier == getIdentifier() then
        return data.key
    end
    return nil
end

local function makeProxyRequest(payload)
    if not requestFunction then return false, "No request function" end
    local success, result = pcall(function()
        return requestFunction({
            Url = CONFIG.ProxyUrl .. "/platoboost/start",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            Body = payload,
            Timeout = CONFIG.Timeout
        })
    end)
    if not success then return false, result end
    return true, result
end

local function makeDirectRequest(url, payload, attempt)
    attempt = attempt or 1
    if not requestFunction then return false, "No request function" end
    local success, result = pcall(function()
        return requestFunction({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
                ["User-Agent"] = "Roblox/Windows",
                ["Origin"] = "https://platoboost.com"
            },
            Body = payload,
            Timeout = CONFIG.Timeout
        })
    end)
    if not success and attempt < CONFIG.MaxRetries then
        task.wait(math.pow(2, attempt - 1))
        return makeDirectRequest(url, payload, attempt + 1)
    end
    return success, result
end

local function makeDirectGetRequest(url, attempt)
    attempt = attempt or 1
    if not requestFunction then return false, "No request function" end
    local success, result = pcall(function()
        return requestFunction({
            Url = url,
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json",
                ["User-Agent"] = "Roblox/Windows"
            },
            Timeout = CONFIG.Timeout
        })
    end)
    if not success and attempt < CONFIG.MaxRetries then
        task.wait(math.pow(2, attempt - 1))
        return makeDirectGetRequest(url, attempt + 1)
    end
    return success, result
end

local function verifyKey(key)
    local identifier = getIdentifier()
    print("🔍 Verificando key...")
    
    for hostIndex, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format("%s/public/whitelist/%d?identifier=%s&key=%s",
            host,
            CONFIG.ServiceId,
            HttpService:UrlEncode(identifier),
            HttpService:UrlEncode(key)
        )
        local success, result = makeDirectGetRequest(url)
        if success and result then
            if result.StatusCode == 200 and result.Body then
                local parseOk, data = pcall(function()
                    return HttpService:JSONDecode(result.Body)
                end)
                if parseOk and data then
                    if data.success and data.data and data.data.valid == true then
                        print("✅ Key válida en " .. host)
                        saveKey(key)
                        return true, "✅ Key válida"
                    end
                end
            end
        end
        if hostIndex < #CONFIG.ApiHosts then
            task.wait(0.5)
        end
    end
    
    print("⚠️ Conexión directa falló, intentando proxy para verificar...")
    local proxyPayload = HttpService:JSONEncode({
        service = CONFIG.ServiceId,
        identifier = identifier,
        key = key
    })
    
    local success, result = pcall(function()
        return requestFunction({
            Url = CONFIG.ProxyUrl .. "/platoboost/verify",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            Body = proxyPayload,
            Timeout = CONFIG.Timeout
        })
    end)
    
    if success and result and result.StatusCode == 200 and result.Body then
        local parseOk, data = pcall(function()
            return HttpService:JSONDecode(result.Body)
        end)
        if parseOk and data and data.success and data.data and data.data.valid == true then
            print("✅ Key válida vía PROXY")
            saveKey(key)
            return true, "✅ Key válida"
        end
    end
    
    print("❌ Key inválida o expirada")
    return false, "❌ Key inválida o expirada"
end

local function generateLink()
    if cachedLink and (os.time() - cachedTime) < 600 then
        return cachedLink, "cached"
    end
    local identifier = getIdentifier()
    local payload = HttpService:JSONEncode({
        service = CONFIG.ServiceId,
        identifier = identifier
    })
    print("🔄 Intentando conexión directa primero...")
    for hostIndex, host in ipairs(CONFIG.ApiHosts) do
        local url = host .. "/public/start"
        local success, result = makeDirectRequest(url, payload)
        if success and result then
            if result.StatusCode == 200 or result.StatusCode == 201 then
                if result.Body and result.Body ~= "" then
                    local parseOk, data = pcall(function()
                        return HttpService:JSONDecode(result.Body)
                    end)
                    if parseOk and data then
                        if data.success and data.data and data.data.url then
                            cachedLink = data.data.url
                            cachedTime = os.time()
                            print("✅ Enlace obtenido directamente de " .. host)
                            return data.data.url, "success_direct"
                        elseif data.message then
                            return nil, data.message
                        end
                    end
                end
            elseif result.StatusCode == 429 then
                return nil, "Rate limit - Espera 30 segundos"
            end
        end
        if hostIndex < #CONFIG.ApiHosts then
            task.wait(0.5)
        end
    end
    print("⚠️ Conexión directa falló, intentando proxy...")
    local success, result = makeProxyRequest(payload)
    if success and result and result.StatusCode == 200 and result.Body then
        local parseOk, data = pcall(function()
            return HttpService:JSONDecode(result.Body)
        end)
        if parseOk and data and data.success and data.data and data.data.url then
            cachedLink = data.data.url
            cachedTime = os.time()
            print("✅ Enlace obtenido vía PROXY")
            return data.data.url, "success_proxy"
        end
    end
    return nil, "No se pudo conectar\nIntenta con VPN o datos móviles"
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KeySystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 280)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 33, 38)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(88, 101, 242)
Stroke.Thickness = 2
Stroke.Transparency = 0.5
Stroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderBottom = Instance.new("Frame")
HeaderBottom.Size = UDim2.new(1, 0, 0, 12)
HeaderBottom.Position = UDim2.new(0, 0, 1, -12)
HeaderBottom.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
HeaderBottom.BorderSizePixel = 0
HeaderBottom.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔑 Sistema de Key"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = Header

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 40)
StatusLabel.Position = UDim2.new(0, 10, 0, 55)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Verificando key guardada..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = MainFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -20, 0, 40)
KeyInput.Position = UDim2.new(0, 10, 0, 105)
KeyInput.BackgroundColor3 = Color3.fromRGB(40, 43, 48)
KeyInput.BorderSizePixel = 0
KeyInput.Text = ""
KeyInput.PlaceholderText = "Ingresa tu key aquí..."
KeyInput.Font = Enum.Font.Gotham
KeyInput.TextSize = 12
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
KeyInput.TextWrapped = false
KeyInput.ClearTextOnFocus = false
KeyInput.Parent = MainFrame

local KeyInputCorner = Instance.new("UICorner")
KeyInputCorner.CornerRadius = UDim.new(0, 8)
KeyInputCorner.Parent = KeyInput

local VerifyButton = Instance.new("TextButton")
VerifyButton.Size = UDim2.new(1, -20, 0, 40)
VerifyButton.Position = UDim2.new(0, 10, 0, 155)
VerifyButton.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
VerifyButton.BorderSizePixel = 0
VerifyButton.Text = "✓ Verificar Key"
VerifyButton.Font = Enum.Font.GothamBold
VerifyButton.TextSize = 14
VerifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyButton.AutoButtonColor = false
VerifyButton.Parent = MainFrame

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 8)
VerifyCorner.Parent = VerifyButton

local LinkBox = Instance.new("TextBox")
LinkBox.Size = UDim2.new(1, -20, 0, 50)
LinkBox.Position = UDim2.new(0, 10, 0, 105)
LinkBox.BackgroundColor3 = Color3.fromRGB(40, 43, 48)
LinkBox.BorderSizePixel = 0
LinkBox.Text = ""
LinkBox.PlaceholderText = "El enlace aparecerá aquí..."
LinkBox.Font = Enum.Font.Gotham
LinkBox.TextSize = 9
LinkBox.TextColor3 = Color3.fromRGB(100, 200, 255)
LinkBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
LinkBox.TextWrapped = true
LinkBox.TextEditable = false
LinkBox.ClearTextOnFocus = false
LinkBox.MultiLine = true
LinkBox.Visible = false
LinkBox.Parent = MainFrame

local LinkBoxCorner = Instance.new("UICorner")
LinkBoxCorner.CornerRadius = UDim.new(0, 8)
LinkBoxCorner.Parent = LinkBox

local LinkBoxPadding = Instance.new("UIPadding")
LinkBoxPadding.PaddingLeft = UDim.new(0, 6)
LinkBoxPadding.PaddingRight = UDim.new(0, 6)
LinkBoxPadding.PaddingTop = UDim.new(0, 6)
LinkBoxPadding.PaddingBottom = UDim.new(0, 6)
LinkBoxPadding.Parent = LinkBox

local GenerateButton = Instance.new("TextButton")
GenerateButton.Size = UDim2.new(1, -20, 0, 40)
GenerateButton.Position = UDim2.new(0, 10, 0, 205)
GenerateButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GenerateButton.BorderSizePixel = 0
GenerateButton.Text = "🔗 Generar Enlace"
GenerateButton.Font = Enum.Font.GothamBold
GenerateButton.TextSize = 14
GenerateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GenerateButton.AutoButtonColor = false
GenerateButton.Parent = MainFrame

local GenerateCorner = Instance.new("UICorner")
GenerateCorner.CornerRadius = UDim.new(0, 8)
GenerateCorner.Parent = GenerateButton

local isProcessing = false

local function onKeyVerified()
    print("✅ ACCESO CONCEDIDO")
    ScreenGui:Destroy()
end

VerifyButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    local key = KeyInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if key == "" then
        StatusLabel.Text = "⚠️ Ingresa una key válida"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
        task.wait(2)
        StatusLabel.Text = "Ingresa tu key o genera una nueva"
        StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
        return
    end
    isProcessing = true
    VerifyButton.BackgroundColor3 = Color3.fromRGB(50, 150, 100)
    VerifyButton.Text = "Verificando..."
    StatusLabel.Text = "🔍 Verificando key..."
    StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
    task.spawn(function()
        local success, message = verifyKey(key)
        task.wait(0.5)
        if success then
            StatusLabel.Text = message
            StatusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            VerifyButton.Text = "✓ Verificado"
            VerifyButton.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            task.wait(1)
            onKeyVerified()
        else
            StatusLabel.Text = message
            StatusLabel.TextColor3 = Color3.fromRGB(240, 71, 71)
            VerifyButton.BackgroundColor3 = Color3.fromRGB(240, 71, 71)
            VerifyButton.Text = "✗ Inválida"
            task.wait(2)
            VerifyButton.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            VerifyButton.Text = "✓ Verificar Key"
            StatusLabel.Text = "Ingresa tu key o genera una nueva"
            StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
            isProcessing = false
        end
    end)
end)

GenerateButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    GenerateButton.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    GenerateButton.Text = "Generando..."
    StatusLabel.Text = "🔄 Conectando..."
    StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
    LinkBox.Visible = false
    KeyInput.Visible = false
    VerifyButton.Visible = false
    task.spawn(function()
        local link, status = generateLink()
        task.wait(0.5)
        if link then
            LinkBox.Text = link
            LinkBox.Visible = true
            local clipboardSuccess = false
            if setclipboard then
                clipboardSuccess = pcall(function()
                    setclipboard(link)
                end)
            end
            local methodText = ""
            if status == "cached" then
                methodText = "📦 Desde caché"
            elseif status == "success_proxy" then
                methodText = "🌐 Vía proxy Cloudflare"
            elseif status == "success_direct" then
                methodText = "🔗 Conexión directa"
            end
            StatusLabel.Text = "✅ Enlace generado\n" .. methodText .. (clipboardSuccess and " | Copiado ✓" or "")
            StatusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            GenerateButton.Text = "✓ Generado"
            GenerateButton.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            task.delay(5, function()
                if GenerateButton then
                    GenerateButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                    GenerateButton.Text = "🔗 Generar Nuevo"
                    LinkBox.Visible = false
                    KeyInput.Visible = true
                    VerifyButton.Visible = true
                    StatusLabel.Text = "Completa los pasos y verifica tu key"
                    StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
                    isProcessing = false
                end
            end)
        else
            StatusLabel.Text = "❌ " .. (status or "Error de conexión")
            StatusLabel.TextColor3 = Color3.fromRGB(240, 71, 71)
            GenerateButton.BackgroundColor3 = Color3.fromRGB(240, 71, 71)
            GenerateButton.Text = "Reintentar"
            task.delay(3, function()
                if GenerateButton then
                    GenerateButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                    GenerateButton.Text = "🔗 Generar Enlace"
                    KeyInput.Visible = true
                    VerifyButton.Visible = true
                    StatusLabel.Text = "Ingresa tu key o genera una nueva"
                    StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
                    isProcessing = false
                end
            end)
        end
    end)
end)

task.spawn(function()
    local savedKey = loadSavedKey()
    if savedKey then
        print("🔑 Key guardada encontrada, verificando...")
        local success, message = verifyKey(savedKey)
        if success then
            StatusLabel.Text = "✅ Key guardada válida"
            StatusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            task.wait(1)
            onKeyVerified()
        else
            StatusLabel.Text = "Ingresa tu key o genera una nueva"
            StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
        end
    else
        StatusLabel.Text = "Ingresa tu key o genera una nueva"
        StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
    end
end)

print("🔑 Key System cargado")
print("🌐 Proxy:", CONFIG.ProxyUrl)
print("📱 Request function:", requestFunction and "✓" or "✗")
print("🔐 Endpoints: /platoboost/start y /platoboost/verify")