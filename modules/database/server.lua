local config = lib.require('shared.config')


local DatabaseManager = {
    initialized = false,
    tables_created = false
}


local function createTables()
    if DatabaseManager.tables_created then
        return
    end

    local prefix = config.database.table_prefix


    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ]] .. prefix .. [[players (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) UNIQUE NOT NULL,
            total_crates_opened INT DEFAULT 0,
            total_items_received INT DEFAULT 0,
            items_by_tier JSON,
            last_opened TIMESTAMP NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])


    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ]] .. prefix .. [[crates (
            id INT AUTO_INCREMENT PRIMARY KEY,
            location_x FLOAT NOT NULL,
            location_y FLOAT NOT NULL,
            location_z FLOAT NOT NULL,
            opened_by VARCHAR(50),
            opened_at TIMESTAMP NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            loot_data JSON
        )
    ]])


    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ]] .. prefix .. [[statistics (
            id INT AUTO_INCREMENT PRIMARY KEY,
            date DATE UNIQUE NOT NULL,
            crates_opened INT DEFAULT 0,
            items_distributed INT DEFAULT 0,
            unique_players INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])

    DatabaseManager.tables_created = true
    config.utils.log(locale('database.tables_created'), 'INFO')
end

local function initializeDatabase()
    if not config.database.enabled then
        config.utils.log(locale('database.database_disabled'), 'INFO')
        return
    end

    if DatabaseManager.initialized then
        return
    end


    createTables()

    DatabaseManager.initialized = true
    config.utils.log(locale('database.database_initialized'), 'INFO')
end





local function savePlayerData(identifier, data)
    if not config.database.enabled then
        return
    end

    local prefix = config.database.table_prefix

    MySQL.query([[
        INSERT INTO ]] .. prefix .. [[players (identifier, total_crates_opened, total_items_received, items_by_tier, last_opened)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        total_crates_opened = VALUES(total_crates_opened),
        total_items_received = VALUES(total_items_received),
        items_by_tier = VALUES(items_by_tier),
        last_opened = VALUES(last_opened)
    ]], {
        identifier,
        data.total_crates_opened or 0,
        data.total_items_received or 0,
        json.encode(data.items_by_tier or {}),
        data.last_opened and os.date('%Y-%m-%d %H:%M:%S', data.last_opened) or nil
    })
end


local function loadPlayerData(identifier)
    if not config.database.enabled then
        return nil
    end

    local prefix = config.database.table_prefix

    local result = MySQL.single.await([[
        SELECT * FROM ]] .. prefix .. [[players WHERE identifier = ?
    ]], {identifier})

    if result then
        return {
            total_crates_opened = result.total_crates_opened,
            total_items_received = result.total_items_received,
            items_by_tier = json.decode(result.items_by_tier or '{}'),
            last_opened = result.last_opened
        }
    end

    return nil
end


local function saveCrateData(coords, opened_by, loot_data)
    if not config.database.enabled then
        return
    end

    local prefix = config.database.table_prefix

    MySQL.query([[
        INSERT INTO ]] .. prefix .. [[crates (location_x, location_y, location_z, opened_by, opened_at, loot_data)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        coords.x,
        coords.y,
        coords.z,
        opened_by,
        os.date('%Y-%m-%d %H:%M:%S'),
        json.encode(loot_data or {})
    })
end


local function updateDailyStats()
    if not config.database.enabled then
        return
    end

    local prefix = config.database.table_prefix
    local today = os.date('%Y-%m-%d')


    local result = MySQL.single.await([[
        SELECT * FROM ]] .. prefix .. [[statistics WHERE date = ?
    ]], {today})

    if result then

        MySQL.query([[
            UPDATE ]] .. prefix .. [[statistics 
            SET crates_opened = crates_opened + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE date = ?
        ]], {today})
    else

        MySQL.query([[
            INSERT INTO ]] .. prefix .. [[statistics (date, crates_opened)
            VALUES (?, 1)
        ]], {today})
    end
end


local function getStatistics(days)
    if not config.database.enabled then
        return {}
    end

    local prefix = config.database.table_prefix
    days = days or 7

    local results = MySQL.query.await([[
        SELECT * FROM ]] .. prefix .. [[statistics 
        WHERE date >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        ORDER BY date DESC
    ]], {days})

    return results or {}
end


local function getTopPlayers(limit)
    if not config.database.enabled then
        return {}
    end

    local prefix = config.database.table_prefix
    limit = limit or 10

    local results = MySQL.query.await([[
        SELECT identifier, total_crates_opened, total_items_received
        FROM ]] .. prefix .. [[players
        ORDER BY total_crates_opened DESC
        LIMIT ?
    ]], {limit})

    return results or {}
end


CreateThread(function()
    initializeDatabase()
end)


return {
    savePlayerData = savePlayerData,
    loadPlayerData = loadPlayerData,
    saveCrateData = saveCrateData,
    updateDailyStats = updateDailyStats,
    getStatistics = getStatistics,
    getTopPlayers = getTopPlayers,
    isEnabled = function()
        return config.database.enabled
    end
}
