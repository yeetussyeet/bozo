--# selene:allow(if_same_then_else,multiple_statements,parenthese_conditions)

local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
-- Modules

local Optipost = require(script.Optipost)

-- Config

local DefaultConfig = {
    -- Target URL
    URL = "http://127.0.0.1:3000/rocontrol",
}

-- Code

local ut = {}

ut.uuid = game:GetService("HttpService"):GenerateGUID(false)

ut.UsingModernChat = game:GetService("TextChatService").ChatVersion == Enum.ChatVersion.TextChatService

if ut.UsingModernChat then
    if not script:FindFirstChild("chathandle") then
        warn("WARNING: Discord to Roblox chat has been disabled. Please add a localscript named \"chathandle\" to the RoControl module, and insert the contents of chathandle.lua to re-enable support for modern chat.")
    else
        script.chathandle:SetAttribute("id",ut.uuid)
    end

    ut.ChatRemoteEvent = Instance.new("RemoteEvent",game:GetService("ReplicatedStorage"))
    ut.ChatRemoteEvent.Name = ut.uuid
else
    ut.ChatService = require(
        game:GetService("ServerScriptService")
            :WaitForChild("ChatServiceRunner",5)
            :WaitForChild("ChatService",5)
    )
    
    ut.Speaker = ut.ChatService:AddSpeaker("RoControl")
    ut.Speaker:JoinChannel("All")
end

-- ut.YieldGet

function ut.YieldGet(session,data,callbackName)
    -- Bad method of doing this but I don't wanna use promise api for now
    if not session then error("Cannot RF when Session is nil.") end
    local d
    local got
    local key = data.key or tostring(math.random())
    local a = session.onmessage:Connect(function(s)
        if s.type == callbackName and s.key == key then
            d = s.data
            got = true
        end
    end)

    local realData = {
        key=key
    }

    for x,v in pairs(data) do
        realData[x] = v
    end

    session:Send(realData)
    repeat task.wait() until got

    a:Disconnect()

    return d
end

-- ut commands

ut.commands = {
    commands = {},
    Session = nil
}

function ut.commands:addCommand(id,commandAliases,desc,args_amt,action,roleid)
    if not self.Session then error("Cannot addCommand when Session is nil.") end

    ut.commands.commands[id] = action

    self.Session:Send({
        type = "RegisterCommand",
        names = commandAliases,
        id = id,
        args_amt = args_amt,
        desc=desc,
        roleid=roleid
    })
end

-- ut.server

ut.server = {
    Session = nil
}

function ut.server:ProcessImage(url)
    if not self.Session then error("Cannot ProcessImage when Session is nil.") end
    if not url then error("Cannot ProcessImage when no URL is passed.") end
    return ut.YieldGet(self.Session,{
        type = "ProcessImage",
        url=url
    },"ProcessedImage")
end

function ut.server:Get(url)
    if not self.Session then error("Cannot Get when Session is nil.") end
    if not url then error("Cannot Get when no URL is passed.") end
    return ut.YieldGet(self.Session,{
        type = "HttpGet",
        url=url
    },"GotHttp")
end

function ut.server:Eval(url)
    if not self.Session then error("Cannot Eval when Session is nil.") end
    if not url then error("Cannot Get when no URL is passed.") end
    return ut.YieldGet(self.Session,{
        type = "HttpGet",
        url=url
    },"GotHttp")
end

function ut.server:Glot(name,data)
    if not self.Session then error("Cannot Glot when Session is nil.") end
    if not name or not data then error("Cannot Glot when no Name/Data is passed.") end
    return ut.YieldGet(self.Session,{
        type = "Glot",
        name=name,
        data=data
    },"GlotPostURL")
end

function ut.server:Log(data)
    if not self.Session then error("Cannot Log when Session is nil.") end
    if not data then error("Cannot Log when no Name/Data is passed.") end
    self.Session:Send({
        type="AddLog",
        data=data
    })
end

function ut.server:GetFeatures(all)
    if not self.Session then error("Cannot Get when Session is nil.") end
    return ut.YieldGet(self.Session,{
        type = "GetFeatures",
        all=all
    },"GotFeatures")
end

-- ut.discord

ut.discord = {
    Session = nil
}

