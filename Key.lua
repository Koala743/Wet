local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local SERVICE_ID = 16251
local MAX_RETRIES = 5
local HOSTS = {
    "https://api.platoboost.com/",
    "https://api.platoboost.net/",
    "https://api.platoboost.app/",
    "https://gateway.platoboost.com/",
    "https://gateway.platoboost.net/"
}
local function getRequestFunc()
    local funcs = {
        http_request, request, HttpRequest,
        syn and syn.request,
        http and http.request,
        fluxus and fluxus.request,
        krnl and krnl.request,
        Delta and Delta.request
    }
    for _, func in ipairs(funcs) do
        if func then return func end
    end
    return function(opts)
        local ok, res = pcall(function()
            if opts.Method == "GET" then
                return {StatusCode = 200, Body = HttpService:GetAsync(opts.Url)}
            else
                return {StatusCode = 200, Body = HttpService:PostAsync(opts.Url, opts.Body, Enum.HttpContentType.ApplicationJson)}
            end
        end)
        if ok then return res end
        return {StatusCode = 500, Body = '{"success":false,"message":"Request failed"}'}
    end
end
local requestFunc = getRequestFunc()
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end
local function getHwid()
    if gethwid then
        local ok, hwid = pcall(gethwid)
        if ok then return tostring(hwid) end
    end
    return tostring(Players.LocalPlayer.UserId)
end
local function generateNonce()
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local nonce = ""
    for i = 1, 16 do
        nonce = nonce .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return nonce
end
local function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = ((hash * 31) + string.byte(str, i)) % 4294967296
    end
    return string.format("%x", hash)
end
local function makeRequest(url, method, body, retries)
    retries = retries or MAX_RETRIES
    for attempt = 1, retries do
        local success, result = pcall(function()
            local options = {
                Url = url,
                Method = method or "GET",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "Roblox/Platoboost/v3.0",
                    ["Accept"] = "application/json"
                }
            }
            if body then
                options.Body = HttpService:JSONEncode(body)
            end
            return requestFunc(options)
        end)
        if success and result then
            if result.StatusCode == 200 then
                return result, nil
            elseif result.StatusCode == 429 then
                return nil, "Rate limited - Espera 30 segundos"
            end
        end
        if attempt < retries then
            task.wait(math.min(attempt * 0.8, 3))
        end
    end
    return nil, "Sin respuesta del servidor"
end
local function testHost(host)
    local endpoints = {"public/connectivity", "health", "ping"}
    for _, endpoint in ipairs(endpoints) do
        local result = makeRequest(host .. endpoint, "GET", nil, 1)
        if result then
            return true
        end
        task.wait(0.2)
    end
    return false
end
local function findWorkingHost()
    local workingHosts = {}
    for _, host in ipairs(HOSTS) do
        if testHost(host) then
            table.insert(workingHosts, host)
        end
    end
    if #workingHosts > 0 then
        return workingHosts[1]
    end
    return nil
end
local function generateLinkDirect(host)
    local hwid = getHwid()
    local timestamp = tostring(os.time())
    local nonce = generateNonce()
    local identifier = simpleHash(hwid .. timestamp)
    local bodyVariants = {
        {
            service = SERVICE_ID,
            identifier = identifier,
            timestamp = tonumber(timestamp),
            nonce = nonce
        },
        {
            service = SERVICE_ID,
            identifier = hwid,
            nonce = nonce
        },
        {
            service = SERVICE_ID,
            hwid = hwid,
            identifier = identifier
        }
    }
    local endpoints = {"public/start", "v1/start", "api/start", "start"}
    for _, body in ipairs(bodyVariants) do
        for _, endpoint in ipairs(endpoints) do
            local url = host .. endpoint
            local response, err = makeRequest(url, "POST", body, 2)
            if response and response.Body then
                local ok, data = pcall(function()
                    return HttpService:JSONDecode(response.Body)
                end)
                if ok and data then
                    if data.success and data.data and data.data.url then
                        return data.data.url, nil
                    elseif data.url then
                        return data.url, nil
                    elseif data.link then
                        return data.link, nil
                    end
                end
            end
            task.wait(0.3)
        end
    end
    return nil, "No se pudo generar el link"
end
local function generateLink()
    notify("🔍 Diagnóstico", "Probando " .. #HOSTS .. " servidores...", 3)
    local host = findWorkingHost()
    if not host then
        notify("❌ Error Fatal", "Todos los servidores están caídos", 8)
        return nil, "Sin servidores disponibles"
    end
    notify("✅ Servidor OK", "Generando link...", 3)
    local link, err = generateLinkDirect(host)
    if link then
        local clipSuccess = pcall(function()
            if setclipboard then
                setclipboard(link)
            elseif toclipboard then
                toclipboard(link)
            end
        end)
        if clipSuccess then
            notify("✅ ¡ÉXITO!", "Link copiado al portapapeles", 5)
        else
            notify("✅ Link generado", link:sub(1, 35) .. "...", 8)
        end
        return link, nil
    else
        notify("❌ Error", err or "Fallo al generar link", 6)
        return nil, err
    end
end
local function createUI()
    if game.CoreGui:FindFirstChild("PlatoGen") then
        game.CoreGui.PlatoGen:Destroy()
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "PlatoGen"
    sg.Parent = game.CoreGui
    sg.ResetOnSpawn = false
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 320, 0, 180)
    f.Position = UDim2.new(0.5, -160, 0.5, -90)
    f.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    f.BorderSizePixel = 0
    f.Parent = sg
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(0, 15)
    c1.Parent = f
    local s = Instance.new("UIStroke")
    s.Thickness = 2
    s.Color = Color3.fromRGB(100, 50, 200)
    s.Parent = f
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, 35)
    t.Position = UDim2.new(0, 10, 0, 10)
    t.Text = "🔗 GENERADOR PLATOBOOST"
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextSize = 15
    t.Parent = f
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -20, 0, 25)
    info.Position = UDim2.new(0, 10, 0, 45)
    info.Text = "Service: " .. SERVICE_ID .. " | Hosts: " .. #HOSTS
    info.TextColor3 = Color3.fromRGB(150, 150, 150)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Gotham
    info.TextSize = 11
    info.Parent = f
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 30)
    status.Position = UDim2.new(0, 10, 0, 75)
    status.Text = "💡 Presiona el botón para generar"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextWrapped = true
    status.Parent = f
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 45)
    btn.Position = UDim2.new(0.075, 0, 0, 115)
    btn.Text = "🚀 GENERAR LINK"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    btn.Parent = f
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 12)
    c2.Parent = btn
    btn.MouseButton1Click:Connect(function()
        btn.Text = "⏳ GENERANDO..."
        btn.BackgroundColor3 = Color3.fromRGB(70, 35, 140)
        status.Text = "🔄 Procesando solicitud..."
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
        task.spawn(function()
            local link, err = generateLink()
            task.wait(1.5)
            btn.Text = "🚀 GENERAR LINK"
            btn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
            if link then
                status.Text = "✅ Link generado exitosamente"
                status.TextColor3 = Color3.fromRGB(100, 255, 100)
            else
                status.Text = "❌ " .. (err or "Error desconocido")
                status.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
            task.wait(3)
            status.Text = "💡 Presiona el botón para generar"
            status.TextColor3 = Color3.fromRGB(200, 200, 200)
        end)
    end)
end
createUI()
notify("✅ Sistema Cargado", "Generador de links listo", 4)