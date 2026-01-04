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
    }
}

local httpRequest = (syn and syn.request) or http_request or (http and http.request) or request or (fluxus and fluxus.request)

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

local function generateGUID()
    local chars = "0123456789abcdef"
    local guid = ""
    
    for i = 1, 36 do
        if i == 9 or i == 14 or i == 19 or i == 24 then
            guid = guid .. "-"
        elseif i == 15 then
            guid = guid .. "4"
        elseif i == 20 then
            local rand = math.random(8, 11)
            guid = guid .. chars:sub(rand, rand)
        else
            local rand = math.random(1, 16)
            guid = guid .. chars:sub(rand, rand)
        end
    end
    
    return guid
end

local function tryHttpServiceGET(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and response then
        return true, response
    end
    return false, nil
end

local function tryHttpServicePOST(url, body)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            Body = body
        })
    end)
    
    if success and response and response.Success then
        return true, response.Body
    end
    return false, nil
end

local function tryHttpServiceJSONEncode(url, body)
    local success, response = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    
    if success and response then
        return true, response
    end
    return false, nil
end

local function tryCustomHttpRequest(url, body)
    if not httpRequest then
        return false, nil
    end
    
    local success, response = pcall(function()
        return httpRequest({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json",
                ["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15"
            },
            Body = body
        })
    end)
    
    if success and response and response.Success and response.StatusCode == 200 then
        return true, response.Body
    end
    return false, nil
end

local function tryGetFenvRequest(url, body)
    local success, response = pcall(function()
        local env = getfenv()
        local req = env.request or env.http_request or env.syn_request
        
        if not req then
            return nil
        end
        
        return req({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    end)
    
    if success and response and response.Success then
        return true, response.Body
    end
    return false, nil
end

local function tryRequestAsync(url, body)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "*/*",
                ["User-Agent"] = "Roblox/iOS"
            },
            Body = body
        })
    end)
    
    if success and response and response.Success and response.StatusCode == 200 then
        return true, response.Body
    end
    return false, nil
end

local function tryGetAsyncWithParams(host, identifier, timestamp)
    local url = string.format("%s/public/start?service=%d&identifier=%s&t=%s", 
        host, CONFIG.ServiceId, identifier, timestamp)
    
    local success, response = pcall(function()
        return game:HttpGetAsync(url)
    end)
    
    if success and response then
        return true, response
    end
    return false, nil
end

local function generateLink()
    local identifier = generateGUID()
    local timestamp = tostring(os.time())
    
    local requestBody = {
        service = CONFIG.ServiceId,
        identifier = identifier
    }
    
    local jsonBody = HttpService:JSONEncode(requestBody)
    
    print("=== INICIANDO GENERACION DE ENLACE ===")
    print("Executor: " .. (identifyexecutor and identifyexecutor() or "Desconocido"))
    print("Identifier: " .. identifier)
    print("Timestamp: " .. timestamp)
    print("HttpRequest disponible: " .. tostring(httpRequest ~= nil))
    
    local requestMethods = {
        {name = "HttpService:RequestAsync (POST)", func = tryHttpServicePOST},
        {name = "HttpService:PostAsync (JSON)", func = tryHttpServiceJSONEncode},
        {name = "Custom http_request", func = tryCustomHttpRequest},
        {name = "GetFenv Request", func = tryGetFenvRequest},
        {name = "RequestAsync (iOS)", func = tryRequestAsync},
        {name = "HttpGet con params", func = tryGetAsyncWithParams}
    }
    
    for hostIndex, host in ipairs(CONFIG.ApiHosts) do
        print("\n--- Probando HOST " .. hostIndex .. ": " .. host .. " ---")
        
        for methodIndex, method in ipairs(requestMethods) do
            print("  Método " .. methodIndex .. ": " .. method.name)
            
            local url = host .. "/public/start?t=" .. timestamp
            local success, responseBody
            
            if method.name == "HttpGet con params" then
                success, responseBody = method.func(host, identifier, timestamp)
            else
                success, responseBody = method.func(url, jsonBody)
            end
            
            if success and responseBody then
                print("  ✓ Respuesta recibida")
                
                local decodeSuccess, data = pcall(function()
                    return HttpService:JSONDecode(responseBody)
                end)
                
                if decodeSuccess and data then
                    print("  ✓ JSON parseado")
                    
                    if data.success and data.data and data.data.url then
                        print("  ✓✓✓ ENLACE OBTENIDO EXITOSAMENTE ✓✓✓")
                        print("  URL: " .. data.data.url)
                        return data.data.url
                    else
                        print("  ✗ Respuesta sin URL válida")
                    end
                else
                    print("  ✗ Error al parsear JSON")
                end
            else
                print("  ✗ Falló")
            end
            
            task.wait(0.2)
        end
        
        task.wait(0.3)
    end
    
    print("\n=== ERROR: NO SE PUDO GENERAR ENLACE ===")
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

print("=== GENERADOR DE ENLACES INICIADO ===")
print("Script optimizado para Delta Executor y iPhone")

local gui, generateBtn, statusLabel, linkBox = createUI()

generateBtn.MouseButton1Click:Connect(function()
    generateBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    generateBtn.Text = "Generando..."
    generateBtn.Active = false
    statusLabel.Text = "Probando métodos de conexión..."
    
    task.spawn(function()
        local link = generateLink()
        
        if link then
            linkBox.Text = link
            linkBox.Visible = true
            
            statusLabel.Text = "✅ Enlace generado exitosamente!\n\nMantén presionado para copiar"
            statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            
            generateBtn.Text = "✓ Enlace Generado"
            generateBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            
            showNotif("¡Enlace generado!", Color3.fromRGB(67, 181, 129))
        else
            statusLabel.Text = "❌ No se pudo generar\n\nRevisa Output/Consola para detalles"
            statusLabel.TextColor3 = Color3.fromRGB(237, 66, 69)
            generateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            generateBtn.Text = "Reintentar"
            generateBtn.Active = true
            
            showNotif("Error - Ver consola", Color3.fromRGB(237, 66, 69))
        end
    end)
end)