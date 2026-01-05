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
    },
    Timeout = 15,
    MaxRetries = 3
}

local cachedLink = nil
local cachedTime = 0

repeat task.wait(0.5) until game:IsLoaded()

-- Detectar la función de request correcta
local requestFunction = (
    http_request or 
    request or 
    (syn and syn.request) or
    (http and http.request) or
    (game and game.HttpGet)
)

local function getIdentifier()
    local success, hwid = pcall(function()
        return gethwid and gethwid() or nil
    end)
    
    if success and hwid then
        return tostring(hwid)
    end
    
    -- Fallback a UserId + JobId para más unicidad
    return tostring(player.UserId) .. "_" .. tostring(game.JobId):sub(1, 8)
end

local function makeRequest(url, payload, attempt)
    attempt = attempt or 1
    
    if not requestFunction then
        return false, "No se encontró función de request compatible"
    end
    
    local success, result = pcall(function()
        local response = requestFunction({
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
        
        return response
    end)
    
    if not success then
        -- Retry con backoff exponencial
        if attempt < CONFIG.MaxRetries then
            task.wait(math.pow(2, attempt - 1))
            return makeRequest(url, payload, attempt + 1)
        end
        return false, result
    end
    
    return true, result
end

local function generateLink()
    -- Verificar cache
    if cachedLink and (os.time() - cachedTime) < 600 then
        return cachedLink, "cached"
    end
    
    local identifier = getIdentifier()
    
    local payload = HttpService:JSONEncode({
        service = CONFIG.ServiceId,
        identifier = identifier
    })
    
    -- Intentar con cada host
    for hostIndex, host in ipairs(CONFIG.ApiHosts) do
        local url = host .. "/public/start"
        
        local success, result = makeRequest(url, payload)
        
        if success and result then
            -- Verificar status code
            if result.StatusCode == 200 or result.StatusCode == 201 then
                if result.Body and result.Body ~= "" then
                    local parseOk, data = pcall(function()
                        return HttpService:JSONDecode(result.Body)
                    end)
                    
                    if parseOk and data then
                        if data.success and data.data and data.data.url then
                            cachedLink = data.data.url
                            cachedTime = os.time()
                            return data.data.url, "success"
                        elseif data.message then
                            -- API retornó error con mensaje
                            return nil, data.message
                        end
                    end
                end
            elseif result.StatusCode == 429 then
                return nil, "Rate limit - Espera 30 segundos"
            elseif result.StatusCode >= 500 then
                -- Error del servidor, intentar siguiente host
                if hostIndex < #CONFIG.ApiHosts then
                    task.wait(1)
                    continue
                end
            end
        end
        
        -- Pequeña espera entre hosts
        if hostIndex < #CONFIG.ApiHosts then
            task.wait(0.5)
        end
    end
    
    return nil, "No se pudo conectar a ningún servidor"
end

-- UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KeySystem"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 220)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -110)
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
StatusLabel.Text = "Presiona el botón para generar tu enlace"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = MainFrame

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
GenerateButton.Position = UDim2.new(0, 10, 0, 170)
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

local isGenerating = false

GenerateButton.MouseButton1Click:Connect(function()
    if isGenerating then return end
    
    isGenerating = true
    GenerateButton.BackgroundColor3 = Color3.fromRGB(70, 80, 200)
    GenerateButton.Text = "Generando..."
    StatusLabel.Text = "🔄 Conectando al servidor Platoboost...\nPor favor espera"
    StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
    LinkBox.Visible = false
    
    task.spawn(function()
        local link, status = generateLink()
        
        task.wait(0.5) -- Pequeña espera visual
        
        if link then
            LinkBox.Text = link
            LinkBox.Visible = true
            
            -- Intentar copiar al portapapeles
            local clipboardSuccess = false
            if setclipboard then
                clipboardSuccess = pcall(function()
                    setclipboard(link)
                end)
            end
            
            if status == "cached" then
                StatusLabel.Text = "✅ Enlace recuperado del caché\n" .. (clipboardSuccess and "Copiado al portapapeles" or "")
            else
                StatusLabel.Text = "✅ Enlace generado correctamente\n" .. (clipboardSuccess and "Copiado al portapapeles" or "Copia manualmente")
            end
            
            StatusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
            GenerateButton.Text = "✓ Generado"
            GenerateButton.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
            
            -- Reset después de 5 segundos
            task.delay(5, function()
                if GenerateButton then
                    GenerateButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                    GenerateButton.Text = "Generar Nuevo"
                    isGenerating = false
                end
            end)
        else
            StatusLabel.Text = "❌ " .. (status or "Error desconocido") .. "\nVerifica tu conexión"
            StatusLabel.TextColor3 = Color3.fromRGB(240, 71, 71)
            GenerateButton.BackgroundColor3 = Color3.fromRGB(240, 71, 71)
            GenerateButton.Text = "Reintentar"
            
            task.delay(3, function()
                if GenerateButton then
                    GenerateButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                    GenerateButton.Text = "Generar Enlace"
                    StatusLabel.Text = "Presiona el botón para generar tu enlace"
                    StatusLabel.TextColor3 = Color3.fromRGB(220, 221, 222)
                    isGenerating = false
                end
            end)
        end
    end)
end)

-- Debug info (puedes eliminar esto en producción)
print("🔑 Key System cargado")
print("Executor detectado: " .. (identifyexecutor and identifyexecutor() or "Desconocido"))
print("Request function: " .. (requestFunction and "✓ Encontrada" or "✗ No encontrada"))