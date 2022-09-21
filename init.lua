local nicklim = 2

local list = core.get_mod_storage()
local whitelist = {} --not persistent = more secure

local function get_ips(nick)
    local ips = {}
    for ip,names in pairs(list:to_table().fields) do
        for _,name in pairs(names:split(" ")) do
            if name == nick then
                table.insert(ips,ip)
            end
        end
    end
    if #ips > 0 then
        return ips
    end
end

core.register_on_prejoinplayer(function(name,ip)
    local names = list:get_string(ip):split(" ")
    local auth = core.get_auth_handler().get_auth(name)
    if #names >= nicklim and not auth and not whitelist[ip] then
        return "You have too many accounts: "..list:get_string(ip)
    end
    local save = true
    for _,nick in pairs(names) do
        if nick == name then
            save = false
            break
        end
    end
    if save then
        list:set_string(ip,list:get_string(ip)..name.." ")
    end
end)

core.register_chatcommand("ipinfo",{
  description = "Get accounts on single IP",
  privs = {server=true},
  params = "<playername>",
  func = function(name,param)
    local ips = get_ips(param)
    local names = {}
    if ips then
        for _,ip in ipairs(ips) do
            table.insert(names,list:get_string(ip))
        end
        return true, "Accounts on "..param.."'s IP: "..table.concat(names)
    end
    return false, "Nothing found"
end})

core.register_chatcommand("iplim_wl",{
  description = "Add/remove Player's IP to/from the whitelist",
  privs = {server=true},
  params = "<add>/<rm> <playername>",
  func = function(name,param)
    local cmd,player = param:match("^(%S+) (.+)$")
    if not (cmd and player) then return false, "Invalid params" end
    local ips = get_ips(player)
    if not ips then return false, "Error getting player's IP" end
    if cmd == "add" then
        for _,ip in ipairs(ips) do
            whitelist[ip] = true
        end
        return true, player.." added to whitelist"
    elseif cmd == "rm" then
        for _,ip in ipairs(ips) do
            whitelist[ip] = nil
        end
        return true, player.." removed from whitelist"
    else
        return false, "Invalid params"
    end
end})

core.register_chatcommand("iplim_clear",{
  description = "Clear iplim database",
  privs = {server=true},
  func = function(name,param)
    for ip,names in pairs(list:to_table().fields) do
        list:set_string(ip,"")
    end
    return true, "iplim DB cleared"
end})
