local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

local SERVICE_ID = 16251
local SERVICE_NAME = "10 Horas"
local PLATOBOOST_HOSTS = {"https://api.platoboost.com/", "https://api.platoboost.net/", "https://api.platoboost.app/"}

local requestFunc = http_request or request or HttpRequest or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)

local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
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

local universalHwid = generateRandomIdentifier()

local function makeRequest(url, method, body)
    local options = {
        Url = url,
        Method = method or "GET",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = body and HttpService:JSONEncode(body) or nil
    }
    
    local success, result = pcall(function()
        return requestFunc(options)
    end)
    
    if success and result then
        return result
    end
    return nil
end

local function testHost()
    for _, host in ipairs(PLATOBOOST_HOSTS) do
        local res = makeRequest(host .. "public/connectivity", "GET")
        if res and res.StatusCode == 200 then
            return host
        end
    end
    return nil
end

local function generateLink()
    notify("🔗 Generando", "Creando enlace...", 3)
    
    local host = testHost()
    if not host then
        notify("❌ Error", "No hay conexión a servidores", 5)
        return nil
    end
    
    local body = {
        service = SERVICE_ID,
        identifier = universalHwid
    }
    
    local res = makeRequest(host .. "public/start", "POST", body)
    
    if res and res.StatusCode == 200 and res.Body then
        local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok and data.success and data.data and data.data.url then
            notify("✅ Link Generado", "Copiado al portapapeles", 5)
            if setclipboard then
                setclipboard(data.data.url)
            end
            print("LINK GENERADO:", data.data.url)
            return data.data.url
        end
    end
    
    notify("❌ Error", "No se pudo generar el link", 5)
    return nil
end

local function verifyKey(key)
    notify("⏳ Verificando", "Comprobando clave...", 3)
    
    local host = testHost()
    if not host then
        notify("❌ Error", "No hay conexión a servidores", 5)
        return false
    end
    
    local endpoint = string.format("public/whitelist/%d?identifier=%s&key=%s",
        SERVICE_ID,
        HttpService:URLEncode(universalHwid),
        HttpService:URLEncode(key))
    
    local res = makeRequest(host .. endpoint, "GET")
    
    if res and res.StatusCode == 200 and res.Body then
        local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok and data.success and data.data and data.data.valid then
            notify("✅ Verificado", "Clave válida!", 5)
            print("CLAVE VÁLIDA!")
            return true
        end
    end
    
    notify("❌ Inválida", "Clave incorrecta", 5)
    return false
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
        notify("⚠️ Error", "Ingresa una clave primero", 3)
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

notify("🚀 Sistema Iniciado", "Mini Key System Test cargado", 4)
print("=== MINI KEY SYSTEM TEST ===")
print("HWID:", universalHwid)
print("Service ID:", SERVICE_ID)