local PI = math.pi
local c1 = 1.70158
local c2 = c1 * 1.525
local c3 = c1 + 1
local c4 = (2 * PI) / 3
local c5 = (2 * PI) / 4.5

local function bounceOut(x)
	local n1 = 7.5625
	local d1 = 2.75

	if x < (1.0 / d1) then
		return n1 * x * x
	elseif x < (2.0 / d1) then
		x = x - 1.5 / d1
		return n1 * x * x + 0.75
	elseif x < (2.5 / d1) then
		x = x - 2.25 / d1
		return n1 * x * x + 0.9375
	else
		x = x - 2.625 / d1
		return n1 * x * x + 0.984375
	end
end

return {
	[Enum.PoseEasingStyle.Linear.Value] = {
		[Enum.PoseEasingDirection.In.Value] = function(x) return x end,
		[Enum.PoseEasingDirection.Out.Value] = function(x) return x end,
		[Enum.PoseEasingDirection.InOut.Value] = function(x) return x end,
	},
	
	[Enum.PoseEasingStyle.Constant.Value] = {
		[Enum.PoseEasingDirection.In.Value] = function(x) return x > 0.99 and 1.0 or 0.0 end,
		[Enum.PoseEasingDirection.Out.Value] = function(x) return x > 0.99 and 1.0 or 0.0 end,
		[Enum.PoseEasingDirection.InOut.Value] = function(x) return x > 0.99 and 1.0 or 0.0 end,
	},
	
	[5] = { -- CubicV2
		[Enum.PoseEasingDirection.In.Value] = function(x) return x*x*x end,
		[Enum.PoseEasingDirection.Out.Value] = function(x) return 1 - math.pow(1 - x, 3) end,
		[Enum.PoseEasingDirection.InOut.Value] = function(x) return x < 0.5 and 4 * x * x * x or 1 - math.pow(-2 * x + 2, 3) / 2 end
	},

	[Enum.PoseEasingStyle.Cubic.Value] = {
		[Enum.PoseEasingDirection.Out.Value] = function(x) return x*x*x end,
		[Enum.PoseEasingDirection.In.Value] = function(x) return 1 - math.pow(1 - x, 3) end,
		[Enum.PoseEasingDirection.InOut.Value] = function(x) return x < 0.5 and 4 * x * x * x or 1 - math.pow(-2 * x + 2, 3) / 2 end
	},

	[Enum.PoseEasingStyle.Bounce.Value] = {
		[Enum.PoseEasingDirection.In.Value] = function(x) return 1 - bounceOut(1 - x) end,
		[Enum.PoseEasingDirection.Out.Value] = bounceOut,
		[Enum.PoseEasingDirection.InOut.Value] = function(x)
			return x < 0.5
				and (1 - bounceOut(1 - 2 * x)) / 2
				or (1 + bounceOut(2 * x - 1)) / 2
		end
	},
	
	[Enum.PoseEasingStyle.Elastic.Value] = {
		[Enum.PoseEasingDirection.In.Value] = function(x)
			return x == 0 and 0
				or x == 1 and 1
				or -math.pow(2, 10 * x - 10) * math.sin((x * 10 - 10.75) * c4)
		end,
		[Enum.PoseEasingDirection.Out.Value] = function(x)
			return x == 0 and 0
				or x == 1 and 1
				or math.pow(2, -10 * x) * math.sin((x * 10 - 0.75) * c4) + 1
		end,
		[Enum.PoseEasingDirection.InOut.Value] = function(x)
			return x == 0 and 0
				or x == 1 and 1
				or x < 0.5 and -(math.pow(2, 20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2
				or (math.pow(2, -20 * x + 10) * math.sin((20 * x - 11.125) * c5)) / 2 + 1
		end,
	}
}
