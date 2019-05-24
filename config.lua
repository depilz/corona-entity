application = {
	content = {
		width  = 320,
		height = 480,
		scale  = "zoomEven",
		fps    = 60,

		imageSuffix =
		{
				["@2x"] = 1.5, -- A good scale for iPhone 4 and iPad
				["@4x"] = 3, -- A good scale for Retina
				-- ["@5x"] = 4.5, -- A good scale for Retina
		}

	},
	license =
    {
        google =
        {
            key    = "",
            policy = "serverManaged"
        },
    },
}
