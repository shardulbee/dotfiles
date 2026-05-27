---@diagnostic disable: undefined-global, lowercase-global
function setup(config)
    config.ui = config.ui or {}
    config.ui.set_window_title = false
    config.ui.theme = {
        dark = "dark",
        light = "light",
    }
end
