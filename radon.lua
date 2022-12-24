--- Imports
local _ = require("util.score")

local Display = require("modules.display")

local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local Button = require("components.Button")
local SmolButton = require("components.SmolButton")
local BigText = require("components.BigText")
local bigFont = require("fonts.bigfont")
local SmolText = require("components.SmolText")
local smolFont = require("fonts.smolfont")
local BasicText = require("components.BasicText")
local Rect = require("components.Rect")
local RenderCanvas = require("components.RenderCanvas")
local Core = require("core.ShopState")
local ShopRunner = require("core.ShopRunner")
local ConfigValidator = require("core.ConfigValidator")

local loadRIF = require("modules.rif")

local config = require("config")
local products = require("products")
--- End Imports

ConfigValidator.validateConfig(config)
ConfigValidator.validateProducts(products)

local display = Display.new({theme=config.theme})

local function getDisplayedProducts(allProducts, settings)
    local displayedProducts = {}
    for i = 1, #allProducts do
        local product = allProducts[i]
        product.id = i
        if not settings.hideUnavailableProducts or product.quantity > 0 then
            table.insert(displayedProducts, product)
        end
    end
    return displayedProducts
end

local function getProductPrice(product, currency)
    local price = product.price / currency.value
    if product.priceOverrides then
        for i = 1, #product.priceOverrides do
            local override = product.priceOverrides[i]
            if override.currency == currency.id then
                price = override.price
                break
            end
        end
    end
    return price
end

