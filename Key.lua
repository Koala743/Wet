local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
    ServiceId = 1951,
    ApiHosts = {
        "https://api.platoboost.com",
        "https://api.platoboost.net",
        "https://api.platoboost.app"
    }
}

local cachedLink = nil
local cachedTime = 0

repeat task.wait(0.5) until game:IsLoaded()

local function getIdentifier()
    local hwid = gethwid and gethwid() or tostring(player.UserId)
    return hwid
end

local function generateLink()
    if cachedLink and (os.time() - cachedTime) < 600 then
        return cachedLink
    end
    
    local identifier = getIdentifier()
    
    for _, host in ipairs(CONFIG.ApiHosts) do
        local url = host .. "/public/start"
        
        local success, result = pcall(function()
            local payload = HttpService:JSONEncode({
                service = CONFIG.ServiceId,
                identifier = identifier
            })
            
            local response = http_request({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = payload
            })
            
            return response
        end)
        
        if success and result then
            if result.StatusCode == 200 and result.Body then
                local parseOk, data = pcall(function()
                    return HttpService:JSONDecode(result.Body)
                end)
                
                if parseOk and data and data.success and data.data and data.data.url then
                    cachedLink = data.data.url
                    cachedTime = os.time()
                    return data.data.url
                end
            end
        end
        
        task.wait(0.3)
    end
    
    return nil
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KeySystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 200)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -100)
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
StatusLabel.Size = UDim2.new(1, -20, 0, 35)
StatusLabel.Position = UDim2.new(0, 10, 0, 55)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Presiona el botón para generar tu enlace"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
StatusLabel.TextWrapped = true
StatusLabel.Parent = MainFrame

local LinkBox = Instance.new("TextBox")
LinkBox.Size = UDim2.new(1, -20, 0, 50)
LinkBox.Position = UDim2.new(0, 10, 0, 100)
LinkBox.BackgroundColor3 = Color3.fromRGB(40, 43, 48)
LinkBox.BorderSizePixel = 0
LinkBox.Text = ""
LinkBox.PlaceholderText = "El enlace aparecerá aquí..."
LinkBox.Font = Enum.Font.Gotham
LinkBox.TextSize = 10
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
LinkBoxPadding.PaddingLeft = UDim.new(0, 8)
LinkBoxPadding.PaddingRight = UDim.new(0, 8)
LinkBoxPadding.PaddingTop = UDim.new(0, 8)
LinkBoxPadding.PaddingBottom = UDim.new(0, 8)
LinkBoxPadding.Parent = LinkBox

local GenerateButton = Instance.new("TextButton")
GenerateButton.Size = UDim2.new(1, -20, 0, 40)
GenerateButton.Position = UDim2.new(0, 10, 0, 150)
GenerateButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
GenerateButton.BorderSizePixel = 0
GenerateButton.Text = "Generar Enlace"
GenerateButton.Font = Enum.Font.GothamBold
GenerateButton.TextSize = 14
GenerateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GenerateButton.AutoButtonColor = false
GenerateButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = GenerateButton

GenerateButton.MouseButton1Click:Connect(function()
    GenerateButton.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    GenerateButton.Text = "Generando..."
    StatusLabel.Text = "Conectando al servidor..."
    
    task.spawn(function()
        local link = generateLink()
        
        if link then
            LinkBox.Text = link
            LinkBox.Visible = true
            
            if setclipboard then
                pcall(function()
                    setclipboard(link)
                end)
            end
            
            StatusLabel.Text = "✅ Enlace generado y copiado"
            StatusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            GenerateButton.Text = "✓ Generado"
            GenerateButton.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
        else
            StatusLabel.Text = "❌ Error al generar enlace\nIntenta de nuevo"
            StatusLabel.TextColor3 = Color3.fromRGB(240, 71, 71)
            GenerateButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            GenerateButton.Text = "Reintentar"
        end
    end)
end)