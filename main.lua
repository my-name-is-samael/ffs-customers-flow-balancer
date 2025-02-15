---@class CustomersFlowBalancerMod: ModModule
local M = {
    Author = "TontonSamael",
    Version = 1,

    -- CONSTANTS
    COOLDOWNS = {                     -- delay in seconds between customers (peds & cars)
        PED = {                       -- PED CUSTOMERS
            [0] = {                   -- EASY
                minPopularity = 47,   -- base 53 + 1 / 3
                maxPopularity = 34.3, -- base 34.3
            },
            [1] = {                   -- NORMAL
                minPopularity = 45,   -- base 53 + 1 / 3
                maxPopularity = 28,   -- base 32
            },
            [2] = {                   -- HARD
                minPopularity = 37,   -- base 40
                maxPopularity = 20,   -- base 21.8
            },
            [3] = {                   -- VERY HARD
                minPopularity = 29,   -- base 32
                maxPopularity = 17,   -- base 19.2
            },
            [4] = {                   -- NIGHTMARE
                minPopularity = 19.2, -- base 19.2
                maxPopularity = 12,   -- base 12
            },
        },
        CAR = {                      -- DRIVE_THRU CUSTOMERS
            [0] = {                  -- EASY
                minPopularity = 120, -- base 240
                maxPopularity = 90,  -- base 120
            },
            [1] = {                  -- NORMAL
                minPopularity = 80,  -- base 160
                maxPopularity = 60,  -- base 96
            },
            [2] = {                  -- HARD
                minPopularity = 48,  -- base 120
                maxPopularity = 37,  -- base 80
            },
            [3] = {                  -- VERY HARD
                minPopularity = 45,  -- base 96
                maxPopularity = 33,  -- base 60
            },
            [4] = {                  -- NIGHTMARE
                minPopularity = 39,  -- base 60
                maxPopularity = 28,  -- base 40
            },
        }
    },

    -- DATA
    pedFlow = 1, -- multiplier to adjust peds flow
    carFlow = 1, -- multiplier to adjust cars flow
}

local function GetBasePedCustomerCooldown(difficulty, popularity)
    local config = M.COOLDOWNS.PED[difficulty]
    if config then
        return math.map(popularity, .25, 1, config.minPopularity, config.maxPopularity)
    end
    return 60
end

local function GetBaseDriveCustomerCooldown(difficulty, popularity)
    local config = M.COOLDOWNS.CAR[difficulty]
    if config then
        return math.map(popularity, .25, 1, config.minPopularity, config.maxPopularity)
    end
    return 60
end

---@param ModManager ModManager
---@param Parameters string[]
---@param Ar any
local function PedFlowCommand(ModManager, Parameters, Ar)
    local usageStr = "Usage: pedflow [percent]"
    if #Parameters < 1 then
        Log(M, LOG.INFO, string.format("Current peds flow = %f%%", M.pedFlow * 100), Ar)
        Log(M, LOG.INFO, usageStr, Ar)
    elseif #Parameters == 1 then
        local percent = tonumber(Parameters[1])
        if not percent then
            Log(M, LOG.INFO, "Invalid percent value", Ar)
            Log(M, LOG.INFO, usageStr, Ar)
            return
        end

        if percent < 20 or percent > 500 then
            Log(M, LOG.INFO, "Percent must be between 20 and 500", Ar)
            return
        end

        M.pedFlow = percent / 100
        Log(M, LOG.INFO, string.format("Peds flow set to %f%%", M.pedFlow * 100), Ar)
    else
        Log(M, LOG.INFO, "Too much parameters", Ar)
        Log(M, LOG.INFO, usageStr, Ar)
    end
end

---@param ModManager ModManager
---@param Parameters string[]
---@param Ar any
local function CarFlowCommand(ModManager, Parameters, Ar)
    local usageStr = "Usage: carflow [percent]"
    if #Parameters < 1 then
        Log(M, LOG.INFO, string.format("Current cars flow = %f%%", M.carFlow * 100), Ar)
        Log(M, LOG.INFO, usageStr, Ar)
    elseif #Parameters == 1 then
        local percent = tonumber(Parameters[1])
        if not percent then
            Log(M, LOG.INFO, "Invalid percent value", Ar)
            Log(M, LOG.INFO, usageStr, Ar)
            return
        end

        if percent < 20 or percent > 500 then
            Log(M, LOG.INFO, "Percent must be between 20 and 500", Ar)
            return
        end

        M.carFlow = percent / 100
        Log(M, LOG.INFO, string.format("Cars flow set to %f%%", M.carFlow * 100), Ar)
    else
        Log(M, LOG.INFO, "Too much parameters", Ar)
        Log(M, LOG.INFO, usageStr, Ar)
    end
end

---@param ModManager ModManager
function M.Init(ModManager)
    ModManager.AddHook(M, "GeneratePedCooldown",
        "/Game/Blueprints/Gameplay/CustomerQueue/BP_CustomerManager.BP_CustomerManager_C:GenerateSpawnCooldown",
        function(M2, GameState)
            local difficulty = tonumber(M2.GameState.GameDifficulty)
            local popularity = tonumber(M2.GameState.RestaurantPopularity)
            local cooldown = GetBasePedCustomerCooldown(difficulty, popularity) / M.pedFlow
            Log(M, LOG.DEBUG,
                string.format("Set ped customer cooldown to %f (difficulty = %s, popularity = %f)", cooldown, difficulty,
                    popularity))
            return cooldown
        end,
        function(ModManager2) return ModManager2.IsHost end)

    ModManager.AddHook(M, "GenerateCarCooldown",
        "/Game/Blueprints/Gameplay/CustomerQueue/BP_CustomerManager.BP_CustomerManager_C:GenerateDriveThruSpawnCooldown",
        function(ModManager2, GameState)
            local difficulty = GameState:get().IngameState.GameDifficulty
            local popularity = GameState:get().IngameState.RestaurantPopularity
            local cooldown = GetBaseDriveCustomerCooldown(difficulty, popularity) / M.carFlow
            Log(M, LOG.DEBUG,
                string.format("Set drive-thru customer cooldown to %f (difficulty = %s, popularity = %f)", cooldown,
                    difficulty, popularity))
            return cooldown
        end,
        function(ModManager2) return ModManager2.IsHost end)

    ModManager.AddCommand(M, "pedflow", PedFlowCommand)
    ModManager.AddCommand(M, "carflow", CarFlowCommand)

    Log(M, LOG.INFO, "Customers Flow Balancer Loaded!")
end

return M