function ut.discord:Say(str)
    if not self.Session then error("Cannot Say when Session is nil.") end
    self.Session:Send({
        type = "Say",
        data=str
    })
end

function ut.discord:DirectMessage(msgid,str)
    if not self.Session then error("Cannot DirectMessage when Session is nil.") end
    self.Session:Send({
        type = "DirectMessage",
        data=str,
        target=msgid
    })
end

function ut.discord:QuickReply(msgid,str)
    if not self.Session then error("Cannot Reply when Session is nil.") end
    if (typeof(str) == "string") then
        str = {
            replyto=msgid,
            content=str
        }
    else
        str.replyto = msgid
    end
    self.Session:Send({
        type = "Say",
        data=str
    })
end

function ut.discord:Edit(id,str)
    if not self.Session then error("Cannot Edit when Session is nil.") end
    local realData = str
    if (typeof(str) == "string") then
        realData = {content=str}
    end
    self.Session:Send({
        type = "EditMessage",
        data= realData,
        id=id
    })
end

function ut.discord:Delete(id)
    if not self.Session then error("Cannot Delete when Session is nil.") end
    self.Session:Send({
        type = "DeleteMessage",
        data=id
    })
end

function ut.discord:ViaWebhook(data)
    if not self.Session then error("Cannot ViaWebhook when Session is nil.") end
    self.Session:Send({
        type = "ViaWebhook",
        data=data
    })
end

function ut.discord:PostLog(str)
    if (not str) then error("Cannot PostLog empty string") end
    if not self.Session then error("Cannot PostLog when Session is nil.") end

    local realData = str
    if (typeof(str) == "string") then
        realData = {content=str}
    end

    self.Session:Send({
        type = "SendMessage",
        data=realData
    })
end

function ut.discord:PostLog(str)
    if (not str) then error("Cannot Send empty string") end
    if not self.Session then error("Cannot Send when Session is nil.") end

    local realData = str
    if (typeof(str) == "string") then
        realData = {content=str}
    end

    return ut.YieldGet(self.Session,{
        type = "SendMessage",
        data=realData
    },"MessageSent")
end

function ut.discord:Reply(msgid,str)
    if (not str) then error("Cannot Send empty string") end
    if not self.Session then error("Cannot Send when Session is nil.") end

    local realData = str
    if (typeof(str) == "string") then
        realData = {content=str,replyto=msgid}
    else
        str.replyto = msgid
    end

    return ut.YieldGet(self.Session,{
        type = "SendMessage",
        data=realData
    },"MessageSent")
end

function ut.discord:GetChatEnabled()
    if not self.Session then error("Cannot GetChatEnabled when Session is nil.") end

    return ut.YieldGet(self.Session,{
        type = "GetDiscordToRobloxChatEnabled"
    },"GetDiscordToRobloxChatEnabled")
end

function ut.discord:GetInformationForMember(userid)
    if not self.Session then error("Cannot GetInformationForMember when Session is nil.") end

    return ut.YieldGet(self.Session,{
        type = "GetInformationForMember",
        id = userid
    },"GuildMemberInformation")
end

function ut.discord:SetChatEnabled(bool)
    if not self.Session then error("Cannot SetChatEnabled when Session is nil.") end

    self.Session:Send({
        type = "SetDiscordToRobloxChatEnabled",
        data=bool
    })
end

function ut.discord:OnButtonPressed(id,btnid)
    if not self.Session then error("Cannot OnButtonPressed when Session is nil.") end

    local b = Instance.new("BindableEvent")

    self.Session:On({type="ButtonPressed",messageId=id,id=btnid},function(data) 
        b:Fire({userId=data.userId,messageId=data.messageId})        
    end)
    return b.Event
end

-- ut.data

ut.data = {
    Session = nil
}

function ut.data:Set(key,value)
    if not self.Session then error("Cannot Set when Session is nil.") end
    self.Session:Send({
        type = "SetData",
        value=value,
        key=key
    })
end

function ut.data:Get(key)
    if not self.Session then error("Cannot Get when Session is nil.") end

    return ut.YieldGet(self.Session,{
        type = "GetData",
        key=key
    },"UtData")
end

-- ut.middleware
-- TODO: make this API more robust before v1 release, or, alternatively, in a future update

