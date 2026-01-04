local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    ServiceId = 1951,
    ApiHosts = {
        "https://api.platoboost.com",
        "https://api.platoboost.app",
        "https://api.platoboost.net"
    },
    KeyDuration = 1200,
    MaxRetries = 5,
    RetryDelay = 2
}

local currentSession = nil
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 340)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -170)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 10)
    headerCorner.Parent = header
    
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 10)
    headerBottom.Position = UDim2.new(0, 0, 1, -10)
    headerBottom.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    headerBottom.BorderSizePixel = 0
    headerBottom.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔑 Verificación"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -20, 0, 55)
    statusLabel.Position = UDim2.new(0, 10, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "1. Toca Obtener Key\n2. Copia el enlace\n3. Completa tareas\n4. Pega la key"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextWrapped = true
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Parent = mainFrame
    
    local linkBox = Instance.new("TextBox")
    linkBox.Name = "LinkBox"
    linkBox.Size = UDim2.new(1, -20, 0, 60)
    linkBox.Position = UDim2.new(0, 10, 0, 125)
    linkBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    linkBox.Text = ""
    linkBox.TextColor3 = Color3.fromRGB(100, 200, 255)
    linkBox.TextSize = 10
    linkBox.Font = Enum.Font.Gotham
    linkBox.TextWrapped = true
    linkBox.TextEditable = false
    linkBox.ClearTextOnFocus = false
    linkBox.MultiLine = true
    linkBox.Visible = false
    linkBox.Parent = mainFrame
    
    local linkBoxCorner = Instance.new("UICorner")
    linkBoxCorner.CornerRadius = UDim.new(0, 8)
    linkBoxCorner.Parent = linkBox
    
    local generateBtn = Instance.new("TextButton")
    generateBtn.Name = "GenerateBtn"
    generateBtn.Size = UDim2.new(1, -20, 0, 45)
    generateBtn.Position = UDim2.new(0, 10, 0, 125)
    generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    generateBtn.Text = "Obtener Key"
    generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    generateBtn.TextSize = 15
    generateBtn.Font = Enum.Font.GothamBold
    generateBtn.AutoButtonColor = false
    generateBtn.Parent = mainFrame
    
    local genBtnCorner = Instance.new("UICorner")
    genBtnCorner.CornerRadius = UDim.new(0, 8)
    genBtnCorner.Parent = generateBtn
    
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, -20, 0, 45)
    keyInput.Position = UDim2.new(0, 10, 0, 195)
    keyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    keyInput.PlaceholderText = "Pega tu key aquí"
    keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    keyInput.Text = ""
    keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.TextSize = 13
    keyInput.Font = Enum.Font.Gotham
    keyInput.ClearTextOnFocus = false
    keyInput.TextXAlignment = Enum.TextXAlignment.Center
    keyInput.Visible = false
    keyInput.Parent = mainFrame
    
    local keyInputCorner = Instance.new("UICorner")
    keyInputCorner.CornerRadius = UDim.new(0, 8)
    keyInputCorner.Parent = keyInput
    
    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Name = "VerifyBtn"
    verifyBtn.Size = UDim2.new(1, -20, 0, 45)
    verifyBtn.Position = UDim2.new(0, 10, 0, 250)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
    verifyBtn.Text = "Verificar"
    verifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    verifyBtn.TextSize = 15
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.AutoButtonColor = false
    verifyBtn.Visible = false
    verifyBtn.Parent = mainFrame
    
    local verifyBtnCorner = Instance.new("UICorner")
    verifyBtnCorner.CornerRadius = UDim.new(0, 8)
    verifyBtnCorner.Parent = verifyBtn
    
    screenGui.Parent = playerGui
    
    return screenGui, generateBtn, keyInput, verifyBtn, statusLabel, linkBox
end

local function generateGUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
end

