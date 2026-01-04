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
    KeyDuration = 1200
}

local currentSession = nil

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
    
    local retryBtn = Instance.new("TextButton")
    retryBtn.Name = "RetryBtn"
    retryBtn.Size = UDim2.new(1, -20, 0, 35)
    retryBtn.Position = UDim2.new(0, 10, 0, 295)
    retryBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    retryBtn.Text = "Reintentar Conexión"
    retryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    retryBtn.TextSize = 13
    retryBtn.Font = Enum.Font.GothamBold
    retryBtn.AutoButtonColor = false
    retryBtn.Visible = false
    retryBtn.Parent = mainFrame
    
    local retryBtnCorner = Instance.new("UICorner")
    retryBtnCorner.CornerRadius = UDim.new(0, 8)
    retryBtnCorner.Parent = retryBtn
    
    screenGui.Parent = playerGui
    
    return screenGui, generateBtn, keyInput, verifyBtn, statusLabel, linkBox, retryBtn
end

local function generateGUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
end

local function safeRequest(url, method, body, timeout)
    timeout = timeout or 10
    local completed = false
    local result = nil
    
    task.spawn(function()
        local success, response = pcall(function()
            return game:HttpGet(url, true)
        end)
        
        if success then
            result = {Success = true, Body = response, StatusCode = 200}
        else
            result = {Success = false, StatusCode = 0}
        end
        completed = true
    end)
    
    local startTime = tick()
    while not completed and (tick() - startTime) < timeout do
        task.wait(0.1)
    end
    
    return result
end

local function generateLink()
    local identifier = generateGUID()
    local timestamp = tostring(os.time())
    
    for i, host in ipairs(CONFIG.ApiHosts) do
        local url = host .. "/public/start?t=" .. timestamp
        
        local success, response = pcall(function()
            return HttpService:JSONEncode({
                service = CONFIG.ServiceId,
                identifier = identifier
            })
        end)
        
        if not success then
            continue
        end
        
        local requestBody = response
        local fullUrl = url
        
        local reqSuccess, reqResponse = pcall(function()
            return HttpService:PostAsync(fullUrl, requestBody, Enum.HttpContentType.ApplicationJson, false)
        end)
        
        if reqSuccess and reqResponse then
            local parseSuccess, data = pcall(function()
                return HttpService:JSONDecode(reqResponse)
            end)
            
            if parseSuccess and data and data.success and data.data and data.data.url then
                currentSession = {
                    identifier = identifier,
                    url = data.data.url,
                    timestamp = os.time(),
                    expiry = os.time() + CONFIG.KeyDuration
                }
                return data.data.url
            end
        end
        
        if i < #CONFIG.ApiHosts then
            task.wait(2)
        end
    end
    
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
    
    for i, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format(
            "%s/public/whitelist/%d?identifier=%s&key=%s&nonce=%s",
            host,
            CONFIG.ServiceId,
            HttpService:UrlEncode(currentSession.identifier),
            HttpService:UrlEncode(key),
            nonce
        )
        
        local success, response = pcall(function()
            return HttpService:GetAsync(url, false)
        end)
        
        if success and response then
            local parseSuccess, data = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            
            if parseSuccess and data and data.success and data.data and data.data.valid == true then
                return true, "Key válida"
            end
        end
        
        if i < #CONFIG.ApiHosts then
            task.wait(2)
        end
    end
    
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

local gui, generateBtn, keyInput, verifyBtn, statusLabel, linkBox, retryBtn = createUI()

local function attemptGenerate()
    generateBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    generateBtn.Text = "Generando..."
    statusLabel.Text = "Conectando al servidor...\nEsto puede tardar un momento"
    retryBtn.Visible = false
    
    task.spawn(function()
        task.wait(0.5)
        
        local link = generateLink()
        
        if link then
            linkBox.Text = link
            linkBox.Visible = true
            
            statusLabel.Text = "✅ Enlace generado!\n\nMantén presionado el enlace\npara copiarlo y ábrelo en Safari"
            statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            
            generateBtn.Visible = false
            keyInput.Visible = true
            verifyBtn.Visible = true
            
            showNotif("Mantén presionado para copiar", Color3.fromRGB(67, 181, 129))
        else
            statusLabel.Text = "❌ Error de conexión\n\nPosibles causas:\n- Internet inestable\n- Límite de solicitudes\n- Servidor ocupado"
            statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
            generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            generateBtn.Text = "Obtener Key"
            retryBtn.Visible = true
            showNotif("Error. Espera 30s y reintenta", Color3.fromRGB(237, 66, 69))
        end
    end)
end

generateBtn.MouseButton1Click:Connect(attemptGenerate)

retryBtn.MouseButton1Click:Connect(function()
    retryBtn.Visible = false
    attemptGenerate()
end)

verifyBtn.MouseButton1Click:Connect(function()
    local key = keyInput.Text:gsub("%s+", "")
    
    if key == "" then
        showNotif("Ingresa una key", Color3.fromRGB(255, 165, 0))
        return
    end
    
    verifyBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 100)
    verifyBtn.Text = "Verificando..."
    statusLabel.Text = "Verificando key...\nEspera un momento"
    
    task.spawn(function()
        task.wait(0.5)
        
        local valid, message = verifyKey(key)
        
        if valid then
            statusLabel.Text = "✅ " .. message
            statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            showNotif("¡Verificado!", Color3.fromRGB(67, 181, 129))
            
            task.wait(1.5)
            gui:Destroy()
            
            print("KEY VERIFICADA - EJECUTANDO SCRIPT")
            
        else
            statusLabel.Text = "❌ " .. message .. "\n\nVerifica que copiaste\nla key completa"
            statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
            verifyBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            verifyBtn.Text = "Verificar"
            showNotif(message, Color3.fromRGB(237, 66, 69))
        end
    end)
end)

print("Sistema de Keys iniciado")