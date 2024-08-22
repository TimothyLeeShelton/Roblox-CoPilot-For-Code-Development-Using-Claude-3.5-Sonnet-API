-- Required services
local HttpService = game:GetService("HttpService")  -- For JSON encoding/decoding and HTTP requests
local ServerStorage = game:GetService("ServerStorage")  -- For accessing server-side storage
local ScriptEditorService = game:GetService("ScriptEditorService")  -- For updating script sources
local UserInputService = game:GetService("UserInputService")  -- For handling user input

-- Test statements for debugging purposes
--Fun statement to test a single script being changed at a time: Add a print statement to the onboardingtutorialcontrol script in serverscriptservice at the start of the "updateDataStore" function. 
--Fun statement to test multiple scripts being changed at a time: Add a print statement to the onboardingtutorialcontrol script in serverscriptservice at the start of the "updateDataStore" function. For a second change, adjust the MAX_PAIRS_PER_KEY value in TimePlayedDataStore to 19999.

-- Create DockWidgetPluginGui
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Initial docking state
	false,  -- Initially enabled
	false,  -- Override enabled
	400,  -- Default width
	300,  -- Default height
	300,  -- Minimum width
	200   -- Minimum height
)

-- Create the main plugin GUI
local pluginGui = plugin:CreateDockWidgetPluginGui("ClaudeCodeUpdaterGUI", widgetInfo)
pluginGui.Title = "Claude Code Updater"

-- Create main Frame (container for UI elements)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1, 0, 1, 0)  -- Fill the entire pluginGui
Frame.BackgroundColor3 = Color3.fromRGB(247, 250, 252)  -- Light background color
Frame.BorderSizePixel = 0
Frame.Parent = pluginGui

-- Add rounded corners to the Frame
local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = Frame

-- Create ScrollingFrame for user input
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(0.9, 0, 0.5, 0)  -- 90% width, 50% height
ScrollingFrame.Position = UDim2.new(0.05, 0, 0.1, 0)  -- Centered horizontally, 10% from top
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.ScrollingEnabled = true  
ScrollingFrame.Parent = Frame
ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right

-- Create TextBox for user input
local UserRequestInput = Instance.new("TextBox")
UserRequestInput.Size = UDim2.new(1, 0, 1, 0)  -- Fill the entire ScrollingFrame
UserRequestInput.Position = UDim2.new(0, 0, 0, 0)
UserRequestInput.Text = "Enter your code update request here..."
UserRequestInput.TextColor3 = Color3.fromRGB(66, 84, 102)  -- Dark text color
UserRequestInput.BackgroundColor3 = Color3.fromRGB(241, 244, 227)  -- Light background color
UserRequestInput.Font = Enum.Font.SourceSansSemibold
UserRequestInput.MultiLine = true
UserRequestInput.TextWrapped = true
UserRequestInput.TextSize = 14
UserRequestInput.ClearTextOnFocus = false
UserRequestInput.Parent = ScrollingFrame

-- Add rounded corners to the TextBox
local TextBoxCorner = Instance.new("UICorner")
TextBoxCorner.CornerRadius = UDim.new(0, 4)
TextBoxCorner.Parent = UserRequestInput

-- Add padding to the text inside the TextBox
local TextBoxPadding = Instance.new("UIPadding")
TextBoxPadding.PaddingLeft = UDim.new(0, 8)
TextBoxPadding.PaddingRight = UDim.new(0, 8)
TextBoxPadding.PaddingTop = UDim.new(0, 8)
TextBoxPadding.PaddingBottom = UDim.new(0, 8)
TextBoxPadding.Parent = UserRequestInput

-- Add text size constraints to ensure readability
local TextSizeConstraint = Instance.new("UITextSizeConstraint")
TextSizeConstraint.MaxTextSize = 14
TextSizeConstraint.MinTextSize = 10
TextSizeConstraint.Parent = UserRequestInput

-- Function to update ScrollingFrame size based on text content
local function updateScrollingFrame()
	local textBounds = UserRequestInput.TextBounds
	local frameHeight = ScrollingFrame.AbsoluteSize.Y

	UserRequestInput.Size = UDim2.new(1, -12, 0, math.max(textBounds.Y, frameHeight))
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(textBounds.Y, frameHeight))
end

-- Connect TextBox events to update ScrollingFrame
UserRequestInput:GetPropertyChangedSignal("Text"):Connect(updateScrollingFrame)
UserRequestInput:GetPropertyChangedSignal("TextBounds"):Connect(updateScrollingFrame)

-- Double-click to clear text functionality
local lastClickTime = 0
UserRequestInput.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local currentTime = tick()
		if currentTime - lastClickTime < 1 then  -- Double-click threshold (1 second)
			UserRequestInput.Text = ""
		end
		lastClickTime = currentTime
	end
