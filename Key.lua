local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    ServiceId = 1951,
    ApiHosts = {
        "https://api.platoboost.app",
        "https://api.platoboost.net",
        "https://api.platoboost.com"
    },
    KeyDuration = 1200
}

local currentSession = nil

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 450, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ZIndex = 0
    shadow.Parent = mainFrame
    
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 15)
    headerCorner.Parent = header
    
    local headerBottom = Instance.new("Frame")
    headerBottom.Size = UDim2.new(1, 0, 0, 15)
    headerBottom.Position = UDim2.new(0, 0, 1, -15)
    headerBottom.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    headerBottom.BorderSizePixel = 0
    headerBottom.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔑 Sistema de Verificación"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -45, 0, 15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -40, 0, 60)
    statusLabel.Position = UDim2.new(0, 20, 0, 80)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Paso 1: Haz clic en 'Generar Enlace'\nPaso 2: Completa las tareas\nPaso 3: Ingresa la key que recibiste"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextWrapped = true
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Parent = mainFrame
    
    local generateBtn = Instance.new("TextButton")
    generateBtn.Name = "GenerateBtn"
    generateBtn.Size = UDim2.new(1, -40, 0, 50)
    generateBtn.Position = UDim2.new(0, 20, 0, 160)
    generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    generateBtn.Text = "🔗 Generar Enlace de Verificación"
    generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    generateBtn.TextSize = 15
    generateBtn.Font = Enum.Font.GothamBold
    generateBtn.AutoButtonColor = false
    generateBtn.Parent = mainFrame
    
    local genBtnCorner = Instance.new("UICorner")
    genBtnCorner.CornerRadius = UDim.new(0, 10)
    genBtnCorner.Parent = generateBtn
    
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, -40, 0, 50)
    keyInput.Position = UDim2.new(0, 20, 0, 220)
    keyInput.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    keyInput.PlaceholderText = "Pega tu key aquí..."
    keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    keyInput.Text = ""
    keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.TextSize = 14
    keyInput.Font = Enum.Font.Gotham
    keyInput.ClearTextOnFocus = false
    keyInput.Visible = false
    keyInput.Parent = mainFrame
    
    local keyInputCorner = Instance.new("UICorner")
    keyInputCorner.CornerRadius = UDim.new(0, 10)
    keyInputCorner.Parent = keyInput
    
    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Name = "VerifyBtn"
    verifyBtn.Size = UDim2.new(1, -40, 0, 50)
    verifyBtn.Position = UDim2.new(0, 20, 0, 280)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
    verifyBtn.Text = "✓ Verificar Key"
    verifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    verifyBtn.TextSize = 15
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.AutoButtonColor = false
    verifyBtn.Visible = false
    verifyBtn.Parent = mainFrame
    
    local verifyBtnCorner = Instance.new("UICorner")
    verifyBtnCorner.CornerRadius = UDim.new(0, 10)
    verifyBtnCorner.Parent = verifyBtn
    
    screenGui.Parent = playerGui
    
    return screenGui, generateBtn, keyInput, verifyBtn, statusLabel, closeBtn
end

local function generateGUID()
    return HttpService:GenerateGUID(false)
end

local function generateLink()
    local identifier = generateGUID()
    local timestamp = tostring(os.time())
    
    for _, host in ipairs(CONFIG.ApiHosts) do
        local success, response = pcall(function()
            return HttpService:RequestAsync({
                Url = host .. "/public/start?t=" .. timestamp,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    service = CONFIG.ServiceId,
                    identifier = identifier
                })
            })
        end)
        
        if success and response.Success then
            local data = HttpService:JSONDecode(response.Body)
            if data.success then
                currentSession = {
                    identifier = identifier,
                    url = data.data.url,
                    timestamp = os.time(),
                    expiry = os.time() + CONFIG.KeyDuration
                }
                return data.data.url
            end
        end
    end
    
    return nil
end

local function verifyKey(key)
    if not currentSession then
        return false, "No hay sesión activa"
    end
    
    if os.time() > currentSession.expiry then
        currentSession = nil
        return false, "Sesión expirada. Genera un nuevo enlace"
    end
    
    local nonce = tostring(os.time())
    
    for _, host in ipairs(CONFIG.ApiHosts) do
        local url = string.format(
            "%s/public/whitelist/%d?identifier=%s&key=%s&nonce=%s",
            host,
            CONFIG.ServiceId,
            HttpService:UrlEncode(currentSession.identifier),
            HttpService:UrlEncode(key),
            nonce
        )
        
        local success, response = pcall(function()
            return HttpService:RequestAsync({
                Url = url,
                Method = "GET"
            })
        end)
        
        if success and response.Success then
            local data = HttpService:JSONDecode(response.Body)
            if data.success and data.data.valid == true then
                return true, "Key verificada correctamente"
            end
        end
    end
    
    return false, "Key inválida o expirada"
end

local function showNotification(text, color)
    local gui = Instance.new("ScreenGui")
    gui.Name = "Notification"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0, -70)
    frame.BackgroundColor3 = color or Color3.fromRGB(88, 101, 242)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextWrapped = true
    label.Parent = frame
    
    gui.Parent = playerGui
    
    frame:TweenPosition(UDim2.new(0.5, -150, 0, 20), "Out", "Quad", 0.3, true)
    
    wait(3)
    
    frame:TweenPosition(UDim2.new(0.5, -150, 0, -70), "In", "Quad", 0.3, true)
    wait(0.3)
    gui:Destroy()
end

local gui, generateBtn, keyInput, verifyBtn, statusLabel, closeBtn = createUI()

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

generateBtn.MouseButton1Click:Connect(function()
    generateBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    statusLabel.Text = "⏳ Generando enlace seguro..."
    
    wait(0.5)
    
    local link = generateLink()
    
    if link then
        pcall(function()
            setclipboard(link)
        end)
        
        statusLabel.Text = "✅ Enlace generado y copiado al portapapeles\n\nCompleta las tareas en la página que se abrió\ny luego ingresa la key que recibiste"
        statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
        
        generateBtn.Visible = false
        keyInput.Visible = true
        verifyBtn.Visible = true
        
        showNotification("Enlace copiado! Abre tu navegador", Color3.fromRGB(67, 181, 129))
    else
        statusLabel.Text = "❌ Error al generar enlace\nIntenta nuevamente"
        statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
        generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        showNotification("Error de conexión", Color3.fromRGB(237, 66, 69))
    end
end)

verifyBtn.MouseButton1Click:Connect(function()
    local key = keyInput.Text
    
    if key == "" then
        showNotification("Ingresa una key primero", Color3.fromRGB(255, 165, 0))
        return
    end
    
    verifyBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 100)
    statusLabel.Text = "⏳ Verificando key..."
    
    wait(0.5)
    
    local valid, message = verifyKey(key)
    
    if valid then
        statusLabel.Text = "✅ " .. message
        statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
        showNotification("Verificación exitosa!", Color3.fromRGB(67, 181, 129))
        
        wait(1)
        gui:Destroy()
        
        print("KEY VERIFICADA - EJECUTANDO SCRIPT PRINCIPAL")
        
    else
        statusLabel.Text = "❌ " .. message
        statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
        verifyBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
        showNotification(message, Color3.fromRGB(237, 66, 69))
    end
end)

print("Sistema de Keys iniciado correctamente")