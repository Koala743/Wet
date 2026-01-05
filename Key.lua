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
        "https://cdn.platoboost.com",
        "http://api.platoboost.com",
        "http://api.platoboost.net"
    }
}

local fRequest = request or http_request or (delta and delta.request) or (Delta and Delta.request) or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
local fSetClipboard = setclipboard or toclipboard or (clipboard and clipboard.set) or (delta and delta.setclipboard) or (Delta and Delta.setclipboard) or setrbxclipboard
local fGetHwid = gethwid or (delta and delta.gethwid) or (Delta and Delta.gethwid) or function() return tostring(game:GetService("Players").LocalPlayer.UserId) end

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

local function tryMethod1(url, body)
    if not fRequest then return false, nil end
    addLog("Método 1: request() POST básico", "info")
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
    if success and response then
        if type(response) == "table" and response.Body then
            addLog("Método 1 OK", "success")
            return true, response.Body
        elseif type(response) == "string" then
            return true, response
        end
    end
    addLog("Método 1 falló", "error")
    return false, response
end

local function tryMethod2(url, body)
    if not fRequest then return false, nil end
    addLog("Método 2: request() sin headers", "info")
    local success, response = pcall(function()
        return fRequest({
            Url = url,
            Method = "POST",
            Body = body
        })
    end)
    if success and response then
        if type(response) == "table" and response.Body then
            addLog("Método 2 OK", "success")
            return true, response.Body
        elseif type(response) == "string" then
            return true, response
        end
    end
    addLog("Método 2 falló", "error")
    return false, response
end

local function tryMethod3(url, body)
    if not fRequest then return false, nil end
    addLog("Método 3: request() User-Agent iOS", "info")
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
    if success and response then
        if type(response) == "table" and response.Body then
            addLog("Método 3 OK", "success")
            return true, response.Body
        elseif type(response) == "string" then
            return true, response
        end
    end
    addLog("Método 3 falló", "error")
    return false, response
end

local function tryMethod4(url, body)
    if not fRequest then return false, nil end
    addLog("Método 4: request() User-Agent Android", "info")
    local success, response = pcall(function()
        return fRequest({
            Url = url,
            Method = "POST",
            Body = body,
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36"
            }
        })
    end)
    if success and response then
        if type(response) == "table" and response.Body then
            addLog("Método 4 OK", "success")
            return true, response.Body
        elseif type(response) == "string" then
            return true, response
        end
    end
    addLog("Método 4 falló", "error")
    return false, response
end

local function tryMethod5(url, body)
    addLog("Método 5: HttpService:PostAsync()", "info")
    local success, response = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    if success and response then
        addLog("Método 5 OK", "success")
        return true, response
    end
    addLog("Método 5 falló", "error")
    return false, response
end

local function tryMethod6(url, body)
    addLog("Método 6: HttpService:RequestAsync() POST", "info")
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
    if success and response and response.Success and response.Body then
        addLog("Método 6 OK", "success")
        return true, response.Body
    end
    addLog("Método 6 falló", "error")
    return false, response
end

local function tryMethod7(url, body)
    addLog("Método 7: game:HttpPost()", "info")
    local success, response = pcall(function()
        return game:HttpPost(url, body)
    end)
    if success and response then
        addLog("Método 7 OK", "success")
        return true, response
    end
    addLog("Método 7 falló", "error")
    return false, response
end

local function tryMethod8(url, body)
    addLog("Método 8: game:HttpPostAsync()", "info")
    local success, response = pcall(function()
        return game:HttpPostAsync(url, body)
    end)
    if success and response then
        addLog("Método 8 OK", "success")
        return true, response
    end
    addLog("Método 8 falló", "error")
    return false, response
end

local function tryMethod9(identifier)
    addLog("Método 9: game:HttpGet() con params", "info")
    for _, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format("%s/public/start?service=%d&identifier=%s", host, CONFIG.ServiceId, identifier)
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        if success and response and response ~= "" then
            addLog("Método 9 OK en " .. host, "success")
            return true, response
        end
    end
    addLog("Método 9 falló en todos los hosts", "error")
    return false, nil
end

local function tryMethod10(identifier)
    addLog("Método 10: game:HttpGetAsync() con params", "info")
    for _, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format("%s/public/start?service=%d&identifier=%s", host, CONFIG.ServiceId, identifier)
        local success, response = pcall(function()
            return game:HttpGetAsync(url)
        end)
        if success and response and response ~= "" then
            addLog("Método 10 OK en " .. host, "success")
            return true, response
        end
    end
    addLog("Método 10 falló", "error")
    return false, nil
end

local function tryMethod11(identifier)
    addLog("Método 11: HttpService:GetAsync()", "info")
    for _, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format("%s/public/start?service=%d&identifier=%s", host, CONFIG.ServiceId, identifier)
        local success, response = pcall(function()
            return HttpService:GetAsync(url, true)
        end)
        if success and response and response ~= "" then
            addLog("Método 11 OK", "success")
            return true, response
        end
    end
    addLog("Método 11 falló", "error")
    return false, nil
end

local function tryMethod12(identifier)
    addLog("Método 12: HttpService:RequestAsync() GET", "info")
    for _, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format("%s/public/start?service=%d&identifier=%s", host, CONFIG.ServiceId, identifier)
        local success, response = pcall(function()
            return HttpService:RequestAsync({
                Url = url,
                Method = "GET"
            })
        end)
        if success and response and response.Success and response.Body then
            addLog("Método 12 OK", "success")
            return true, response.Body
        end
    end
    addLog("Método 12 falló", "error")
    return false, nil
