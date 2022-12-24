return {
    branding = {
        title = "Radon Shop"
    },
    settings = {
        hideUnavailableProducts = false,
        pollFrequency = 30,
        categoryCycleFrequency = 20,
        activityTimeout = 60,
    },
    theme = {
        formatting = {
            headerAlign = "center",
            productNameAlign = "center",
            productTextSize = "auto"
        },
        colors = {
            bgColor = colors.lightGray,
            headerBgColor = colors.red,
            headerColor = colors.white,
            productBgColor = colors.blue,
            outOfStockQtyColor = colors.red,
            lowQtyColor = colors.orange,
            warningQtyColor = colors.yellow,
            normalQtyColor = colors.white,
            productNameColor = colors.white,
            outOfStockNameColor = colors.lightGray,
            priceColor = colors.lime,
            addressColor = colors.white,
            currencyTextColor = colors.white,
            currency1Color = colors.green,
            currency2Color = colors.pink,
            currency3Color = colors.lightBlue,
            currency4Color = colors.yellow,
            catagoryTextColor = colors.white,
            category1Color = colors.pink,
            category2Color = colors.orange,
            category3Color = colors.lime,
            category4Color = colors.lightBlue,
            activeCategoryColor = colors.black,
        },
        palette = {
            [colors.black] = 0x181818,
            [colors.blue] = 0x182B52,
            [colors.purple] = 0x7E2553,
            [colors.green] = 0x008751,
            [colors.brown] = 0xAB5136,
            [colors.gray] = 0x565656,
            [colors.lightGray] = 0x9D9D9D,
            [colors.red] = 0xFF004C,
            [colors.orange] = 0xFFA300,
            [colors.yellow] = 0xFFEC23,
            [colors.lime] = 0x00A23C,
            [colors.cyan] = 0x29ADFF,
            [colors.magenta] = 0x82769C,
            [colors.pink] = 0xFF77A9,
            [colors.lightBlue] = 0x3D7EDB,
            [colors.white] = 0xECECEC
        }
    },
    currencies = {
        {
            id = "krist", -- if not krist or tenebra, must supply endpoint
            -- node = "https://krist.dev"
            host = "ksbangelco",
            name = "radon.kst",
            pkey = "",
            pkeyFormat = "raw", -- Either 'raw' or 'kristwallet', defaults to 'raw'
            -- NOTE: It is not recommended to use kwallet, the best practice is to convert your pkey (using
            -- kwallet format) to raw pkey yourself first, and then use that here. Thus improving security.
            value = 1.0 -- Default scaling on item prices, can be overridden on a per-item basis
        },
        {
            id = "tenebra", -- if not krist or tenebra, must supply endpoint
            -- node = "https://krist.dev"
            host = "tttttttttt",
            name = "radon.tst",
            pkey = "",
            pkeyFormat = "raw", -- Either 'raw' or 'kristwallet', defaults to 'raw'
            -- NOTE: It is not recommended to use kwallet, the best practice is to convert your pkey (using
            -- kwallet format) to raw pkey yourself first, and then use that here. Thus improving security.
            value = 0.1 -- Default scaling on item prices, can be overridden on a per-item basis
        },
    },
    peripherals = {
        monitor = nil,
        exchangeChest = nil,
        outputChest = nil,
    },
    exchange = {
        enabled = true,
        node = "https://localhost:8000/"
    }
}