ut.middleware = {
    Session = nil,
    middlewares = {}
}

function ut.middleware:SetAction(action,func)
    ut.middleware.middlewares[action] = func
end

-- ut.util

ut.util = {
    Session = nil,
    specialGetPlayerOptions = {
        all = function() return game:GetService("Players"):GetPlayers() end,
        random = function() local p = game:GetService("Players"):GetPlayers() return {p[math.random(1,#p)]} end
    }
}

function ut.util.startsWith(target,str)
    return string.sub(target,1,string.len(str)) == str
end

function ut.util.endsWith(target,str)
    return string.sub(target,-string.len(str)) == str
end

function ut.util.getPlayers(strl)
    if (not strl) then return {} end
    local str = tostring(strl)
    if (ut.util.specialGetPlayerOptions[str:lower()]) then
        return ut.util.specialGetPlayerOptions[str:lower()]()
    end
    local players = {}
    for x,v in pairs(Players:GetPlayers()) do
        -- No better alternatives
        -- Or there is but I'm too lazy to find them, this will do
        -- for now

        -- TODO: make this NOT suck!!!
        if (str == tostring(v.UserId)) then
            table.insert(players,v)
        elseif (ut.util.startsWith(string.lower(v.Name),str:lower())) then
            table.insert(players,v)
        elseif (ut.util.startsWith(string.lower(v.DisplayName),str:lower())) then
            table.insert(players,v)
        end
    end
    return players
end

function ut.util.tableFilter(x,fun)
    local newTable = {}
    
    table.foreach(x,function(index,value) 
        if fun(value) then
            table.insert(newTable,value)
        end
    end)
    
    return newTable
end

function ut.util.tableMap(x,fun)
    local newTable = {}
    
    table.foreach(x,function(index,value) 
        newTable[index] = fun(value)
    end)
    
    return newTable
end

function ut.util.tableFind(x,fun)
    for _,v in pairs(x) do
        if fun(v) then
            return v
        end
    end
end

function ut.util.tableFindIndex(x,fun)
    for _,v in pairs(x) do
        if fun(v) then
            return _
        end
    end
end

-- ut.chat

function ut._initChat(session,player:Player)
    local c = player.Chatted:Connect(function(msg)
        session:Send({
            type = "Chat",
            data = msg,
            userid = tostring(player.UserId),
            username = player.Name,
            displayname = player.DisplayName
        })
    end)

    session.onclose:Connect(function()
        c:Disconnect()
    end)

    if (ut.UsingModernChat) then
        local sg = Instance.new("ScreenGui")
        sg.ResetOnSpawn = false
        sg.Name = HttpService:GenerateGUID(false)
        local ch = script.chathandle:Clone()
        ch.Parent = sg
        sg.Parent = player.PlayerGui 
    end
end

function ut.chat(session)
    print("Chat logging ready.")

    for x,v in pairs(Players:GetPlayers()) do
        ut._initChat(session,v)
    end

    local c = Players.PlayerAdded:Connect(function(p)
        ut._initChat(session,p)
    end)

    session.onclose:Connect(function()
        c:Disconnect()
    end)
end

-- ut init


function ut.init(session)
    local x = table.clone(ut)
    for _,v in pairs(x) do
        if typeof(v) == "table" then
            v.Session = session
        end
    end
    x.Session = session
    x.StartSession = StartSession
    return x
end

local Actions = {
    Ready = function(session,data)
        session.flags = data.flags

        session:Send({
            type = "GetGameInfo",
            data = game.JobId,
            gameid = tonumber(game.PlaceId),
            _PS_ID = game.PrivateServerId,
            _PS_UID = game.PrivateServerOwnerId
        })

        -- init packages
        if script:FindFirstChild("packages") then
            for x,v in pairs(script.packages:GetChildren()) do
                if (v:IsA("ModuleScript")) then
                    session.api.server:Log("Loading package "..v.Name)
                    require(v)(session.api)
                end
            end
        end
    end,
    Chat = function(session,data)
        if (ut.UsingModernChat) then
            if ut.ChatRemoteEvent then
                ut.ChatRemoteEvent:FireAllClients(
                    session.flags.DisplayRoControlTagInRobloxChat,
                    data.tagColor or "#FFFFFF",
                    data.tag,
                    data.data
                )
            end
        else
            local extradata = {Tags={
                {
                    TagText = "as "..data.tag,
                    TagColor = Color3.fromHex(data.tagColor or "#FFFFFF")
                }
            },NameColor=Color3.new(1,0,0)}
            if (not session.flags.DisplayRoControlTagInRobloxChat) then
                extradata.NameColor = Color3.fromHex(data.tagColor or "#FFFFFF")
                extradata.Tags = {}
                ut.Speaker.PlayerObj = {DisplayName=data.tag,UserId=0}
            end
            ut.Speaker:SayMessage(data.data,"All",extradata)
            ut.Speaker.PlayerObj = nil
        end
    end,
    Image = function(session,data)
        local parentG = Instance.new("ScreenGui")
        if (data.caption) then
            local t = Instance.new("TextLabel",parentG)
            t.Text = data.caption
            t.Size = UDim2.new(1,0,0,36)
            t.Position = UDim2.new(0,0,0,-36)
            t.TextColor3 = Color3.new(1,1,1)
            t.BackgroundColor3 = Color3.new(0,0,0)
            t.Font = Enum.Font.Gotham
            t.TextSize = 20
            t.TextWrapped = true
            t.BackgroundTransparency = 0.5
            t.BorderSizePixel = 0
        end

        for xPos,Color in pairs(data.data) do
            local csK = {}
            for yPos,color in pairs(Color) do
                table.insert(csK,ColorSequenceKeypoint.new((((yPos-1)%20)*0.05)/0.95,Color3.fromRGB(color.r,color.g,color.b)))
            end

            for tableOffset = 0,9 do
                local realCSK = {}
                local loc = (20*tableOffset)+1
                table.move(
                    csK,
                    loc,
                    20*(tableOffset+1),
                    1,
                    realCSK
                )
                local _frame = Instance.new("Frame")
                _frame.Position = UDim2.new((xPos-1)*0.005,0,tableOffset*0.1,0)
                _frame.Size = UDim2.new(0.005,0,0.1,0)
                _frame.BorderSizePixel = 0
                _frame.BackgroundColor3 = Color3.new(1,1,1)

                local gradient = Instance.new("UIGradient")
                gradient.Rotation = 90
                gradient.Color = ColorSequence.new(realCSK)

                gradient.Parent = _frame
                _frame.Parent = parentG
            end
        end

        local toCleanup = {
            parentG
        }

        -- Maybe replace this with
        -- local plrs = ut.util.getPlayers(data.player or "")
        -- Should have the same effect

        local plrs = Players:GetPlayers()

        if #ut.util.getPlayers(data.player or tostring(math.random())) >= 0 then
            plrs = ut.util.getPlayers(data.player)
        end

        for x,v in pairs(plrs) do
            local _g = parentG:Clone()
            _g.Parent = v.PlayerGui
            table.insert(toCleanup,_g)
        end

        session:Send({
            type = "Say",
            data="Image sent."
        })

        task.wait(tonumber(data.time) or 5)

        for x,v in pairs(toCleanup) do
            if v then
                v:Destroy()
            end
        end
    end,
    ExecuteCommand = function(session,data)
        if (session.api.commands.commands[data.commandId]) then
            session.api.commands.commands[data.commandId](data.args,{userId=data.userId,messageId=data.messageId})
        end
    end
}

function StartSession(config)
    local Config = config or DefaultConfig

    local OptipostSession = Optipost.new(Config.URL)

    OptipostSession.api = ut.init(OptipostSession)

    OptipostSession.onmessage:Connect(function(dt)
        local function default(data)
            if not data then data = dt end
            if (Actions[data.type or ""]) then
                Actions[data.type or ""](OptipostSession,data)
            end
        end

        if ut.middleware.middlewares[dt.type or ""] then
            ut.middleware.middlewares[dt.type or ""]({data=dt,default=default})
        else
            default(dt)
        end
    end)

    OptipostSession.onopen:Connect(function(data)
        print("Connected to RoControl. Waiting for server to send back Ready...")
    end)

    OptipostSession:Open()

    ut.chat(OptipostSession)

    return OptipostSession
end

return StartSession