local function getCurrencySymbol(currency, productTextSize)
    local currencySymbol
    if currency.krypton and currency.krypton.currency then
        currencySymbol = currency.krypton.currency.currency_symbol  
    elseif not currencySymbol and currency.name:find("%.") then
        currencySymbol = currency.name:sub(currency.name:find("%.")+1, #currency.name)
    elseif currency.id == "tenebra" then
        currencySymbol = "tst"
    else
        currencySymbol = "KST"
    end
    if currencySymbol == "TST" then
        currencySymbol = "tst"
    end
    if currencySymbol:lower() == "kst" and productTextSize == "medium" then
        currencySymbol = "kst"
    elseif currencySymbol:lower() == "kst" then
        currencySymbol = "\164"
    end
    return currencySymbol
end

local function getCategories(products)
    local categories = {}
    for _, product in ipairs(products) do
        local category = product.category
        if not category then
            category = "*"
        end
        local found = nil
        for i = 1, #categories do
            if categories[i].name == category then
                found = i
                break
            end
        end
        if not found then
            if category == "*" then
                table.insert(categories, 1, {name=category, products={}})
                found = 1
            else
                table.insert(categories, {name=category, products={}})
                found = #categories
            end
        end
        table.insert(categories[found].products, product)
    end
    return categories
end

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas(display)
    local theme = props.config.theme

    local header = BigText { display=display, text="Radon Shop", x=1, y=1, align=theme.formatting.headerAlign, bg=theme.colors.headerBgColor, color = theme.colors.headerColor, width=display.bgCanvas.width }

    if props.shopState.productsChanged then
        canvas:markRect(1, 1, canvas.width, canvas.height)
    end

    local flatCanvas = {
        header
    }

    local maxAddrWidth = 0
    local maxQtyWidth = 0
    local maxPriceWidth = 0
    local categories = getCategories(props.shopState.products)
    props.shopState.numCategories = #categories
    local selectedCategory = props.shopState.selectedCategory
    local catName = categories[selectedCategory].name
    local shopProducts = getDisplayedProducts(categories[selectedCategory].products, config.settings)
    local productsHeight = display.bgCanvas.height - 17
    local heightPerProduct = math.floor(productsHeight / #shopProducts)
    local productTextSize
    if theme.formatting.productTextSize == "auto" then
        if heightPerProduct >= 15 then
            productTextSize = "large"
        elseif heightPerProduct >= 9 then
            productTextSize = "medium"
        else
            productTextSize = "small"
       end
    else
        productTextSize = theme.formatting.productTextSize
    end

    if #shopProducts > 0 then
        table.insert(flatCanvas, Rect { display=display, x=1, y=16, width=display.bgCanvas.width, height=1, color=theme.colors.productBgColor })
    end

    local currency = props.shopState.selectedCurrency
    local currencySymbol = getCurrencySymbol(currency, productTextSize)
    for i = 1, #shopProducts do
        local product = shopProducts[i]
        product.quantity = product.quantity or 0
        local productPrice = getProductPrice(product, props.shopState.selectedCurrency)
        if productTextSize == "large" then
            maxAddrWidth = math.max(maxAddrWidth, bigFont:getWidth(product.address .. "@")+2)
            maxQtyWidth = math.max(maxQtyWidth, bigFont:getWidth(tostring(product.quantity))+4)
            maxPriceWidth = math.max(maxPriceWidth, bigFont:getWidth(tostring(productPrice) .. currencySymbol)+2)
        elseif productTextSize == "medium" then
            maxAddrWidth = math.max(maxAddrWidth, smolFont:getWidth(product.address .. "@")+2)
            maxQtyWidth = math.max(maxQtyWidth, smolFont:getWidth(tostring(product.quantity))+4)
            maxPriceWidth = math.max(maxPriceWidth, smolFont:getWidth(tostring(productPrice) .. currencySymbol)+2)
        else
            maxAddrWidth = math.max(maxAddrWidth, #(product.address .. "@")+1)
            maxQtyWidth = math.max(maxQtyWidth, #tostring(product.quantity)+2)
            maxPriceWidth = math.max(maxPriceWidth, #(tostring(productPrice) .. currencySymbol)+1)
        end
    end
    for i = 1, #shopProducts do
        local product = shopProducts[i]
        -- Display products in format:
        -- <quantity> <name> <price> <address>
        product.quantity = product.quantity or 0
        local productPrice = getProductPrice(product, props.shopState.selectedCurrency)
        local qtyColor = theme.colors.normalQtyColor
        if product.quantity == 0 then
            qtyColor = theme.colors.outOfStockQtyColor
        elseif product.quantity < 10 then
            qtyColor = theme.colors.lowQtyColor
        elseif product.quantity < 64 then
            qtyColor = theme.colors.warningQtyColor
        end
        local productNameColor = theme.colors.productNameColor
        if product.quantity == 0 then
            productNameColor = theme.colors.outOfStockNameColor
        end
        if productTextSize == "large" then
            table.insert(flatCanvas, BigText { key="qty-"..catName..tostring(product.id), display=display, text=tostring(product.quantity), x=1, y=17+((i-1)*15), align="center", bg=theme.colors.productBgColor, color=qtyColor, width=maxQtyWidth })
            table.insert(flatCanvas, BigText { key="name-"..catName..tostring(product.id), display=display, text=product.name, x=maxQtyWidth+1, y=17+((i-1)*15), align=theme.formatting.productNameAlign, bg=theme.colors.productBgColor, color=productNameColor, width=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth-maxQtyWidth })
            table.insert(flatCanvas, BigText { key="price-"..catName..tostring(product.id), display=display, text=tostring(productPrice) .. currencySymbol, x=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth, y=17+((i-1)*15), align="right", bg=theme.colors.productBgColor, color=theme.colors.priceColor, width=maxPriceWidth })
            table.insert(flatCanvas, BigText { key="addr-"..catName..tostring(product.id), display=display, text=product.address .. "@", x=display.bgCanvas.width-3-maxAddrWidth, y=17+((i-1)*15), align="right", bg=theme.colors.productBgColor, color=theme.colors.addressColor, width=maxAddrWidth+4 })
        elseif productTextSize == "medium" then
            table.insert(flatCanvas, SmolText { key="qty-"..catName..tostring(product.id), display=display, text=tostring(product.quantity), x=1, y=17+((i-1)*9), align="center", bg=theme.colors.productBgColor, color=qtyColor, width=maxQtyWidth })
            table.insert(flatCanvas, SmolText { key="name-"..catName..tostring(product.id), display=display, text=product.name, x=maxQtyWidth+1, y=17+((i-1)*9), align=theme.formatting.productNameAlign, bg=theme.colors.productBgColor, color=productNameColor, width=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth-maxQtyWidth })
            table.insert(flatCanvas, SmolText { key="price-"..catName..tostring(product.id), display=display, text=tostring(productPrice) .. currencySymbol, x=display.bgCanvas.width-3-maxAddrWidth-maxPriceWidth, y=17+((i-1)*9), align="right", bg=theme.colors.productBgColor, color=theme.colors.priceColor, width=maxPriceWidth })
            table.insert(flatCanvas, SmolText { key="addr-"..catName..tostring(product.id), display=display, text=product.address .. "@", x=display.bgCanvas.width-3-maxAddrWidth, y=17+((i-1)*9), align="right", bg=theme.colors.productBgColor, color=theme.colors.addressColor, width=maxAddrWidth+4 })
        else
            table.insert(flatCanvas, BasicText { key="qty-"..catName..tostring(product.id), display=display, text=tostring(product.quantity), x=1, y=6+((i-1)*1), align="center", bg=theme.colors.productBgColor, color=qtyColor, width=maxQtyWidth })
            table.insert(flatCanvas, BasicText { key="name-"..catName..tostring(product.id), display=display, text=product.name, x=maxQtyWidth+1, y=6+((i-1)*1), align=theme.formatting.productNameAlign, bg=theme.colors.productBgColor, color=productNameColor, width=(display.bgCanvas.width/2)-1-maxAddrWidth-maxPriceWidth-maxQtyWidth })
            table.insert(flatCanvas, BasicText { key="price-"..catName..tostring(product.id), display=display, text=tostring(productPrice) .. currencySymbol, x=(display.bgCanvas.width/2)-1-maxAddrWidth-maxPriceWidth, y=6+((i-1)*1), align="right", bg=theme.colors.productBgColor, color=theme.colors.priceColor, width=maxPriceWidth })
            table.insert(flatCanvas, BasicText { key="addr-"..catName..tostring(product.id), display=display, text=product.address .. "@  ", x=(display.bgCanvas.width/2)-1-maxAddrWidth, y=6+((i-1)*1), align="right", bg=theme.colors.productBgColor, color=theme.colors.addressColor, width=maxAddrWidth+2 })
        end
    end

    local currencyX = 3
    for i = 1, #props.config.currencies do
        local symbol = getCurrencySymbol(props.config.currencies[i], productTextSize)
        local symbolSize = bigFont:getWidth(symbol)+6
        local bgColor
        if i % 4 == 1 then
            bgColor = theme.colors.currency1Color
        elseif i % 4 == 2 then
            bgColor = theme.colors.currency2Color
        elseif i % 4 == 3 then
            bgColor = theme.colors.currency3Color
        elseif i % 4 == 0 then
            bgColor = theme.colors.currency4Color
        end
        table.insert(flatCanvas, Button {
            display = display,
            align = "center",
            text = symbol,
            x = currencyX,
            y = 1,
            bg = bgColor,
            color = theme.colors.currencyTextColor,
            width = symbolSize,
            onClick = function()
                props.shopState.selectedCurrency = props.config.currencies[i]
                props.shopState.lastTouched = os.epoch("utc")
            end
        })
        currencyX = currencyX + symbolSize + 2
    end

    local categoryX = display.bgCanvas.width - 2
    for i = #categories, 1, -1 do
        local category = categories[i]
        local categoryName = category.name
        local categoryColor
        if i == selectedCategory then
            categoryColor = theme.colors.activeCategoryColor
            categoryName = "[" .. categoryName .. "]"
        elseif i % 4 == 1 then
            categoryColor = theme.colors.category1Color
        elseif i % 4 == 2 then
            categoryColor = theme.colors.category2Color
        elseif i % 4 == 3 then
            categoryColor = theme.colors.category3Color
        elseif i % 4 == 0 then
            categoryColor = theme.colors.category4Color
        end
        local categoryWidth = smolFont:getWidth(categoryName)+6
        categoryX = categoryX - categoryWidth - 2

        table.insert(flatCanvas, SmolButton {
            display = display,
            align = "center",
            text = categoryName,
            x = categoryX,
            y = 4,
            bg = categoryColor,
            color = theme.colors.categoryTextColor,
            width = categoryWidth,
            onClick = function()
                props.shopState.selectedCategory = i
                props.shopState.lastTouched = os.epoch("utc")
                canvas:markRect(1, 16, canvas.width, canvas.height-16)
            end
        })
    end

    return _.flat({ _.flat(flatCanvas) }), {
        canvas = {canvas, 1, 1},
        config = props.config or {},
        shopState = props.shopState or {},
        products = props.shopState.products,
    }
end)



local t = 0
local tree = nil
local lastClock = os.epoch("utc")

local lastCanvasStack = {}
local lastCanvasHash = {}
local function diffCanvasStack(newStack)
    -- Find any canvases that were removed
    local removed = {}
    local kept, newCanvasHash = {}, {}
    for i = 1, #lastCanvasStack do
        removed[lastCanvasStack[i][1]] = lastCanvasStack[i]
    end
    for i = 1, #newStack do
        if removed[newStack[i][1]] then
            kept[#kept+1] = newStack[i]
            removed[newStack[i][1]] = nil
            newStack[i][1].allDirty = false
        else -- New
            newStack[i][1].allDirty = true
        end

        newCanvasHash[newStack[i][1]] = newStack[i]
    end

    -- Mark rectangle of removed canvases on bgCanvas (TODO: using bgCanvas is a hack)
    for _, canvas in pairs(removed) do
        display.bgCanvas:dirtyRect(canvas[2], canvas[3], canvas[1].width, canvas[1].height)
    end

    -- For each kept canvas, mark the bounds if the new bounds are different
    for i = 1, #kept do
        local newCanvas = kept[i]
        local oldCanvas = lastCanvasHash[newCanvas[1]]
        if oldCanvas then
            if oldCanvas[2] ~= newCanvas[2] or oldCanvas[3] ~= newCanvas[3] then
                -- TODO: Optimize this?
                display.bgCanvas:dirtyRect(oldCanvas[2], oldCanvas[3], oldCanvas[1].width, oldCanvas[1].height)
                display.bgCanvas:dirtyRect(newCanvas[2], newCanvas[3], newCanvas[1].width, newCanvas[1].height)
            end
        end
    end

    lastCanvasStack = newStack
    lastCanvasHash = newCanvasHash
end

local shopState = Core.ShopState.new(config, products)

local deltaTimer = os.startTimer(0)
ShopRunner.launchShop(shopState, function()
    while true do
        tree = Solyd.render(tree, Main {t = t, config = config, shopState = shopState})

        local context = Solyd.getTopologicalContext(tree, { "canvas", "aabb" })

        diffCanvasStack(context.canvas)

        local t1 = os.epoch("utc")
        display.ccCanvas:composite(unpack(context.canvas))
        display.ccCanvas:outputDirty(display.mon)
        local t2 = os.epoch("utc")
        -- print("Render time: " .. (t2-t1) .. "ms")

        local e = { os.pullEvent() }
        local name = e[1]
        if name == "timer" and e[2] == deltaTimer then
            local clock = os.epoch("utc")
            local dt = (clock - lastClock)/1000
            t = t + dt
            lastClock = clock
            deltaTimer = os.startTimer(0)

            hooks.tickAnimations(dt)
        elseif name == "monitor_touch" then
            local x, y = e[3], e[4]
            local node = hooks.findNodeAt(context.aabb, x, y)
            if node then
                node.onClick()
            end
        end
    end
end)