local function makeRequestHttpService(url, method, body)
    local success, result = pcall(function()
        local requestData = {
            Url = url,
            Method = method or "GET",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
                ["User-Agent"] = "Roblox/WinInet"
            }
        }
        
        if body then
            requestData.Body = body
        end
        
        return HttpService:RequestAsync(requestData)
    end)
    
    if success and result and result.Success and result.StatusCode == 200 then
        return true, result.Body
    end
    
    return false, nil
end

local function makeRequestHttp(url, method, body)
    if not httpRequest then
        return false, nil
    end
    
    local success, result = pcall(function()
        local requestData = {
            Url = url,
            Method = method or "GET",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
                ["User-Agent"] = "Mozilla/5.0"
            }
        }
        
        if body then
            requestData.Body = body
        end
        
        return httpRequest(requestData)
    end)
    
    if success and result and result.Success and result.StatusCode == 200 then
        return true, result.Body
    end
    
    return false, nil
end

local function makeRequestGetFenv(url, method, body)
    local success, result = pcall(function()
        local req = getfenv().request or getfenv().http_request or getfenv().syn.request
        if not req then return nil end
        
        local requestData = {
            Url = url,
            Method = method or "GET",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            }
        }
        
        if body then
            requestData.Body = body
        end
        
        return req(requestData)
    end)
    
    if success and result and result.Success and result.StatusCode == 200 then
        return true, result.Body
    end
    
    return false, nil
end

local function makeRequest(url, method, body, attemptNum)
    local methods = {
        makeRequestHttpService,
        makeRequestHttp,
        makeRequestGetFenv
    }
    
    for _, requestMethod in ipairs(methods) do
        local success, responseBody = requestMethod(url, method, body)
        if success then
            return true, responseBody
        end
        task.wait(0.3)
    end
    
    return false, nil
end

local function generateLink()
    local identifier = generateGUID()
    local timestamp = tostring(os.time())
    
    for attemptNum = 1, CONFIG.MaxRetries do
        for hostIndex, host in ipairs(CONFIG.ApiHosts) do
            local url = host .. "/public/start?t=" .. timestamp .. "&attempt=" .. attemptNum
            local body = HttpService:JSONEncode({
                service = CONFIG.ServiceId,
                identifier = identifier,
                timestamp = timestamp
            })
            
            print("Intento " .. attemptNum .. "/" .. CONFIG.MaxRetries .. " - Host " .. hostIndex)
            
            local success, responseBody = makeRequest(url, "POST", body, attemptNum)
            
            if success and responseBody then
                local parseSuccess, data = pcall(function()
                    return HttpService:JSONDecode(responseBody)
                end)
                
                if parseSuccess and data and data.success and data.data and data.data.url then
                    currentSession = {
                        identifier = identifier,
                        url = data.data.url,
                        timestamp = os.time(),
                        expiry = os.time() + CONFIG.KeyDuration
                    }
                    print("Enlace generado exitosamente!")
                    return data.data.url
                end
            end
            
            task.wait(0.5)
        end
        
        if attemptNum < CONFIG.MaxRetries then
            print("Esperando " .. CONFIG.RetryDelay .. " segundos antes de reintentar...")
            task.wait(CONFIG.RetryDelay)
        end
    end
    
    print("Error: No se pudo generar el enlace después de " .. CONFIG.MaxRetries .. " intentos")
    return nil
end

local function verifyKey(key)
    if not currentSession then
        return false, "Sin sesión activa"
    end
    
    if os.time() > currentSession.expiry then
        currentSession = nil
        return false, "Sesión expirada"
    end
    
    local nonce = tostring(os.time()) .. tostring(math.random(1000, 9999))
    
    for attemptNum = 1, CONFIG.MaxRetries do
        for hostIndex, host in ipairs(CONFIG.ApiHosts) do
            local url = string.format(
                "%s/public/whitelist/%d?identifier=%s&key=%s&nonce=%s&attempt=%d",
                host,
                CONFIG.ServiceId,
                HttpService:UrlEncode(currentSession.identifier),
                HttpService:UrlEncode(key),
                nonce,
                attemptNum
            )
            
            print("Verificando - Intento " .. attemptNum .. "/" .. CONFIG.MaxRetries .. " - Host " .. hostIndex)
            
            local success, responseBody = makeRequest(url, "GET", nil, attemptNum)
            
            if success and responseBody then
                local parseSuccess, data = pcall(function()
                    return HttpService:JSONDecode(responseBody)
                end)
                
                if parseSuccess and data and data.success and data.data and data.data.valid == true then
                    print("Key verificada exitosamente!")
                    return true, "Key válida"
                end
            end
            
            task.wait(0.5)
        end
        
        if attemptNum < CONFIG.MaxRetries then
            task.wait(1)
        end
    end
    
    print("Error: Key inválida o no se pudo verificar")
    return false, "Key inválida"
