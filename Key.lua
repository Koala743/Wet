local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    ServiceId = 1951,
    ApiHosts = {
        "https://api.platoboost.com",
        "https://api.platoboost.net",
        "https://api.platoboost.app",
        "https://gateway.platoboost.com",
        "https://cdn.platoboost.com"
    }
}

local fRequest = request or http_request or syn and syn.request or http and http.request or fluxus and fluxus.request
local fSetClipboard = setclipboard or toclipboard or clipboard and clipboard.set
local fGetHwid = gethwid or function() return tostring(game:GetService("Players").LocalPlayer.UserId) end

repeat task.wait(0.5) until game:IsLoaded()

local cachedLink = nil
local cachedTime = 0
local logFrame = nil
local logLabel = nil
local logs = {}

local function createLogWindow()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LogWindow"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local frame = Instance.new("Frame")
    frame.Name = "LogFrame"
    frame.Size = UDim2.new(0, 350, 0, 400)
    frame.Position = UDim2.new(1, -360, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
    header.BorderSizePixel = 0
    header.Parent = frame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 8)
    headerBottom.Position = UDim2.new(0, 0, 1, -8)
    headerBottom.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
    headerBottom.BorderSizePixel = 0
    headerBottom.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "📋 Logs de Conexión"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 5)
    closeBtnCorner.Parent = closeBtn
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -50)
    scrollFrame.Position = UDim2.new(0, 10, 0, 40)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = frame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 5)
    scrollCorner.Parent = scrollFrame
    
    local logText = Instance.new("TextLabel")
    logText.Name = "LogText"
    logText.Size = UDim2.new(1, -10, 1, 0)
    logText.Position = UDim2.new(0, 5, 0, 0)
    logText.BackgroundTransparency = 1
    logText.Text = ""
    logText.TextColor3 = Color3.fromRGB(220, 220, 230)
    logText.TextSize = 11
    logText.Font = Enum.Font.Code
    logText.TextWrapped = true
    logText.TextXAlignment = Enum.TextXAlignment.Left
    logText.TextYAlignment = Enum.TextYAlignment.Top
    logText.Parent = scrollFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        logFrame = nil
        logLabel = nil
    end)
    
    screenGui.Parent = playerGui
    
    logFrame = scrollFrame
    logLabel = logText
    
    return screenGui
end

local function addLog(message, logType)
    local timestamp = os.date("%H:%M:%S")
    local prefix = ""
    local color = "⚪"
    
    if logType == "success" then
        prefix = "✓"
        color = "🟢"
    elseif logType == "error" then
        prefix = "✗"
        color = "🔴"
    elseif logType == "info" then
        prefix = "ℹ"
        color = "🔵"
    elseif logType == "warning" then
        prefix = "⚠"
        color = "🟡"
    end
    
    local logMessage = string.format("[%s] %s %s %s", timestamp, color, prefix, message)
    table.insert(logs, logMessage)
    
    if #logs > 100 then
        table.remove(logs, 1)
    end
    
    print(logMessage)
    
    if logLabel then
        logLabel.Text = table.concat(logs, "\n")
        
        task.wait()
        if logFrame then
            logFrame.CanvasSize = UDim2.new(0, 0, 0, logLabel.TextBounds.Y + 10)
            logFrame.CanvasPosition = Vector2.new(0, logFrame.CanvasSize.Y.Offset)
        end
    end
end