end)

-- Create Send Button
local SendButton = Instance.new("TextButton")
SendButton.Size = UDim2.new(0.3, 0, 0.15, 0)  -- 30% width, 15% height
SendButton.Position = UDim2.new(0.35, 0, 0.7, 0)  -- Centered horizontally, 70% from top
SendButton.Text = "Update Code"
SendButton.Font = Enum.Font.SourceSansBold
SendButton.TextSize = 16
SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White text
SendButton.BackgroundColor3 = Color3.fromRGB(99, 91, 255)  -- Purple background
SendButton.Parent = Frame

-- Add rounded corners to the Button
local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 4)
ButtonCorner.Parent = SendButton

-- Create Response Text area
local ResponseText = Instance.new("TextLabel")
ResponseText.Size = UDim2.new(0.9, 0, 0.2, 0)  -- 90% width, 20% height
ResponseText.Position = UDim2.new(0.05, 0, 0.9, 0)  -- Centered horizontally, 90% from top
ResponseText.BackgroundTransparency = 1
ResponseText.Text = ""
ResponseText.TextColor3 = Color3.fromRGB(66, 84, 102)  -- Dark text color
ResponseText.Font = Enum.Font.SourceSansSemibold
ResponseText.TextSize = 14
ResponseText.TextWrapped = true
ResponseText.TextXAlignment = Enum.TextXAlignment.Center
ResponseText.Parent = Frame


-- Function to create the Claude API prompt
local function createClaudePrompt(codebase, userRequest)
	-- Construct a multi-line string containing instructions for Claude
	return [[
Please analyze the following codebase and make the requested changes. 
Respond with a JSON structure containing the original code snippet and the updated version for each change that was requested.

User Request: ]] .. userRequest .. [[  

Codebase:
]] .. codebase .. [[ 

Please provide your response in the following JSON format:
{
    "changes": [
        {
            "previousCode": "Exact snippet of code to be replaced",
            "newCode": "Updated version of the code snippet",
            "explanation": "Brief explanation of the changes made"
        }
    ]
}

Only include the JSON in your response, without any additional text or formatting.
]]
	-- The function returns this constructed string
end

-- Function to serialize scripts from a specific service
local function serializeScriptsFromService(service)
	local scriptsData = {}  -- Initialize an empty table to store script data
	-- Iterate through all descendants of the service
	for _, script in ipairs(service:GetDescendants()) do
		-- Check if the descendant is a Script, LocalScript, or ModuleScript
		if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
			-- Add the script's data to the scriptsData table
			table.insert(scriptsData, {
				Name = script.Name,  -- Store the script's name
				ClassName = script.ClassName,  -- Store the script's class name
				ParentName = script.Parent and script.Parent.Name or "None",  -- Store the parent's name, or "None" if no parent
				Source = script.Source  -- Store the script's source code
			})
		end
	end
	-- Print a log message with the number of scripts serialized
	print("Serialized " .. #scriptsData .. " scripts from " .. service.Name)
	return scriptsData  -- Return the table containing all script data
end

-- Function to send request to Claude API
local function sendToClaudeAPI(scriptData, userRequest)
	print("Entering sendToClaudeAPI function")  -- Log function entry
	-- API key for authentication with Claude API
	local apiKey = "" --Replace with your API key.
	local url = "https://api.anthropic.com/v1/messages"  -- Claude API endpoint URL

	-- Create the prompt for Claude using the createClaudePrompt function
	local prompt = createClaudePrompt(HttpService:JSONEncode(scriptData), userRequest)

	-- Construct the request body
	local requestBody = {
		model = "claude-3-5-sonnet-20240620",  -- Specify the Claude model to use
		messages = {
			{
				role = "user",
				content = prompt  -- The prompt created earlier
			}
		},
		max_tokens = 4096  -- Maximum number of tokens in the response
	}

	print("Sending request to Claude API...")  -- Log sending request
	print("Request body: " .. HttpService:JSONEncode(requestBody))  -- Log the request body

	-- Use pcall to safely execute the HTTP request
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["x-api-key"] = apiKey,
				["anthropic-version"] = "2023-06-01"
			},
			Body = HttpService:JSONEncode(requestBody)
		})
	end)

	-- Handle the response
	if success then
		if response.Success then
			-- If the request was successful, decode the response and return the content
			local responseData = HttpService:JSONDecode(response.Body)
			print("Received successful response from Claude API: ", responseData)
			return responseData.content[1].text
		else
			-- If the request failed, log the error and return an error message
			print("API request failed. Status: " .. response.StatusCode .. ", Body: " .. response.Body)
			return "Error: API request failed with status " .. response.StatusCode
		end
	else
		-- If an error occurred during the request, log and return the error
		print("Error occurred while calling Claude API: " .. tostring(response))
		return "Error: " .. tostring(response)
	end