end

local function showNotif(text, color)
    local gui = Instance.new("ScreenGui")
    gui.IgnoreGuiInset = true
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 50)
    frame.Position = UDim2.new(0.5, -130, 0, -60)
    frame.BackgroundColor3 = color
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextWrapped = true
    label.Parent = frame
    
    gui.Parent = playerGui
    
    frame:TweenPosition(UDim2.new(0.5, -130, 0, 20), "Out", "Quad", 0.3, true)
    task.wait(2.5)
    frame:TweenPosition(UDim2.new(0.5, -130, 0, -60), "In", "Quad", 0.3, true)
    task.wait(0.3)
    gui:Destroy()
end

print("=== SISTEMA DE KEYS INICIADO ===")
print("Executor detectado: " .. (identifyexecutor and identifyexecutor() or "Desconocido"))
print("HttpService disponible: " .. tostring(HttpService ~= nil))
print("http_request disponible: " .. tostring(httpRequest ~= nil))

local gui, generateBtn, keyInput, verifyBtn, statusLabel, linkBox = createUI()

generateBtn.MouseButton1Click:Connect(function()
    generateBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    generateBtn.Text = "Generando..."
    statusLabel.Text = "Conectando...\nIntento 1/" .. CONFIG.MaxRetries
    
    task.spawn(function()
        task.wait(0.3)
        
        local link = generateLink()
        
        if link then
            linkBox.Text = link
            linkBox.Visible = true
            
            statusLabel.Text = "✅ Enlace generado!\n\nMantén presionado el enlace\npara copiarlo"
            statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            
            generateBtn.Visible = false
            keyInput.Visible = true
            verifyBtn.Visible = true
            
            showNotif("Mantén presionado para copiar", Color3.fromRGB(67, 181, 129))
        else
            statusLabel.Text = "❌ Error de conexión\n\nNo se pudo conectar después\nde " .. CONFIG.MaxRetries .. " intentos"
            statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
            generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            generateBtn.Text = "Obtener Key"
            showNotif("Error. Verifica tu internet", Color3.fromRGB(237, 66, 69))
        end
    end)
end)

verifyBtn.MouseButton1Click:Connect(function()
    local key = keyInput.Text:gsub("%s+", "")
    
    if key == "" then
        showNotif("Ingresa una key", Color3.fromRGB(255, 165, 0))
        return
    end
    
    verifyBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 100)
    verifyBtn.Text = "Verificando..."
    statusLabel.Text = "Verificando key...\nIntento 1/" .. CONFIG.MaxRetries
    
    task.spawn(function()
        task.wait(0.3)
        
        local valid, message = verifyKey(key)
        
        if valid then
            statusLabel.Text = "✅ " .. message
            statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            showNotif("¡Verificado!", Color3.fromRGB(67, 181, 129))
            
            task.wait(1)
            gui:Destroy()
            
            print("=== KEY VERIFICADA - EJECUTANDO SCRIPT ===")
            
        else
            statusLabel.Text = "❌ " .. message
            statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
            verifyBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            verifyBtn.Text = "Verificar"
            showNotif(message, Color3.fromRGB(237, 66, 69))
        end
    end)
end)

print("Sistema de Keys listo - Presiona el botón para comenzar")