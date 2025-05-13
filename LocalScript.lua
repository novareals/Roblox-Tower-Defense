local TweenService = game:GetService("TweenService")
local button = script.Parent
local frame = button.Parent:FindFirstChild("UpdateFrame") -- Adjust the path if necessary

local tweenInfo = TweenInfo.new(
	0.5, -- Time
	Enum.EasingStyle.Quad, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	0, -- RepeatCount (0 = no repeat)
	false, -- Reverses (tween will not reverse)
	0 -- DelayTime
)

button.MouseButton1Click:Connect(function()
	if frame.Visible then
		local tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 1})
		tween:Play()
		tween.Completed:Connect(function()
			frame.Visible = false
			frame.BackgroundTransparency = 0.55
		end)
	else
		frame.Visible = true
		local tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0.55})
		tween:Play()
	end
end)