createLogWindow()

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 280)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -140)
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
    title.Text = "🔑 Obtener Key"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -20, 0, 40)
    statusLabel.Position = UDim2.new(0, 10, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Presiona el botón para obtener tu enlace"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextWrapped = true
    statusLabel.Parent = mainFrame
    
    local linkBox = Instance.new("TextBox")
    linkBox.Name = "LinkBox"
    linkBox.Size = UDim2.new(1, -20, 0, 80)
    linkBox.Position = UDim2.new(0, 10, 0, 110)
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
    generateBtn.Size = UDim2.new(1, -20, 0, 50)
    generateBtn.Position = UDim2.new(0, 10, 0, 210)
    generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    generateBtn.Text = "Generar Enlace"
    generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    generateBtn.TextSize = 16
    generateBtn.Font = Enum.Font.GothamBold
    generateBtn.AutoButtonColor = false
    generateBtn.Parent = mainFrame
    
    local genBtnCorner = Instance.new("UICorner")
    genBtnCorner.CornerRadius = UDim.new(0, 8)
    genBtnCorner.Parent = generateBtn
    
    screenGui.Parent = playerGui
    
    return screenGui, generateBtn, statusLabel, linkBox
end

local function sha256(str)
    local h0 = 0x6a09e667
    local h1 = 0xbb67ae85
    local h2 = 0x3c6ef372
    local h3 = 0xa54ff53a
    local h4 = 0x510e527f
    local h5 = 0x9b05688c
    local h6 = 0x1f83d9ab
    local h7 = 0x5be0cd19
    
    local bytes = {string.byte(str, 1, -1)}
    local len = #bytes
    
    table.insert(bytes, 0x80)
    while (#bytes + 8) % 64 ~= 0 do
        table.insert(bytes, 0x00)
    end
    
    local bitLen = len * 8
    for i = 7, 0, -1 do
        table.insert(bytes, math.floor(bitLen / (2^(i*8))) % 256)
    end
    
    local hash = string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
    return hash
end

local function generateIdentifier()
    local hwid = fGetHwid()
    return sha256(hwid)
end

local function pickHost()
    addLog("Seleccionando mejor host...", "info")
    
    local testOrder = {1, 2, 3, 4, 5}
    for i = #testOrder, 2, -1 do
        local j = math.random(i)
        testOrder[i], testOrder[j] = testOrder[j], testOrder[i]
    end
    
    for _, i in ipairs(testOrder) do
        local host = CONFIG.ApiHosts[i]
        addLog("Probando host " .. i .. ": " .. host, "info")
        
        if fRequest then
            local success, response = pcall(function()
                return fRequest({
                    Url = host .. "/public/connectivity",
                    Method = "GET",
                    Headers = {}
                })
            end)
            
            if success and response then
                addLog("StatusCode: " .. tostring(response.StatusCode), "info")
                if response.StatusCode == 200 or response.StatusCode == 204 then
                    addLog("Host seleccionado: " .. host, "success")
                    return host
                end
            else
                addLog("Error en host: " .. tostring(response), "error")
            end
        else
            local success, response = pcall(function()
                return game:HttpGetAsync(host .. "/public/connectivity")
            end)
            
            if success then
                addLog("Host seleccionado (HttpGet): " .. host, "success")
                return host
            else
                addLog("HttpGet falló en host", "error")
            end
        end
        
        task.wait(0.3)
    end
    
    addLog("Usando host por defecto: " .. CONFIG.ApiHosts[1], "warning")
    return CONFIG.ApiHosts[1]
end

local selectedHost = pickHost()

-- NUEVO: Método 1 - request() POST estándar
local function tryRequestMethod1(url, body)
    if not fRequest then return false, nil end
    
    addLog("Método 1: request() POST", "info")
    local success, response = pcall(function()
        return fRequest({
            Url = url,
            Method = "POST",
            Body = body,
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            }
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        addLog("Método 1 exitoso", "success")
        return true, response.Body
    end
    addLog("Método 1 falló: " .. tostring(response), "error")
    return false, response
end

-- NUEVO: Método 2 - HttpService:PostAsync()
local function tryRequestMethod2(url, body)
    addLog("Método 2: HttpService:PostAsync()", "info")
    local success, response = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    
    if success and response then
        addLog("Método 2 exitoso", "success")
        return true, response
    end
    addLog("Método 2 falló: " .. tostring(response), "error")
    return false, response
end

-- NUEVO: Método 3 - HttpService:RequestAsync()
local function tryRequestMethod3(url, body)
    addLog("Método 3: HttpService:RequestAsync()", "info")
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Body = body,
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
    end)
    
    if success and response and response.Success and response.StatusCode == 200 then
        addLog("Método 3 exitoso", "success")
        return true, response.Body
    end
    addLog("Método 3 falló: " .. tostring(response), "error")
    return false, response
end

-- NUEVO: Método 4 - request() con User-Agent iOS
local function tryRequestMethod4(url, body)
    if not fRequest then return false, nil end
    
    addLog("Método 4: request() con User-Agent iOS", "info")
    local success, response = pcall(function()
        return fRequest({
            Url = url,
            Method = "POST",
            Body = body,
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "Mozilla/5.0 (iPad; CPU OS 16_0 like Mac OS X) AppleWebKit/605.1.15",
                ["Accept"] = "*/*"
            }
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        addLog("Método 4 exitoso", "success")
        return true, response.Body
    end
    addLog("Método 4 falló: " .. tostring(response), "error")
    return false, response
end

-- NUEVO: Método 5 - HttpService:GetAsync() con parámetros en URL
local function tryRequestMethod5(url, body)
    addLog("Método 5: GET con params en URL", "info")
    
    local decoded = HttpService:JSONDecode(body)
    local params = "?service=" .. tostring(decoded.service) .. "&identifier=" .. tostring(decoded.identifier)
    local getUrl = url:gsub("/start", "/start" .. params)
    
    local success, response = pcall(function()
        return HttpService:GetAsync(getUrl, true)
    end)
    
    if success and response then
        addLog("Método 5 exitoso", "success")
        return true, response
    end
    addLog("Método 5 falló: " .. tostring(response), "error")
    return false, response
end

-- NUEVO: Método 6 - request() sin Content-Type
local function tryRequestMethod6(url, body)
    if not fRequest then return false, nil end
    
    addLog("Método 6: request() sin headers complejos", "info")
    local success, response = pcall(function()
        return fRequest({
            Url = url,
            Method = "POST",
            Body = body
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        addLog("Método 6 exitoso", "success")
        return true, response.Body
    end
    addLog("Método 6 falló: " .. tostring(response), "error")
    return false, response
end

-- NUEVO: Método 7 - HttpService:JSONEncode dentro del request
local function tryRequestMethod7(url, body)
    if not fRequest then return false, nil end
    
    addLog("Método 7: request() con encoding interno", "info")
    local success, response = pcall(function()
        local decoded = HttpService:JSONDecode(body)
        return fRequest({
            Url = url,
            Method = "POST",
            Body = game:GetService("HttpService"):JSONEncode(decoded),
            Headers = {
                ["Content-Type"] = "application/json"
            }
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        addLog("Método 7 exitoso", "success")
        return true, response.Body
    end
    addLog("Método 7 falló: " .. tostring(response), "error")
    return false, response
end

-- NUEVO: Método 8 - game:HttpGet() legacy
local function tryRequestMethod8(url, body)
    addLog("Método 8: Legacy HttpGet", "info")
    
    local decoded = HttpService:JSONDecode(body)
    local params = "?service=" .. tostring(decoded.service) .. "&identifier=" .. tostring(decoded.identifier)
    local getUrl = url:gsub("/start", "/start" .. params)
    
    local success, response = pcall(function()
        return game:HttpGet(getUrl)
    end)
    
    if success and response then
        addLog("Método 8 exitoso", "success")
        return true, response
    end
    addLog("Método 8 falló: " .. tostring(response), "error")
    return false, response
end

local function generateLink()
    if cachedLink and (os.time() - cachedTime) < 600 then
        addLog("Usando link en caché", "info")
        return cachedLink
    end
    
    local identifier = generateIdentifier()
    
    addLog("=== GENERANDO ENLACE ===", "info")
    addLog("Host: " .. selectedHost, "info")
    addLog("Identifier: " .. identifier:sub(1, 16) .. "...", "info")
    addLog("fRequest disponible: " .. tostring(fRequest ~= nil), "info")
    
    local url = selectedHost .. "/public/start"
    
    local requestBody = HttpService:JSONEncode({
        service = CONFIG.ServiceId,
        identifier = identifier
    })
    
    -- TODOS LOS MÉTODOS EN ORDEN
    local methods = {
        tryRequestMethod1,
        tryRequestMethod4,
        tryRequestMethod2,
        tryRequestMethod3,
        tryRequestMethod5,
        tryRequestMethod6,
        tryRequestMethod7,
        tryRequestMethod8
    }
    
    for methodNum, method in ipairs(methods) do
        addLog("Intentando método " .. methodNum .. "/" .. #methods, "info")
        local success, responseBody = method(url, requestBody)
        
        if success and responseBody then
            addLog("Respuesta recibida, parseando JSON...", "info")
            
            local parseSuccess, decoded = pcall(function()
                return HttpService:JSONDecode(responseBody)
            end)
            
            if parseSuccess and decoded.success == true and decoded.data and decoded.data.url then
                addLog("¡ENLACE GENERADO EXITOSAMENTE!", "success")
                addLog("URL: " .. decoded.data.url:sub(1, 40) .. "...", "success")
                
                cachedLink = decoded.data.url
                cachedTime = os.time()
                
                return decoded.data.url
            else
                addLog("Respuesta inválida o error en JSON", "error")
            end
        end
        
        task.wait(0.2)
    end
    
    addLog("Todos los métodos fallaron, probando hosts alternativos...", "warning")
    
    -- Probar TODOS los hosts alternativos con TODOS los métodos
    for _, fallbackHost in ipairs(CONFIG.ApiHosts) do
        if fallbackHost ~= selectedHost then
            addLog("=== HOST ALTERNATIVO: " .. fallbackHost .. " ===", "info")
            local fallbackUrl = fallbackHost .. "/public/start"
            
            for methodNum, method in ipairs(methods) do
                addLog("Método " .. methodNum .. " con host alternativo", "info")
                local success, responseBody = method(fallbackUrl, requestBody)
                
                if success and responseBody then
                    local parseSuccess, decoded = pcall(function()
                        return HttpService:JSONDecode(responseBody)
                    end)
                    
                    if parseSuccess and decoded.success == true and decoded.data and decoded.data.url then
                        addLog("¡Éxito con host alternativo!", "success")
                        
                        cachedLink = decoded.data.url
                        cachedTime = os.time()
                        selectedHost = fallbackHost
                        
                        return decoded.data.url
                    end
                end
                
                task.wait(0.2)
            end
        end
    end
    
    addLog("=== ERROR: NO SE PUDO GENERAR ENLACE ===", "error")
    addLog("Posibles causas:", "warning")
    addLog("1. Problemas de red/DNS", "warning")
    addLog("2. Firewall/ISP bloqueando", "warning")
    addLog("3. Intenta con VPN (1.1.1.1)", "warning")
    return nil
end

local function showNotif(text, color)
    task.spawn(function()
        local gui = Instance.new("ScreenGui")
        gui.IgnoreGuiInset = true
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 280, 0, 50)
        frame.Position = UDim2.new(0.5, -140, 0, -60)
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
        
        frame:TweenPosition(UDim2.new(0.5, -140, 0, 20), "Out", "Quad", 0.3, true)
        task.wait(2.5)
        frame:TweenPosition(UDim2.new(0.5, -140, 0, -60), "In", "Quad", 0.3, true)
        task.wait(0.3)
        gui:Destroy()
    end)
end

addLog("=== SISTEMA INICIADO ===", "success")
addLog("Executor: " .. (identifyexecutor and identifyexecutor() or "Desconocido"), "info")
addLog("Platform: " .. (game:GetService("UserInputService").TouchEnabled and "Mobile/Tablet" or "PC"), "info")
addLog("Versión: REFORZADA v2.0 (8 métodos)", "success")

local gui, generateBtn, statusLabel, linkBox = createUI()

generateBtn.MouseButton1Click:Connect(function()
    generateBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    generateBtn.Text = "Generando..."
    generateBtn.Active = false
    statusLabel.Text = "Conectando al servidor...\nProbando múltiples métodos..."
    
    addLog("Usuario presionó botón de generar", "info")
    
    task.spawn(function()
        local link = generateLink()
        
        if link then
            linkBox.Text = link
            linkBox.Visible = true
            
            if fSetClipboard then
                local clipSuccess = pcall(function()
                    fSetClipboard(link)
                end)
                if clipSuccess then
                    addLog("Enlace copiado al portapapeles", "success")
                else
                    addLog("No se pudo copiar al portapapeles", "warning")
                end
            end
            
            statusLabel.Text = "✅ Enlace generado!\n\nMantén presionado para copiar"
            statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            
            generateBtn.Text = "✓ Enlace Generado"
            generateBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            
            showNotif("¡Enlace generado!", Color3.fromRGB(67, 181, 129))
        else
            statusLabel.Text = "❌ Error de conexión\n\nRevisa logs / Prueba VPN"
            statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
            generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            generateBtn.Text = "Reintentar"
            generateBtn.Active = true
            
            showNotif("Error - Ver logs o usar VPN", Color3.fromRGB(237, 66, 69))
        end
    end)
end)