end

-- Function to apply code changes suggested by Claude
local function applyCodeChanges(claudeResponse)
	print("Applying code changes function started")  -- Log function start
	-- Decode the JSON response from Claude
	local changes = HttpService:JSONDecode(claudeResponse).changes
	print("Content of changes to apply in applycodechanges function are: ", changes)

	-- Iterate through each change suggested by Claude
	for _, change in ipairs(changes) do
		local previousCode = change.previousCode
		local newCode = change.newCode
		print("Previous code is: ", previousCode)  -- Log the code to be replaced
		print("New Code is: ", newCode)  -- Log the new code

		-- Search for the script containing the previous code
		for _, service in ipairs({game.ServerScriptService, game.ReplicatedStorage, game.StarterGui}) do
			for _, script in ipairs(service:GetDescendants()) do
				if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
					local source = script.Source
					-- Find the exact location of the code to be replaced
					local startIndex, endIndex = string.find(source, previousCode, 1, true)

					if startIndex then
						print("We found a matching piece of code compared to our previous code. So we know where to change. In Script: ", script.Name)
						-- Comment out the previous code
						local commentedCode = string.gsub(previousCode, "([^\r\n]+)", "--[[ %1 ]]")
						-- Construct the updated source code
						local updatedSource = string.sub(source, 1, startIndex - 1) .. commentedCode .. "\n" .. newCode .. "\n" .. string.sub(source, endIndex + 1)

						-- Update the script's source
						script.Source = updatedSource

						-- Use ScriptEditorService to update the script asynchronously
						ScriptEditorService:UpdateSourceAsync(script, function(previousCode)
							return updatedSource
						end)

						-- Open the updated script in the script editor
						plugin:OpenScript(script, startIndex)

						print("Updated script: " .. script.Name .. " in Service: " .. service.Name .. " \n \n \n \n With updated source of:" .. updatedSource)
						break  -- Exit the loop after updating the script
					end 
				end
			end
		end
	end
end

-- Function to serialize all scripts in specified services
local function serializeAllScripts()
	local allScriptsData = {}  -- Initialize an empty table to store all script data
	-- List of services to check for scripts
	local servicesToCheck = {game.ServerScriptService, game.ReplicatedStorage, game.StarterGui} -- Add more services as needed
	-- Iterate through each service
	for _, serviceBeingChecked in pairs(servicesToCheck) do
		-- Serialize scripts from the current service
		local serviceScripts = serializeScriptsFromService(serviceBeingChecked)
		-- Add the serialized scripts to the allScriptsData table
		for _, scriptData in ipairs(serviceScripts) do
			table.insert(allScriptsData, scriptData)
		end
	end
	-- Log the total number of scripts serialized
	print("Serialized " .. #allScriptsData .. " scripts from " .. #servicesToCheck .. " services")
	return allScriptsData  -- Return the table containing all serialized scripts
end

-- Function to handle sending request to Claude and applying changes
local function updateCode()
	-- Get the user's request from the input field
	local userRequest = UserRequestInput.Text
	-- Serialize all scripts in the game
	local serializedScripts = serializeAllScripts()
	-- Send the serialized scripts and user request to Claude API
	local claudeResponse = sendToClaudeAPI(serializedScripts, userRequest)

	-- Check if the response from Claude is an error
	if claudeResponse:sub(1, 5) == "Error" then
		-- If it's an error, update the response text with the error message
		ResponseText.Text = claudeResponse
		ResponseText.TextColor3 = Color3.fromRGB(234, 76, 137) -- Stripe-like error color
	else
		-- If it's not an error, apply the changes suggested by Claude
		print("Going to apply changes: ", claudeResponse)
		applyCodeChanges(claudeResponse)

		-- Update the response area to show success
		ResponseText.Text = "Success"
		ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126) -- Stripe-like success color
	end
	print("Completed updatecode function")  -- Log completion of the function
end

-- Connect the updateCode function to the button
SendButton.MouseButton1Click:Connect(updateCode)

-- Create a toolbar button to toggle the widget
local toolbar = plugin:CreateToolbar("Code Updater")
local toggleButton = toolbar:CreateButton("ToggleUpdater", "Toggle Code Updater", "")

-- Toggle button handler
toggleButton.Click:Connect(function()
	-- Toggle the visibility of the plugin GUI when the button is clicked
	pluginGui.Enabled = not pluginGui.Enabled
end)