end

local function tryMethod13(identifier)
    if not fRequest then return false, nil end
    addLog("Método 13: request() GET con params", "info")
    for _, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format("%s/public/start?service=%d&identifier=%s", host, CONFIG.ServiceId, identifier)
        local success, response = pcall(function()
            return fRequest({
                Url = url,
                Method = "GET"
            })
        end)
        if success and response then
            if type(response) == "table" and response.Body then
                addLog("Método 13 OK", "success")
                return true, response.Body
            elseif type(response) == "string" then
                return true, response
            end
        end
    end
    addLog("Método 13 falló", "error")
    return false, nil
end

local function tryMethod14(identifier)
    if not fRequest then return false, nil end
    addLog("Método 14: request() GET con headers iOS", "info")
    for _, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format("%s/public/start?service=%d&identifier=%s", host, CONFIG.ServiceId, identifier)
        local success, response = pcall(function()
            return fRequest({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Mozilla/5.0 (iPad; CPU OS 16_0 like Mac OS X) AppleWebKit/605.1.15"
                }
            })
        end)
        if success and response then
            if type(response) == "table" and response.Body then
                addLog("Método 14 OK", "success")
                return true, response.Body
            elseif type(response) == "string" then
                return true, response
            end
        end
    end
    addLog("Método 14 falló", "error")
    return false, nil
end

local function generateLink()
    if cachedLink and (os.time() - cachedTime) < 600 then
        addLog("Usando link en caché", "info")
        return cachedLink
    end
    
    local identifier = generateIdentifier()
    
    addLog("=== GENERANDO ENLACE ULTRA ===", "success")
    addLog("Identifier: " .. identifier:sub(1, 16) .. "...", "info")
    addLog("fRequest disponible: " .. tostring(fRequest ~= nil), "info")
    addLog("Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"), "info")
    
    local requestBody = HttpService:JSONEncode({
        service = CONFIG.ServiceId,
        identifier = identifier
    })
    
    for hostIndex, host in ipairs(CONFIG.ApiHosts) do
        addLog("=== HOST " .. hostIndex .. "/" .. #CONFIG.ApiHosts .. ": " .. host .. " ===", "warning")
        local url = host .. "/public/start"
        
        local postMethods = {
            tryMethod1, tryMethod2, tryMethod3, tryMethod4,
            tryMethod5, tryMethod6, tryMethod7, tryMethod8
        }
        
        for i, method in ipairs(postMethods) do
            local success, responseBody = method(url, requestBody)
            if success and responseBody then
                local parseOk, data = pcall(function() return HttpService:JSONDecode(responseBody) end)
                if parseOk and data and data.success == true and data.data and data.data.url then
                    addLog("¡ÉXITO CON POST!", "success")
                    cachedLink = data.data.url
                    cachedTime = os.time()
                    return data.data.url
                end
            end
            task.wait(0.15)
        end
    end
    
    addLog("=== PROBANDO MÉTODOS GET ===", "warning")
    
    local getMethods = {
        tryMethod9, tryMethod10, tryMethod11,
        tryMethod12, tryMethod13, tryMethod14
    }
    
    for i, method in ipairs(getMethods) do
        local success, responseBody = method(identifier)
        if success and responseBody then
            local parseOk, data = pcall(function() return HttpService:JSONDecode(responseBody) end)
            if parseOk and data and data.success == true and data.data and data.data.url then
                addLog("¡ÉXITO CON GET!", "success")
                cachedLink = data.data.url
                cachedTime = os.time()
                return data.data.url
            end
        end
        task.wait(0.15)
    end
    
    addLog("=== TODOS LOS MÉTODOS FALLARON ===", "error")
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

addLog("=== SISTEMA ULTRA v5.0 ===", "success")
addLog("14 métodos | 7 hosts | POST + GET", "success")
addLog("Executor: " .. (identifyexecutor and identifyexecutor() or "Desconocido"), "info")
addLog("Platform: " .. (game:GetService("UserInputService").TouchEnabled and "Mobile/Tablet" or "PC"), "info")

local gui, generateBtn, statusLabel, linkBox = createUI()

generateBtn.MouseButton1Click:Connect(function()
    generateBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    generateBtn.Text = "Generando..."
    generateBtn.Active = false
    statusLabel.Text = "Probando 14 métodos..."
    
    addLog("▶ Usuario presionó generar", "info")
    
    task.spawn(function()
        local link = generateLink()
        
        if link then
            linkBox.Text = link
            linkBox.Visible = true
            
            if fSetClipboard then
                pcall(function()
                    fSetClipboard(link)
                    addLog("Copiado al portapapeles", "success")
                end)
            end
            
            statusLabel.Text = "✅ Enlace generado!\n\nMantén presionado para copiar"
            statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            
            generateBtn.Text = "✓ Enlace Generado"
            generateBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            
            showNotif("¡Enlace generado!", Color3.fromRGB(67, 181, 129))
        else
            statusLabel.Text = "❌ Error de conexión\n\nRevisa ventana de logs"
            statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
            generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            generateBtn.Text = "Reintentar"
            generateBtn.Active = true
            
            showNotif("Error - Ver logs", Color3.fromRGB(237, 66, 69))
        end
    end)
end)